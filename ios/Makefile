.PHONY: help gen test build lint run clean

# Machine-local TEAM and DEVICE, gitignored; see Makefile.local.example.
-include Makefile.local
TEAM   ?=
DEVICE ?=

PROJECT := CrewAir.xcodeproj
SCHEME  := CrewAir
SIM     ?= iPhone 17 Pro

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

gen: ## Regenerate the Xcode project from project.yml
	@xcodegen generate

test: ## Domain tests in CrewKit (no simulator, ~1s)
	@cd CrewKit && swift test 2>&1 | tail -3

build: gen ## Build for the simulator (compile check)
	@set -o pipefail; xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
		-derivedDataPath build-sim CODE_SIGNING_ALLOWED=NO build 2>&1 | \
		grep -E "(error:|warning:|BUILD)" | head -30

run: gen ## Build, install and launch on a simulator (SIM="iPhone 17 Pro")
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination 'platform=iOS Simulator,name=$(SIM)' \
		-derivedDataPath build-sim CODE_SIGNING_ALLOWED=NO build 2>&1 | grep -E "(error:|BUILD)"
	@xcrun simctl boot "$(SIM)" 2>/dev/null || true
	@xcrun simctl install "$(SIM)" build-sim/Build/Products/Debug-iphonesimulator/CrewAir.app
	@xcrun simctl launch "$(SIM)" co.superduperai.crewair

build-device: gen ## Build for a physical iPhone (TEAM in Makefile.local)
	@set -o pipefail; xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-sdk iphoneos -destination 'generic/platform=iOS' \
		-derivedDataPath build -allowProvisioningUpdates \
		DEVELOPMENT_TEAM=$(TEAM) build 2>&1 | grep -E "(error:|BUILD)" | head -30

install: build-device ## Build and install onto the paired iPhone (DEVICE in Makefile.local)
	@test -n "$(DEVICE)" || { echo "Set DEVICE in Makefile.local: xcrun devicectl list devices"; exit 1; }
	@xcrun devicectl device install app --device $(DEVICE) \
		build/Build/Products/Debug-iphoneos/CrewAir.app 2>&1 | grep -E "(App installed|bundleID|ERROR)"

lint: ## SwiftLint, if installed
	@if command -v swiftlint >/dev/null; then swiftlint lint --quiet; \
		else echo "swiftlint not installed, skipped"; fi

clean: ## Remove build output and the generated project
	@rm -rf build build-sim $(PROJECT) CrewKit/.build
