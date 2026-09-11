#!/bin/bash
#
# Records the simulator while one instrumented drag runs, then pulls back the
# video and the trace log.
#
# Usage: record.sh <device-udid> <output-dir>
#
set -euo pipefail

UDID="${1:?usage: record.sh <device-udid> <output-dir>}"
OUT="${2:?usage: record.sh <device-udid> <output-dir>}"
BUNDLE_ID="com.onitaps.Drag-Drop"
DERIVED="${DERIVED_DATA:-/Users/joey/.claude/jobs/baf95f66/tmp/trace-dd}"
PROJECT_DIR="$(cd "$(dirname "$0")/../../Demo" && pwd)"

mkdir -p "$OUT"
rm -f "$OUT/capture.mov" "$OUT/animation-trace.log"

echo "==> recording"
xcrun simctl io "$UDID" recordVideo --codec h264 --force "$OUT/capture.mov" &
RECORD_PID=$!

# Let the recorder actually start before anything happens on screen. The
# clapperboard is what aligns the timelines, so this only needs to be long
# enough that no event is missed, not accurate.
sleep 3

echo "==> running the drag"
set +e
xcodebuild test-without-building \
    -project "$PROJECT_DIR/DragDropDemo.xcodeproj" \
    -scheme DragDropDemo \
    -destination "platform=iOS Simulator,id=$UDID" \
    -derivedDataPath "$DERIVED" \
    -only-testing:DragDropDemoUITests/AnimationTraceDrag \
    > "$OUT/test.log" 2>&1
TEST_STATUS=$?
set -e

sleep 2

echo "==> stopping recording"
kill -INT "$RECORD_PID" 2>/dev/null || true
wait "$RECORD_PID" 2>/dev/null || true

echo "==> collecting the trace log"
CONTAINER="$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)"
cp "$CONTAINER/tmp/animation-trace.log" "$OUT/animation-trace.log"

grep -E "TRACE|Test Case.*(passed|failed)" "$OUT/test.log" || true
echo "==> video:  $OUT/capture.mov"
echo "==> log:    $OUT/animation-trace.log  ($(wc -l < "$OUT/animation-trace.log") lines)"
exit $TEST_STATUS
