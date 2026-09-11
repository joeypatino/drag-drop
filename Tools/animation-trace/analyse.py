#!/usr/bin/env python3
"""
Turns a recording plus a trace log into a per-frame table of what was actually
on screen, indexed by the event it belongs to.

The recording from `simctl io recordVideo` is variable frame rate -- it records
densely while the screen changes and barely at all while it is still -- so
frames are addressed by their real presentation timestamp, never by an assumed
fps. The clapperboard strip in the top-left corner carries the event counter in
binary, which is what ties a log line to a frame.

Usage: analyse.py <capture-dir> [--event N] [--window SECONDS]
"""

import argparse
import json
import os
import re
import subprocess
import sys

from PIL import Image

MARKER_BITS = 6
MARKER_BLOCK_PT = 24


def frame_timestamps(video):
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0",
         "-show_entries", "frame=pts_time", "-of", "csv=p=0", video],
        capture_output=True, text=True, check=True).stdout
    times = []
    for line in out.splitlines():
        value = line.strip().rstrip(",")
        if value:
            times.append(float(value))
    return times


def extract_frames(video, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    if not os.listdir(out_dir):
        subprocess.run(
            ["ffmpeg", "-v", "error", "-i", video, "-vsync", "0",
             os.path.join(out_dir, "f_%05d.png")], check=True)
    return sorted(os.path.join(out_dir, n) for n in os.listdir(out_dir)
                  if n.endswith(".png"))


def read_marker(image, scale):
    """Decode the binary strip. Returns None if the strip is not present."""
    block = MARKER_BLOCK_PT * scale
    value = 0
    for bit in range(MARKER_BITS):
        # Sample the middle of each block, away from any edge softening.
        x = int(bit * block + block * 0.5)
        y = int(block * 0.5)
        r, g, b = image.getpixel((x, y))[:3]
        if r > 200 and g > 200 and b > 200:
            value |= 1 << bit
        elif not (r < 80 and g < 80 and b < 80):
            return None          # neither white nor black: no marker here
    return value


FIDUCIALS = {"cell": (255, 0, 255), "inner": (255, 255, 0), "render": (255, 0, 0)}


def fiducial_box(image, colour, scale, tolerance=60):
    """
    Bounding box, in points, of the hairline the harness drew on a view.

    The colours are pure and appear nowhere else in the interface, so this is a
    lookup rather than a segmentation -- there is nothing for it to confuse.
    Returns None when the fiducial is not on screen at all, which is itself
    information: the view was hidden, clipped or off-screen that frame.
    """
    pixels = image.load()
    width, height = image.size
    step = max(1, scale // 2)
    top = bottom = left = right = None
    for y in range(0, height, step):
        for x in range(0, width, step):
            r, g, b = pixels[x, y][:3]
            if (abs(r - colour[0]) + abs(g - colour[1]) + abs(b - colour[2])) <= tolerance:
                if top is None:
                    top = y
                bottom = y
                left = x if left is None else min(left, x)
                right = x if right is None else max(right, x)
    if top is None:
        return None
    return {"top": top / scale, "bottom": bottom / scale,
            "left": left / scale, "right": right / scale,
            "height": (bottom - top) / scale, "width": (right - left) / scale}


def parse_log(path):
    events, samples = [], []
    for line in open(path):
        line = line.strip()
        if not line:
            continue
        fields = dict(re.findall(r"(\S+?)=(\S+)", line))
        if "event" in fields:
            events.append(fields)
        elif "frame" in fields:
            samples.append(fields)
    return events, samples


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("capture_dir")
    ap.add_argument("--event", type=int, default=None,
                    help="event index to centre on (default: the first with a bounds animation)")
    ap.add_argument("--window", type=float, default=0.6)
    args = ap.parse_args()

    video = os.path.join(args.capture_dir, "capture.mov")
    log = os.path.join(args.capture_dir, "animation-trace.log")
    events, samples = parse_log(log)

    times = frame_timestamps(video)
    frames = extract_frames(video, os.path.join(args.capture_dir, "frames"))
    if len(frames) != len(times):
        print(f"warning: {len(frames)} frames but {len(times)} timestamps", file=sys.stderr)
    count = min(len(frames), len(times))

    probe = Image.open(frames[0])
    scale = probe.width // 402            # logical points -> pixels
    print(f"video {probe.width}x{probe.height}, scale {scale}x, {count} frames, "
          f"{times[-1]:.2f}s, mean {count / times[-1]:.1f} fps overall")

    # Decode the clapperboard on every frame.
    markers = []
    for index in range(count):
        image = Image.open(frames[index]).convert("RGB")
        markers.append(read_marker(image, scale))

    # Which frame first shows each event.
    first_frame_of = {}
    for index, value in enumerate(markers):
        if value is not None and value not in first_frame_of:
            first_frame_of[value] = index

    print("\nevent -> first frame showing it")
    for fields in events:
        index = int(fields["event"])
        frame = first_frame_of.get(index)
        when = f"{times[frame]:.3f}s (frame {frame})" if frame is not None else "NOT FOUND"
        print(f"  event {index} {fields['name']:<24} {when}")

    target_event = args.event
    if target_event is None:
        for fields in events:
            if "bounds.size" in fields.get("cell.keys", ""):
                target_event = int(fields["event"])
                break
    if target_event is None or target_event not in first_frame_of:
        print("\nno event with a bounds animation found in the video", file=sys.stderr)
        return 1

    start = first_frame_of[target_event]
    t0 = times[start]

    print(f"\nmeasuring event {target_event} from {t0:.3f}s to {t0 + args.window:.3f}s, every frame")
    header = f"{'frame':>6} {'t(s)':>8} {'dt(ms)':>7} {'mk':>3}"
    for name in FIDUCIALS:
        header += f" | {name+' h':>8} {'top':>7}"
    print(header)

    table = []
    for index in range(start, count):
        if times[index] > t0 + args.window:
            break
        image = Image.open(frames[index]).convert("RGB")
        row = {"frame": index, "t": times[index]}
        line = f"{index:>6} {times[index]:>8.3f} {(times[index]-t0)*1000:>7.1f} {str(markers[index]):>3}"
        for name, colour in FIDUCIALS.items():
            box = fiducial_box(image, colour, scale)
            row[name] = box
            if box is None:
                line += f" | {'absent':>8} {'-':>7}"
            else:
                line += f" | {box['height']:>8.1f} {box['top']:>7.1f}"
        table.append(row)
        print(line)

    print()
    for name in FIDUCIALS:
        # Degenerate readings -- a fiducial clipped to a sliver or gone from
        # screen -- are not measurements, and counting them as changes would
        # report a snap as an animation.
        heights = [r[name]["height"] for r in table if r[name] and r[name]["height"] > 20]
        if len(heights) < 2:
            print(f"{name:>8}: fiducial never visible -- cannot measure")
            continue
        changes = sum(1 for a, b in zip(heights, heights[1:]) if abs(a - b) > 1.0)
        verdict = "ANIMATED" if changes >= 2 else "SNAPPED"
        print(f"{name:>8}: {min(heights):6.1f} -> {max(heights):6.1f} pt, "
              f"{changes} of {len(heights)-1} frame-to-frame changes  => {verdict}")

    with open(os.path.join(args.capture_dir, "measurements.json"), "w") as handle:
        json.dump({"event": target_event, "frames": table}, handle, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
