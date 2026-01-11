# WhisperX Makefile
# See docs/development.md for detailed documentation

.PHONY: all build build-debug build-release run clean xcode \
        dmg dmg-background install-tools help

# Default target
all: build

# ============================================================================
# Development
# ============================================================================

## Build debug configuration
build: build-debug

## Build debug configuration
build-debug:
	xcodebuild build \
		-scheme whisperX \
		-configuration Debug \
		-derivedDataPath build

## Build release configuration
build-release:
	xcodebuild build \
		-scheme whisperX \
		-configuration Release \
		-derivedDataPath build \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO

## Open project in Xcode
xcode:
	open whisperX.xcodeproj

## Run the debug build
run: build-debug
	open build/Build/Products/Debug/WhisperX.app

# ============================================================================
# Release & Distribution
# ============================================================================

## Install tools needed for DMG creation
install-tools:
	brew install create-dmg imagemagick

## Generate DMG background image
dmg-background:
	./installer/generate-background.sh

## Create DMG installer (requires build-release first)
dmg: build-release dmg-background
	./installer/create-dmg.sh \
		"build/Build/Products/Release/WhisperX.app" \
		"WhisperX.dmg"
	@echo "Created: WhisperX.dmg"

## Create versioned DMG (usage: make dmg-versioned VERSION=v1.0.0)
dmg-versioned: build-release dmg-background
	./installer/create-dmg.sh \
		"build/Build/Products/Release/WhisperX.app" \
		"WhisperX-$(VERSION).dmg"
	@echo "Created: WhisperX-$(VERSION).dmg"

# ============================================================================
# Maintenance
# ============================================================================

## Remove build artifacts
clean:
	rm -rf build/
	rm -f *.dmg
	rm -f installer/dmg-background.png

## Deep clean (also removes Xcode derived data)
clean-all: clean
	rm -rf ~/Library/Developer/Xcode/DerivedData/whisperX-*

# ============================================================================
# Help
# ============================================================================

## Show this help message
help:
	@echo "WhisperX Development Commands"
	@echo "=============================="
	@echo ""
	@echo "Development:"
	@echo "  make build          Build debug configuration"
	@echo "  make build-debug    Build debug configuration"
	@echo "  make build-release  Build release configuration (unsigned)"
	@echo "  make run            Build and run debug build"
	@echo "  make xcode          Open project in Xcode"
	@echo ""
	@echo "Release:"
	@echo "  make install-tools  Install create-dmg and imagemagick"
	@echo "  make dmg-background Generate DMG background image"
	@echo "  make dmg            Build release and create DMG installer"
	@echo "  make dmg-versioned VERSION=vX.X.X"
	@echo "                      Create versioned DMG (e.g., WhisperX-v1.0.0.dmg)"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean          Remove build artifacts and DMGs"
	@echo "  make clean-all      Deep clean including Xcode derived data"
	@echo ""
	@echo "For detailed documentation, see docs/development.md"
