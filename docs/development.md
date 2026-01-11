# Development Guide

This document covers all the commands available for developing, building, and releasing WhisperX.

## Prerequisites

- **macOS 15.0+**
- **Xcode 16.2+**
- **Apple Silicon Mac** (M1/M2/M3/M4)

For creating DMG installers:
```bash
make install-tools
```

This installs `create-dmg` and `imagemagick` via Homebrew.

## Quick Start

```bash
# Clone and build
git clone https://github.com/sadiksaifi/WhisperX.git
cd WhisperX
make build
make run
```

## Development Commands

### Building

| Command | Description |
|---------|-------------|
| `make build` | Build debug configuration (default) |
| `make build-debug` | Build debug configuration |
| `make build-release` | Build unsigned release configuration |

**Debug build:**
```bash
make build
# Output: build/Build/Products/Debug/WhisperX.app
```

**Release build:**
```bash
make build-release
# Output: build/Build/Products/Release/WhisperX.app
```

The release build disables code signing for distribution without an Apple Developer account.

### Running

| Command | Description |
|---------|-------------|
| `make run` | Build debug and launch the app |
| `make xcode` | Open project in Xcode |

**Quick iteration:**
```bash
make run
```

**Using Xcode:**
```bash
make xcode
# Then press Cmd+R to build and run
```

## Release Commands

### Creating a DMG Installer

The DMG installer provides a professional "drag to Applications" experience.

| Command | Description |
|---------|-------------|
| `make install-tools` | Install create-dmg and imagemagick |
| `make dmg-background` | Generate the DMG background image |
| `make dmg` | Build release and create WhisperX.dmg |
| `make dmg-versioned VERSION=vX.X.X` | Create versioned DMG |

**First-time setup:**
```bash
make install-tools
```

**Create DMG:**
```bash
make dmg
# Creates: WhisperX.dmg
```

**Create versioned DMG:**
```bash
make dmg-versioned VERSION=v1.0.0
# Creates: WhisperX-v1.0.0.dmg
```

### DMG Contents

When a user opens the DMG:
- Window size: 660x400 pixels
- App icon on the left (position 160, 190)
- Applications folder symlink on the right (position 500, 190)
- Background image with visual arrow guide

### Release Workflow

For creating a new release:

```bash
# 1. Update version in Xcode project settings
# 2. Update CHANGELOG.md with release notes
# 3. Commit changes
git add .
git commit -m "chore: prepare v1.0.0 release"

# 4. Create and push tag
git tag v1.0.0
git push origin main
git push origin v1.0.0

# 5. GitHub Actions will automatically:
#    - Build the release
#    - Generate DMG background
#    - Create styled DMG installer
#    - Create GitHub release with DMG attached
```

## Maintenance Commands

| Command | Description |
|---------|-------------|
| `make clean` | Remove build/, *.dmg, and generated background |
| `make clean-all` | Deep clean including Xcode derived data |

**Regular cleanup:**
```bash
make clean
```

**Full reset (if builds are corrupted):**
```bash
make clean-all
```

## Manual Commands

If you need to run commands directly without Make:

### Build
```bash
# Debug
xcodebuild build -scheme whisperX -configuration Debug -derivedDataPath build

# Release (unsigned)
xcodebuild build -scheme whisperX -configuration Release -derivedDataPath build \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

### DMG Creation
```bash
# Generate background
./installer/generate-background.sh

# Create DMG
./installer/create-dmg.sh build/Build/Products/Release/WhisperX.app WhisperX.dmg
```

## Troubleshooting

### Build fails with signing errors

The release build is configured to skip code signing. If you see signing errors:
```bash
make clean
make build-release
```

### DMG creation fails

Ensure tools are installed:
```bash
make install-tools
```

Verify background image exists:
```bash
ls -la installer/dmg-background.png
# If missing: make dmg-background
```

### App won't launch (quarantine)

After installing from DMG, macOS may block the app:
```bash
xattr -cr /Applications/WhisperX.app
```

### Clean build issues

For persistent build problems:
```bash
make clean-all
make build
```

## CI/CD

The GitHub Actions workflow (`.github/workflows/release.yml`) handles releases automatically:

1. Triggered by pushing a tag matching `v*`
2. Installs build tools (`create-dmg`, `imagemagick`)
3. Builds release configuration
4. Generates DMG background image
5. Creates styled DMG installer
6. Extracts release notes from CHANGELOG.md
7. Creates GitHub release with DMG attachment

Tags ending in `-alpha` or `-beta` are marked as pre-releases.
