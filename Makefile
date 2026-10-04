SHELL := /bin/bash
DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
export DEVELOPER_DIR

PROJECT := HealthGoals.xcodeproj
SCHEME := HealthGoals
SWIFTFORMAT_VERSION := 0.59.1
SWIFTLINT_VERSION := 0.65.0
SWIFTFORMAT := $(CURDIR)/.build/tools/swiftformat-$(SWIFTFORMAT_VERSION)/swiftformat
SWIFTLINT := $(CURDIR)/.build/tools/swiftlint-$(SWIFTLINT_VERSION)/swiftlint
RESULT_DIR ?= $(CURDIR)/.build/verification
SIMULATOR_UDID ?=

.NOTPARALLEL:

.PHONY: setup tools-check format format-check lint repository-checks xcode-version test analyze build-release verify

setup:
	./scripts/setup-quality-tools.sh

tools-check:
	@test -x '$(SWIFTFORMAT)' && test "$$('$(SWIFTFORMAT)' --version)" = '$(SWIFTFORMAT_VERSION)' || { echo 'Run make setup for SwiftFormat $(SWIFTFORMAT_VERSION).' >&2; exit 1; }
	@test -x '$(SWIFTLINT)' && test "$$('$(SWIFTLINT)' --version)" = '$(SWIFTLINT_VERSION)' || { echo 'Run make setup for SwiftLint $(SWIFTLINT_VERSION).' >&2; exit 1; }

# This is the only quality target that writes Swift sources.
format: tools-check
	'$(SWIFTFORMAT)' . --config .swiftformat --cache ignore

format-check: tools-check
	'$(SWIFTFORMAT)' . --config .swiftformat --cache ignore --lint

lint: tools-check
	'$(SWIFTLINT)' lint --config .swiftlint.yml --strict --no-cache

repository-checks:
	python3 scripts/check-agent-kit.py
	python3 -m unittest discover -s tests -v
	git diff --check HEAD

xcode-version:
	@test "$$(xcodebuild -version)" = $$'Xcode 26.6\nBuild version 17F113' || { echo 'Select Xcode 26.6 (17F113) with DEVELOPER_DIR.' >&2; exit 1; }

test: xcode-version
	@test -n '$(SIMULATOR_UDID)' || { echo 'Provide a booted SIMULATOR_UDID, or run make verify.' >&2; exit 1; }
	mkdir -p '$(RESULT_DIR)'
	xcodebuild test -project '$(PROJECT)' -scheme '$(SCHEME)' -configuration Debug \
		-destination 'platform=iOS Simulator,id=$(SIMULATOR_UDID)' \
		-only-testing:HealthGoalsTests -only-testing:HealthGoalsUITests/BootstrapTests/testLaunch \
		-parallel-testing-enabled NO -derivedDataPath '$(RESULT_DIR)/Tests' \
		-resultBundlePath '$(RESULT_DIR)/Tests.xcresult' CODE_SIGNING_ALLOWED=NO

analyze: xcode-version
	xcodebuild analyze -project '$(PROJECT)' -scheme '$(SCHEME)' -configuration Debug \
		-destination 'generic/platform=iOS Simulator' -derivedDataPath '$(RESULT_DIR)/Tests' \
		CODE_SIGNING_ALLOWED=NO

build-release: xcode-version
	xcodebuild build -project '$(PROJECT)' -scheme '$(SCHEME)' -configuration Release \
		-destination 'generic/platform=iOS' -derivedDataPath '$(RESULT_DIR)/Release' \
		CODE_SIGNING_ALLOWED=NO

verify: format-check lint repository-checks
	./scripts/verify-ios.sh
