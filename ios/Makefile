.PHONY: help gen test build lint run clean

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

lint: ## SwiftLint, if installed
	@if command -v swiftlint >/dev/null; then swiftlint lint --quiet; \
		else echo "swiftlint not installed, skipped"; fi

clean: ## Remove build output and the generated project
	@rm -rf build-sim $(PROJECT) CrewKit/.build
