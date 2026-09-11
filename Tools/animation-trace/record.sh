#!/bin/bash
#
# Records a simulator while one instrumented interaction runs, then collects the
# video and the trace log the app wrote into its tmp directory.
#
# Usage:
#   record.sh <device-udid> <output-dir>
#
# Configure via environment:
#   BUNDLE_ID     app bundle identifier                       (required)
#   XCPROJECT     path to .xcodeproj or .xcworkspace           (required)
#   SCHEME        scheme to test                               (required)
#   ONLY_TESTING  -only-testing: argument selecting the single
#                 UI test that performs the interaction        (required)
#   DERIVED_DATA  derived data path used by build-for-testing  (required)
#   LOG_NAME      file the app writes into NSTemporaryDirectory
#                 (default: animation-trace.log)
#   WARMUP        seconds to let the recorder start (default: 3)
#
# Build first with `xcodebuild build-for-testing` into DERIVED_DATA. This script
# only runs `test-without-building`, so a compile never lands in the recording.
#
set -euo pipefail

UDID="${1:?usage: record.sh <device-udid> <output-dir>}"
OUT="${2:?usage: record.sh <device-udid> <output-dir>}"

: "${BUNDLE_ID:?set BUNDLE_ID}"
: "${XCPROJECT:?set XCPROJECT}"
: "${SCHEME:?set SCHEME}"
: "${ONLY_TESTING:?set ONLY_TESTING}"
: "${DERIVED_DATA:?set DERIVED_DATA}"
LOG_NAME="${LOG_NAME:-animation-trace.log}"
WARMUP="${WARMUP:-3}"

case "$XCPROJECT" in
    *.xcworkspace) PROJECT_FLAG=(-workspace "$XCPROJECT") ;;
    *)             PROJECT_FLAG=(-project   "$XCPROJECT") ;;
esac

mkdir -p "$OUT"
rm -f "$OUT/capture.mov" "$OUT/animation-trace.log"
rm -rf "$OUT/frames"

echo "==> recording"
xcrun simctl io "$UDID" recordVideo --codec h264 --force "$OUT/capture.mov" &
RECORD_PID=$!

# Let the recorder actually start before anything happens on screen. The
# clapperboard is what aligns the timelines, so this only has to be long enough
# that no event is missed -- it does not have to be accurate.
sleep "$WARMUP"

echo "==> running the interaction"
set +e
xcodebuild test-without-building \
    "${PROJECT_FLAG[@]}" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$UDID" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:"$ONLY_TESTING" \
    > "$OUT/test.log" 2>&1
TEST_STATUS=$?
set -e

# Let the last animation finish inside the recording rather than at its edge.
sleep 2

echo "==> stopping recording"
kill -INT "$RECORD_PID" 2>/dev/null || true
wait "$RECORD_PID" 2>/dev/null || true

echo "==> collecting the trace log"
CONTAINER="$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)"
if [ -f "$CONTAINER/tmp/$LOG_NAME" ]; then
    cp "$CONTAINER/tmp/$LOG_NAME" "$OUT/animation-trace.log"
    echo "==> log:   $OUT/animation-trace.log ($(wc -l < "$OUT/animation-trace.log") lines)"
else
    echo "!! no $LOG_NAME in the app container -- is the harness hooked up?" >&2
fi

grep -E "Test Case.*(passed|failed)" "$OUT/test.log" || true
echo "==> video: $OUT/capture.mov"
exit $TEST_STATUS
