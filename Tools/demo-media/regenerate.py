#!/usr/bin/env python3
"""
Regenerate every still and animated GIF in `docs/media`, in place.

    Tools/demo-media/regenerate.py [options]

The files keep their names -- `<SegueIdentifier>.png` and `<SegueIdentifier>.gif`
-- so `docs/demos.md` and the README pick up new media without being edited.

What it does, per demo: launches straight onto the screen for a still, then
records the simulator while that screen's existing UI test performs a real drag,
trims the recording to the span where the app is actually on screen, and
converts that to a GIF. Every clip is then checked for motion and for
springboard leakage before anything is committed.

Options:
    --device UDID          simulator to drive (default: the booted one)
    --only SEGUE           regenerate just these demos; repeatable
    --skip-build           reuse an existing build in --derived-data
    --reuse-recordings     re-cut GIFs from the last run's videos, no tests
    --derived-data PATH    build location (default: a temp dir alongside)
    --no-commit            leave the new media uncommitted

Requires a booted simulator, Xcode command line tools, ffmpeg/ffprobe, Pillow.

---------------------------------------------------------------------------
Why the trimming is the way it is
---------------------------------------------------------------------------

Each recording starts on the iOS home screen, because `record.sh` starts
capturing before the test launches the app, and ends back there when the test
tears it down. Cutting that off took two different signals, and neither works
alone:

* The app *arriving* is invisible to ffmpeg's scene detection -- the launch
  transition scores about the same as a drag (~0.18), so no threshold separates
  them. Saturation does separate them: the demo screens are near-white, the
  wallpaper is a saturated gradient.

* The app *leaving* is invisible to saturation -- Widget Composer's purple phone
  frame reads exactly like wallpaper. But vanishing is a huge scene change
  (~0.68) where arriving was not, so the score finds it.

So: saturation for the head, scene score for the tail.

Two further traps, both of which produced confident, wrong output:

* Cropping to the "busy" part of the clip by scene score once cut a GIF to the
  still screen sitting *beside* its own drag -- a perfectly static demo,
  correctly trimmed to the wrong seconds. The whole app-on-screen span is used
  instead. A beat of stillness at the head is a fair price and shows the resting
  layout before anything moves.

* `-ss` before `-i` seeks to the nearest keyframe. These recordings are variable
  frame rate, so that misses by seconds. `-ss` after `-i` is exact, but only as
  an output option over a single input -- with the palette as a second input it
  applies to the palette and ffmpeg exits 254. Hence trimming to a temporary
  clip as its own pass, before palettegen ever runs.
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile
import time

from PIL import Image, ImageChops


def saturation(image):
    """Mean per-pixel (max channel - min channel) over an RGB image."""
    raw = image.tobytes()
    total = sum(max(raw[i:i + 3]) - min(raw[i:i + 3]) for i in range(0, len(raw), 3))
    return total / (len(raw) / 3)

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MEDIA = os.path.join(ROOT, "docs", "media")
RECORD = os.path.join(ROOT, "Tools", "animation-trace", "record.sh")

BUNDLE_ID = "com.onitaps.Drag-Drop"
XCPROJECT = "Demo/DragDropDemo.xcodeproj"
SCHEME = "DragDropDemo"

STILL_WIDTH = 400
GIF_WIDTH = 300
GIF_FPS = 12
GIF_MAX_SECONDS = 9.0
SETTLE_SECONDS = 2.5

# Each demo, and the existing UI test that drives a representative drag on it.
# A new demo needs a line here and a test that actually drags something.
DEMOS = {
    "FourByFourViewController":
        "DragDropDemoUITests/FreeFormDemoTests/testMovingSomeoneBetweenShiftsUpdatesBothPanels",
    "EmbeddedViewController":
        "DragDropDemoUITests/FreeFormDemoTests/testAPhotoMovesIntoTheNestedAlbum",
    "DoubleEmbeddedViewController":
        "DragDropDemoUITests/FreeFormDemoTests/testAWidgetDropsIntoTheStackInsideTheDecorativeFrame",
    "EmbeddedDropTargetViewController":
        "DragDropDemoUITests/FreeFormDemoTests/testDroppingAFileOnTheFolderFilesIt",
    "NormalTableViewController":
        "DragDropDemoUITests/ListDemoTests/testDraggingATrackOutOfTheQueueMovesItToSaved",
    "NormalCollectionViewController":
        "DragDropDemoUITests/ListDemoTests/testReorderingAMoodboardCardLeavesNoHoleAndNoOverlap",
    "DoubleCollectionViewController":
        "DragDropDemoUITests/ListDemoTests/testAPlayerMovesFromTheBenchToTheStarters",
}


# --------------------------------------------------------------------------
# simulator

def booted_device():
    out = subprocess.run(["xcrun", "simctl", "list", "devices", "booted"],
                         capture_output=True, text=True).stdout
    found = re.search(r"\(([0-9A-F-]{36})\) \(Booted\)", out)
    if not found:
        sys.exit("no booted simulator -- boot one, or pass --device")
    return found.group(1)


def still(device, segue):
    """Launch straight onto the screen, let it settle, screenshot, downscale."""
    subprocess.run(["xcrun", "simctl", "terminate", device, BUNDLE_ID],
                   capture_output=True)
    subprocess.run(["xcrun", "simctl", "launch", device, BUNDLE_ID, "-demo", segue],
                   capture_output=True, check=True)
    time.sleep(SETTLE_SECONDS)

    path = os.path.join(MEDIA, f"{segue}.png")
    subprocess.run(["xcrun", "simctl", "io", device, "screenshot", path],
                   capture_output=True, check=True)
    subprocess.run(["xcrun", "simctl", "terminate", device, BUNDLE_ID],
                   capture_output=True)

    image = Image.open(path).convert("RGB")
    scaled = image.resize(
        (STILL_WIDTH, round(image.height * STILL_WIDTH / image.width)),
        Image.Resampling.LANCZOS)
    scaled.save(path, "PNG", optimize=True)
    return os.path.getsize(path)


def record(device, segue, test, derived_data, work, reuse):
    out_dir = os.path.join(work, segue)
    video = os.path.join(out_dir, "capture.mov")
    if reuse and os.path.exists(video):
        return video

    env = dict(os.environ, BUNDLE_ID=BUNDLE_ID, XCPROJECT=XCPROJECT, SCHEME=SCHEME,
               ONLY_TESTING=test, DERIVED_DATA=derived_data, WARMUP="2")
    subprocess.run(["bash", RECORD, device, out_dir],
                   cwd=ROOT, env=env, capture_output=True, text=True)
    return video if os.path.exists(video) else None


# --------------------------------------------------------------------------
# trimming

def duration(video):
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=nw=1:nk=1", video],
        capture_output=True, text=True).stdout.strip()
    return float(out) if out else 0.0


def app_on_screen(video):
    """
    (first, last) seconds the app is up, found by saturation.

    Scene detection cannot answer this: the launch transition scores about the
    same as a drag. The demo screens are near-white and the springboard
    wallpaper is not, which separates them cleanly.
    """
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["ffmpeg", "-v", "error", "-i", video,
                        "-vf", "fps=5,scale=48:-1", "-y",
                        os.path.join(tmp, "s_%05d.png")], check=True)
        names = sorted(n for n in os.listdir(tmp) if n.endswith(".png"))
        sats = [saturation(Image.open(os.path.join(tmp, name)).convert("RGB"))
                for name in names]

    if not sats:
        return None
    low, high = min(sats), max(sats)
    if high - low < 12:
        return None

    # Split at the midpoint of the observed range, not a fixed number, so a
    # restyle of the demo palette does not silently break this.
    cut = low + (high - low) * 0.45

    runs, start = [], None
    for index, value in enumerate(sats):
        if value <= cut and start is None:
            start = index
        elif value > cut and start is not None:
            runs.append((start, index - 1))
            start = None
    if start is not None:
        runs.append((start, len(sats) - 1))
    if not runs:
        return None

    first, last = max(runs, key=lambda r: r[1] - r[0])
    return first / 5.0, last / 5.0


def window(video):
    """The span to keep: app on screen, springboard trimmed off both ends."""
    total = duration(video)
    out = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", video,
         "-vf", "select='gt(scene,0.004)',metadata=print:file=-",
         "-an", "-f", "null", "-"],
        capture_output=True, text=True).stdout
    events = [(float(t), float(s)) for t, s in re.findall(
        r"pts_time:([0-9.]+)\s*\nlavfi\.scene_score=([0-9.]+)", out)]

    appearing = app_on_screen(video)
    floor = (appearing[0] + 0.3) if appearing else 0.0

    # `record.sh` sleeps 2s after the test, so that is the fallback tail.
    limit = max(total - 2.0, floor)
    for when, score in events:
        if score > 0.45 and when > floor + 1.0:
            limit = max(when - 0.4, floor)
            break

    if limit - floor < 1.0:
        return None
    return floor, min(limit - floor, GIF_MAX_SECONDS)


def to_gif(video, start, length, gif, work):
    chain = f"fps={GIF_FPS},scale={GIF_WIDTH}:-1:flags=lanczos"
    clip = os.path.join(work, "clip.mp4")
    palette = os.path.join(work, "palette.png")

    # Trim as its own pass over a single input -- see the module docstring.
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", video,
                    "-ss", f"{start:.2f}", "-t", f"{length:.2f}",
                    "-an", "-c:v", "libx264", "-pix_fmt", "yuv420p", clip], check=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", clip,
                    "-vf", chain + ",palettegen=max_colors=128", palette], check=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", clip, "-i", palette,
                    "-lavfi", chain + "[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3",
                    "-loop", "0", gif], check=True)
    os.remove(palette)
    os.remove(clip)


# --------------------------------------------------------------------------
# verification

def check(gif):
    """
    (ok, moved, max_saturation). A GIF must actually move, and must not have
    caught the springboard -- both failures have shipped from this script's
    ancestors and neither is visible in a file listing.

    The test that matters is that the clip *ends somewhere else*: every one of
    these demos permanently changes its screen -- a card moves, two counts
    change -- so a clip whose last frame matches its first did not catch the
    drop. That is exactly how the one bad clip failed, and counting motion
    missed it: it had 46 frames and 7 changed transitions, which looks healthy.

    Counting was tried twice and is not stable enough to gate on. Absolute
    counts assume every frame survived, and the encoder drops duplicates, so a
    clip with a still beat decodes to far fewer frames than fps x duration --
    Lineup came back as 14 frames for 6.8s. A proportion then fails the clips
    that are mostly still and correct. `moved` is kept as a floor against a
    single jump cut, and reported for eyeballing, but the verdict is the
    endpoints.
    """
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", gif, "-vsync", "0",
                        os.path.join(tmp, "f_%04d.png")], check=True)
        frames = [Image.open(os.path.join(tmp, n)).convert("RGB").resize((60, 130))
                  for n in sorted(os.listdir(tmp))]

    moved = 0
    for a, b in zip(frames, frames[1:]):
        raw = ImageChops.difference(a, b).tobytes()
        if sum(raw) / (len(raw) / 3) > 2.0:
            moved += 1

    # Springboard detection looks only at the top of the frame. Whole-frame
    # saturation was calibrated when Moodboard had whitespace between its
    # cards; packing it as real masonry filled that in and the screen started
    # reading as wallpaper. The bar at the top is near-white on every demo and
    # is wallpaper on the springboard, whatever the content below it.
    worst = max((saturation(frame.crop((0, 0, frame.width, frame.height // 7)))
                 for frame in frames), default=0.0)

    settled = 0.0
    if len(frames) >= 2:
        raw = ImageChops.difference(frames[0], frames[-1]).tobytes()
        settled = sum(raw) / (len(raw) / 3)

    ok = settled > 2.0 and moved >= 3 and worst < 45
    return ok, moved, worst


# --------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--device")
    parser.add_argument("--only", action="append", choices=sorted(DEMOS))
    parser.add_argument("--skip-build", action="store_true")
    parser.add_argument("--reuse-recordings", action="store_true")
    parser.add_argument("--derived-data")
    parser.add_argument("--no-commit", action="store_true")
    args = parser.parse_args()

    device = args.device or booted_device()
    demos = {k: v for k, v in DEMOS.items() if not args.only or k in args.only}
    work = args.derived_data or os.path.join(tempfile.gettempdir(), "demo-media")
    derived = os.path.join(work, "DerivedData")
    os.makedirs(MEDIA, exist_ok=True)
    os.makedirs(work, exist_ok=True)

    # `--skip-build` against a derived-data path with no build in it produces
    # seven recordings of the iOS home screen and nothing else: the tests fail
    # instantly, so the app never launches. Caught downstream by the checks
    # below, but the message there blames the trimming rather than the cause.
    if args.skip_build and not args.reuse_recordings:
        runner = os.path.join(derived, "Build", "Products",
                              "Debug-iphonesimulator", "DragDropDemoUITests-Runner.app")
        if not os.path.exists(runner):
            sys.exit(f"--skip-build, but there is no test build at {derived}.\n"
                     f"Drop the flag, or point --derived-data at a directory whose\n"
                     f"DerivedData subdirectory holds a `build-for-testing` result.")

    if not args.skip_build and not args.reuse_recordings:
        print("==> building for testing")
        build = subprocess.run(
            ["xcodebuild", "build-for-testing", "-project", XCPROJECT,
             "-scheme", SCHEME, "-destination", f"platform=iOS Simulator,id={device}",
             "-derivedDataPath", derived],
            cwd=ROOT, capture_output=True, text=True)
        if build.returncode:
            sys.exit(build.stdout[-3000:] or "build failed")

    print(f"{'demo':<38} {'still':>7} {'gif':>7} {'window':>16} {'moved':>6}  state")
    failures = []
    for segue, test in demos.items():
        png = still(device, segue)

        video = record(device, segue, test, derived, work, args.reuse_recordings)
        if video is None:
            failures.append(f"{segue}: no recording (its UI test may have failed)")
            print(f"{segue:<38} {png/1024:>6.0f}K {'-':>7} {'-':>16} {'-':>6}  NO VIDEO")
            continue

        span = window(video)
        if span is None:
            failures.append(f"{segue}: could not find the app on screen in the recording")
            print(f"{segue:<38} {png/1024:>6.0f}K {'-':>7} {'-':>16} {'-':>6}  NO WINDOW")
            continue

        gif = os.path.join(MEDIA, f"{segue}.gif")
        to_gif(video, span[0], span[1], gif, work)
        ok, moved, worst = check(gif)
        if not ok:
            failures.append(f"{segue}: clip is static or caught the springboard "
                            f"(moved={moved}, saturation={worst:.0f})")

        print(f"{segue:<38} {png/1024:>6.0f}K "
              f"{os.path.getsize(gif)/1024:>6.0f}K "
              f"{span[0]:>6.1f}s +{span[1]:>5.1f}s {moved:>6}  "
              f"{'ok' if ok else 'CHECK'}")

    if failures:
        print("\n" + "\n".join(f"  !! {f}" for f in failures), file=sys.stderr)
        sys.exit("refusing to commit -- fix the above and re-run")

    if args.no_commit:
        print("\nmedia regenerated; not committed (--no-commit)")
        return

    changed = subprocess.run(["git", "status", "--porcelain", "docs/media"],
                             cwd=ROOT, capture_output=True, text=True).stdout.strip()
    if not changed:
        print("\nmedia regenerated; identical to what is committed")
        return

    subprocess.run(["git", "add", "docs/media"], cwd=ROOT, check=True)
    subprocess.run(["git", "commit", "-m", "Regenerate the demo stills and GIFs",
                    "-m", "Produced by Tools/demo-media/regenerate.py against the "
                          "current demos. Filenames are unchanged, so docs/demos.md "
                          "and the README pick these up as they are."],
                   cwd=ROOT, check=True)
    print("\ncommitted:")
    print(changed)


if __name__ == "__main__":
    main()
