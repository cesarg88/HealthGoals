#!/bin/bash
# Verificación específica de HealthGoals; no instala herramientas ni modifica fuentes.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${DEVELOPER_DIR:?Selecciona explícitamente Xcode 26.6 mediante DEVELOPER_DIR}"
expected_xcode=$'Xcode 26.6\nBuild version 17F113'
if [[ "$(xcodebuild -version)" != "$expected_xcode" ]]; then
    echo "Se requiere Xcode 26.6 (17F113)." >&2
    exit 1
fi
runtime=com.apple.CoreSimulator.SimRuntime.iOS-26-5
xcrun simctl list runtimes --json | python3 -c '
import json, sys
runtimes = json.load(sys.stdin)["runtimes"]
assert any(r["identifier"] == sys.argv[1] and r["isAvailable"] for r in runtimes), "Falta runtime iOS 26.5"
' "$runtime"
mkdir -p .build
results_dir=$(mktemp -d "$PWD/.build/ios.XXXXXX")
echo "Resultados: $results_dir"
simulator_id=''
cleanup() {
    if [[ -n "$simulator_id" ]]; then
        xcrun simctl shutdown "$simulator_id" >/dev/null 2>&1 || true
        xcrun simctl delete "$simulator_id" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT
xcodebuild -list -project HealthGoals.xcodeproj | tee "$results_dir/project.log"
for device in 'iPhone 17 Pro' 'iPad Pro 11-inch (M5)'; do
    device_type=$(xcrun simctl list devicetypes --json | python3 -c '
import json, sys
print(next(d["identifier"] for d in json.load(sys.stdin)["devicetypes"] if d["name"] == sys.argv[1]))
' "$device")
    simulator_id=$(xcrun simctl create "HealthGoals bootstrap $device" "$device_type" "$runtime")
    xcrun simctl bootstatus "$simulator_id" -b
    destination="platform=iOS Simulator,id=$simulator_id"
    xcodebuild -project HealthGoals.xcodeproj -scheme HealthGoals -configuration Debug \
        -destination "$destination" -derivedDataPath "$results_dir/DerivedData" \
        CODE_SIGNING_ALLOWED=NO build 2>&1 | tee "$results_dir/$device-build.log"
    xcodebuild -project HealthGoals.xcodeproj -scheme HealthGoals -configuration Debug \
        -destination "$destination" -derivedDataPath "$results_dir/DerivedData" \
        -parallel-testing-enabled NO -resultBundlePath "$results_dir/$device.xcresult" \
        CODE_SIGNING_ALLOWED=NO test 2>&1 | tee "$results_dir/$device-test.log"
    cleanup
    simulator_id=''
done
