# WhisperX Makefile
# macOS menu bar app for push-to-talk transcription

SCHEME = whisperX
APP_NAME = WhisperX
BUILD_DIR = build
DERIVED_DATA = $(BUILD_DIR)
DEBUG_APP = $(BUILD_DIR)/Build/Products/Debug/$(APP_NAME).app
RELEASE_APP = $(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app
DMG_BACKGROUND = scripts/dmg-resources/background.png

# Version calculation
# Gets latest tag, strips 'v' prefix, counts commits ahead, formats as X.Y.Z-dev.N
# Falls back to 0.0.0-dev if no tags exist
LATEST_TAG := $(shell git describe --tags --abbrev=0 2>/dev/null)
TAG_VERSION := $(shell echo "$(LATEST_TAG)" | sed 's/^v//')
COMMITS_AHEAD := $(shell git rev-list $(LATEST_TAG)..HEAD --count 2>/dev/null || echo "0")
DEV_VERSION := $(if $(TAG_VERSION),$(if $(filter 0,$(COMMITS_AHEAD)),$(TAG_VERSION),$(TAG_VERSION)-dev.$(COMMITS_AHEAD)),0.0.0-dev)
VERSION ?= $(DEV_VERSION)

.PHONY: all build build-debug build-release run clean open \
        dmg dmg-debug dmg-release dmg-background \
        setup version help

# Default target
all: build

# ============================================================================
# Build targets
# ============================================================================

## build: Build the app (Debug configuration)
build: build-debug

## build-debug: Build the app in Debug configuration
build-debug:
	@echo "Building $(APP_NAME) (Debug)..."
	@xcodebuild build \
		-scheme $(SCHEME) \
		-configuration Debug \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		| grep -E "^(Build|Compile|Link|error:|warning:)" || true
	@echo "Build complete: $(DEBUG_APP)"

## build-release: Build the app in Release configuration
build-release:
	@echo "Building $(APP_NAME) (Release)..."
	@xcodebuild build \
		-scheme $(SCHEME) \
		-configuration Release \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		| grep -E "^(Build|Compile|Link|error:|warning:)" || true
	@echo "Build complete: $(RELEASE_APP)"

## run: Build and run the app (Debug)
run: build-debug
	@echo "Running $(APP_NAME)..."
	@open "$(DEBUG_APP)"

# ============================================================================
# DMG targets
# ============================================================================

## dmg-background: Generate DMG background image
dmg-background: $(DMG_BACKGROUND)

$(DMG_BACKGROUND): scripts/generate-dmg-background.js
	@echo "Generating DMG background..."
	@if [ ! -d scripts/node_modules ]; then \
		echo "Installing dependencies..."; \
		cd scripts && npm install; \
	fi
	@node scripts/generate-dmg-background.js

## dmg: Create DMG installer (Debug)
dmg: dmg-debug

## dmg-debug: Create DMG installer with Debug build
dmg-debug: build-debug dmg-background
	@echo "Creating DMG (Debug) - Version: $(VERSION)..."
	@rm -f $(APP_NAME)-$(VERSION)-debug.dmg
	@create-dmg \
		--volname "$(APP_NAME)" \
		--background "$(DMG_BACKGROUND)" \
		--window-pos 200 120 \
		--window-size 600 400 \
		--icon-size 100 \
		--icon "$(APP_NAME).app" 150 185 \
		--hide-extension "$(APP_NAME).app" \
		--app-drop-link 450 185 \
		--no-internet-enable \
		"$(APP_NAME)-$(VERSION)-debug.dmg" \
		"$(DEBUG_APP)"
	@echo "DMG created: $(APP_NAME)-$(VERSION)-debug.dmg"

## dmg-release: Create DMG installer with Release build
dmg-release: build-release dmg-background
	@echo "Creating DMG (Release) - Version: $(VERSION)..."
	@rm -f $(APP_NAME)-$(VERSION).dmg
	@create-dmg \
		--volname "$(APP_NAME)" \
		--background "$(DMG_BACKGROUND)" \
		--window-pos 200 120 \
		--window-size 600 400 \
		--icon-size 100 \
		--icon "$(APP_NAME).app" 150 185 \
		--hide-extension "$(APP_NAME).app" \
		--app-drop-link 450 185 \
		--no-internet-enable \
		"$(APP_NAME)-$(VERSION).dmg" \
		"$(RELEASE_APP)"
	@echo "DMG created: $(APP_NAME)-$(VERSION).dmg"

# ============================================================================
# Utility targets
# ============================================================================

## setup: Install development dependencies
setup:
	@echo "Checking dependencies..."
	@command -v create-dmg >/dev/null 2>&1 || { \
		echo "Installing create-dmg..."; \
		brew install create-dmg; \
	}
	@command -v node >/dev/null 2>&1 || { \
		echo "Node.js is required but not installed."; \
		exit 1; \
	}
	@if [ ! -d scripts/node_modules ]; then \
		echo "Installing Node.js dependencies..."; \
		cd scripts && npm install; \
	fi
	@echo "Setup complete!"

## open: Open project in Xcode
open:
	@open $(SCHEME).xcodeproj

## clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -rf DerivedData
	@rm -f *.dmg
	@rm -f $(DMG_BACKGROUND)
	@echo "Clean complete"

## clean-all: Remove all generated files including node_modules
clean-all: clean
	@rm -rf scripts/node_modules
	@rm -f scripts/package-lock.json

## version: Show current version
version:
	@echo "$(VERSION)"

# ============================================================================
# Help
# ============================================================================

## help: Show this help message
help:
	@echo "WhisperX - macOS Menu Bar Transcription App"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Build targets:"
	@echo "  build          Build the app (Debug)"
	@echo "  build-debug    Build the app in Debug configuration"
	@echo "  build-release  Build the app in Release configuration"
	@echo "  run            Build and run the app (Debug)"
	@echo ""
	@echo "DMG targets:"
	@echo "  dmg            Create DMG installer (Debug)"
	@echo "  dmg-debug      Create DMG installer with Debug build"
	@echo "  dmg-release    Create DMG installer with Release build"
	@echo "  dmg-background Generate DMG background image"
	@echo ""
	@echo "Utility targets:"
	@echo "  setup          Install development dependencies"
	@echo "  open           Open project in Xcode"
	@echo "  clean          Remove build artifacts"
	@echo "  clean-all      Remove all generated files including node_modules"
	@echo "  version        Show current version"
	@echo "  help           Show this help message"
	@echo ""
	@echo "Versioning:"
	@echo "  Auto-calculated from git tags (e.g., 0.1.0-dev.2 = 2 commits after v0.1.0)"
	@echo "  Falls back to 0.0.0-dev if no tags exist"
	@echo ""
	@echo "Examples:"
	@echo "  make                    # Build debug app"
	@echo "  make dmg-release        # Create release DMG (auto-versioned)"
	@echo "  make VERSION=1.0.0 dmg-release  # Create DMG with specific version"
