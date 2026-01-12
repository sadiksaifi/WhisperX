# Release Guide

Step-by-step guide for releasing new versions of WhisperX.

## Pre-Release Checklist

- [ ] All features/fixes are merged to `main`
- [ ] App builds successfully (`make build-release`)
- [ ] App runs without errors
- [ ] CHANGELOG.md is updated

## Release Types

| Type | Tag Format | Example | Use Case |
|------|------------|---------|----------|
| Alpha | `v0.1.0-alpha.N` | `v0.1.0-alpha.1` | Early testing, experimental features |
| Beta | `v0.1.0-beta.N` | `v0.1.0-beta.1` | Feature complete, needs testing |
| Stable | `v0.1.0` | `v0.1.0` | Production ready |

## Step 1: Update CHANGELOG.md

Add a new section at the top of CHANGELOG.md:

```markdown
## [0.1.0-alpha.1] - YYYY-MM-DD

### Added
- Feature X
- Feature Y

### Changed
- Change Z

### Fixed
- Bug fix A
```

## Step 2: Commit the Changelog

```bash
git add CHANGELOG.md
git commit -m "docs: add changelog for vX.Y.Z"
git push origin main
```

## Step 3: Create the Tag

```bash
# For alpha release
git tag v0.1.0-alpha.1

# For beta release
git tag v0.1.0-beta.1

# For stable release
git tag v0.1.0
```

## Step 4: Push the Tag

```bash
git push origin <tag-name>
```

Example:
```bash
git push origin v0.1.0-alpha.1
```

## Step 5: Monitor CI

1. Go to [Actions](https://github.com/sadiksaifi/WhisperX/actions)
2. Watch the "Release" workflow
3. Wait for it to complete (usually 3-5 minutes)

## Step 6: Verify the Release

1. Go to [Releases](https://github.com/sadiksaifi/WhisperX/releases)
2. Check that:
   - Release is created with correct tag
   - DMG file is attached (`WhisperX-vX.Y.Z.dmg`)
   - Release notes are correct
   - Alpha/Beta releases are marked as "Pre-release"

## Step 7: Test the Release

```bash
# Download and test the DMG
cd ~/Downloads
open WhisperX-v0.1.0-alpha.1.dmg
```

Verify:
- DMG opens with drag-to-Applications layout
- App installs correctly
- App shows correct version in Settings
- Update check works

## Incrementing Versions

### Alpha Releases
```
v0.1.0-alpha.1 → v0.1.0-alpha.2 → v0.1.0-alpha.3
```

### Promoting Alpha to Beta
```
v0.1.0-alpha.3 → v0.1.0-beta.1
```

### Promoting Beta to Stable
```
v0.1.0-beta.2 → v0.1.0
```

### Next Version Cycle
```
v0.1.0 → v0.2.0-alpha.1 (new features)
v0.1.0 → v0.1.1 (patch/hotfix)
```

## Deleting a Release (if needed)

If something went wrong:

```bash
# Delete local tag
git tag -d v0.1.0-alpha.1

# Delete remote tag
git push origin --delete v0.1.0-alpha.1

# Delete GitHub release
gh release delete v0.1.0-alpha.1 --yes
```

Then fix the issue and start from Step 1.

## Quick Reference

### Full Release Flow (Copy-Paste)

```bash
# 1. Update CHANGELOG.md manually, then:
git add CHANGELOG.md
git commit -m "docs: add changelog for v0.1.0-alpha.1"
git push origin main

# 2. Tag and release
git tag v0.1.0-alpha.1
git push origin v0.1.0-alpha.1

# 3. Monitor at: https://github.com/sadiksaifi/WhisperX/actions
```

### Emergency Hotfix

```bash
# On main branch
git checkout main
git pull origin main

# Make fix, then:
git add .
git commit -m "fix: critical bug description"
git push origin main

# Tag as patch version
git tag v0.1.1
git push origin v0.1.1
```
