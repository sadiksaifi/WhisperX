# Release Workflow

This document describes how to create and publish releases for WhisperX.

## Version Format

WhisperX uses [Semantic Versioning](https://semver.org/) with pre-release suffixes:

| Version | Channel | Description |
|---------|---------|-------------|
| `0.1.0` | Stable | Production-ready release |
| `0.1.0-beta.1` | Beta | Feature-complete, testing phase |
| `0.1.0-alpha.1` | Alpha | Early preview, experimental |
| `0.1.0-dev.2` | Dev | Local development build (not released) |

### Version Ordering

Versions are compared as: `dev < alpha < beta < stable`

For the same base version:
```
0.1.0 > 0.1.0-beta.2 > 0.1.0-beta.1 > 0.1.0-alpha.2 > 0.1.0-alpha.1 > 0.1.0-dev.1
```

A higher base version always wins:
```
0.2.0-alpha.1 > 0.1.0 (stable)
```

## Creating a Release

### 1. Update CHANGELOG.md

Add a new section for the version:

```markdown
## [0.1.0] - 2024-01-15

### Added
- New feature X

### Fixed
- Bug Y
```

### 2. Create and Push a Tag

```bash
# Stable release
git tag v0.1.0
git push origin v0.1.0

# Beta release
git tag v0.1.0-beta.1
git push origin v0.1.0-beta.1

# Alpha release
git tag v0.1.0-alpha.1
git push origin v0.1.0-alpha.1
```

### 3. Automated CI Process

When a tag is pushed, GitHub Actions automatically:

1. **Builds** the app with the version embedded (`MARKETING_VERSION`)
2. **Creates** a DMG installer with drag-to-Applications support
3. **Generates** release notes from CHANGELOG.md
4. **Publishes** to GitHub Releases
   - Alpha/Beta tags are marked as **pre-release**
   - Stable tags are marked as **latest release**

### 4. Verify the Release

1. Go to [GitHub Releases](https://github.com/sadiksaifi/WhisperX/releases)
2. Verify the DMG is attached
3. Download and test the installation

## Update Channels

Users can select their preferred update channel in Settings:

| User's Build | Available Channels |
|--------------|-------------------|
| Stable | Stable, Beta |
| Beta | Stable, Beta |
| Alpha | Stable, Beta, Alpha |
| Dev | Stable, Beta, Alpha |

### Channel Behavior

- **Stable users**: Only receive stable updates
- **Beta users**: Receive beta OR stable updates (whichever is newer)
- **Alpha users**: Receive alpha, beta, OR stable updates (whichever is newer)

### Special Cases

1. **Pre-release older than stable**: If a user is on `0.1.0-beta.1` but `0.2.0` (stable) is available, they'll be notified that a newer stable version exists.

2. **Dev builds**: Local development builds (`-dev.N`) show a warning in the UI but use the Alpha channel for updates.

## Local Development Builds

When building locally with `make`, the version is auto-calculated:

```bash
make version
# Output: 0.1.0-dev.2 (2 commits ahead of v0.1.0)
```

### Build Commands

```bash
# Build with auto-calculated version
make build-debug
make build-release

# Build with specific version (for testing)
make build-debug VERSION=0.1.0-alpha.1
make build-debug VERSION=0.1.0-beta.1

# Create DMG
make dmg-release
make dmg-release VERSION=0.1.0
```

## GitHub API Integration

The app fetches releases from:
```
https://api.github.com/repos/sadiksaifi/WhisperX/releases
```

### Rate Limiting

- Unauthenticated: 60 requests/hour
- Local throttling: 1 hour between checks
- Respects `Retry-After` header

### Release Filtering

The app filters releases based on:
1. User's channel preference
2. `prerelease` field from GitHub API
3. Version tag parsing (e.g., `-alpha`, `-beta`)

## Troubleshooting

### Release not showing for users

1. Check if the tag follows the format: `v*` (e.g., `v0.1.0`)
2. Verify GitHub Actions completed successfully
3. Check if release is marked correctly (prerelease vs latest)

### Version not displaying correctly

1. Ensure `MARKETING_VERSION` is set during build
2. Check `CFBundleShortVersionString` in the built app:
   ```bash
   /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
     build/Build/Products/Release/WhisperX.app/Contents/Info.plist
   ```

### Users not receiving updates

1. Check user's channel setting in Settings
2. Verify the release exists on GitHub
3. Check if version comparison is correct (newer version should be higher)
