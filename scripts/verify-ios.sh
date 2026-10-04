#!/bin/bash
# Run the delivery gate on one owned iPhone; leave source files untouched.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
results_dir=$(mktemp -d "$PWD/.build/verify.XXXXXX")
echo "Verification results: $results_dir"
simulator_id=''
cleanup() {
    if [[ -n "$simulator_id" ]]; then
        xcrun simctl shutdown "$simulator_id" >/dev/null 2>&1 || true
        xcrun simctl delete "$simulator_id" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT
make xcode-version
simulator_id=$(xcrun simctl create 'HealthGoals local verification' \
    com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro \
    com.apple.CoreSimulator.SimRuntime.iOS-26-5)
xcrun simctl bootstatus "$simulator_id" -b
make test analyze build-release SIMULATOR_UDID="$simulator_id" RESULT_DIR="$results_dir" \
    2>&1 | tee "$results_dir/verify.log"
