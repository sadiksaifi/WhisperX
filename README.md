# WhisperX

[![GitHub release](https://img.shields.io/github/v/release/sadiksaifi/WhisperX?include_prereleases&label=version)](https://github.com/sadiksaifi/WhisperX/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-15.0%2B-blue)](https://github.com/sadiksaifi/WhisperX)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%2FM2%2FM3%2FM4-orange)](https://github.com/sadiksaifi/WhisperX)

**Fast, private, offline speech-to-text for Mac.**

Turn your voice into text instantly with a single hotkey. WhisperX runs entirely on your Mac using OpenAI's Whisper model — no internet required, no data leaves your device.

> [!TIP]
> **Quick Start:** [Download the latest release](https://github.com/sadiksaifi/WhisperX/releases) → Open DMG → Drag to Applications → Done!

---

## Table of Contents

- [Why WhisperX?](#why-whisperx)
- [How It Works](#how-it-works)
- [Installation](#installation)
  - [Download](#download)
  - [First Launch](#first-launch)
  - [Permissions](#permissions)
- [Features](#features)
- [Models](#models)
- [Building from Source](#building-from-source)
- [License](#license)

---

## Why WhisperX?

| | |
|---|---|
| **Completely Private** | Your audio never leaves your Mac. No cloud, no servers, no subscriptions. |
| **Blazing Fast** | Optimized for Apple Silicon. Transcribe in seconds, not minutes. |
| **Dead Simple** | Hold a key, speak, release. Text appears in your clipboard. |
| **Works Everywhere** | Paste your transcription into any app instantly. |

---

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  1. HOLD          2. SPEAK          3. RELEASE              │
│  ─────────────────────────────────────────────────────      │
│  ⌥ + Space        🎤 "Hello..."     📋 Text copied!         │
│  (hold hotkey)    (speak clearly)   (paste anywhere)        │
└─────────────────────────────────────────────────────────────┘
```

---

## Installation

### System Requirements

| Requirement | Minimum |
|-------------|---------|
| **macOS** | 15.0 (Sequoia) or later |
| **Processor** | Apple Silicon (M1/M2/M3/M4) |

### Download

1. Go to [**Releases**](https://github.com/sadiksaifi/WhisperX/releases)
2. Download `WhisperX-vX.X.X.dmg` from the latest release
3. Open the DMG and drag WhisperX to your Applications folder

### First Launch

> [!IMPORTANT]
> **Gatekeeper Warning:** Since WhisperX is distributed without code signing, macOS will block it by default.

**Option 1: Right-click to open (Recommended)**

1. Right-click (or Control-click) on WhisperX.app
2. Select "Open" from the menu
3. Click "Open" in the dialog that appears

> [!WARNING]
> **Option 2: Terminal command**
>
> Run this command after moving WhisperX to Applications:
> ```bash
> xattr -cr /Applications/WhisperX.app
> ```
> This removes the quarantine attribute that macOS applies to downloaded apps.

> [!NOTE]
> **Why is this safe?** You're downloading directly from the official GitHub repository. The app runs entirely locally and doesn't connect to any external servers.

### Permissions

> [!WARNING]
> WhisperX requires two system permissions to function. Without these, the app cannot record audio or detect your hotkey.

| Permission | Purpose | How to Enable |
|------------|---------|---------------|
| **Microphone** | Capture your voice for transcription | Grant when prompted |
| **Accessibility** | Detect global hotkey from any app | `System Settings → Privacy & Security → Accessibility` |

---

## Features

| Feature | Description |
|---------|-------------|
| **Push-to-talk** | Customizable global hotkey (default: `⌥ + Space`) |
| **Multiple Models** | Choose from tiny to large-v3-turbo |
| **Auto-copy** | Transcription automatically copied to clipboard |
| **Auto-paste** | Optionally paste immediately after transcription |
| **Device Selection** | Choose your preferred microphone |
| **Visual Feedback** | Floating HUD shows recording/transcription status |

---

## Models

Choose the right balance of speed and accuracy:

| Model | Size | Speed | Accuracy | Best For |
|-------|------|-------|----------|----------|
| `tiny` | ~39 MB | ⚡⚡⚡⚡⚡ | ★☆☆☆☆ | Quick drafts |
| `base` | ~74 MB | ⚡⚡⚡⚡ | ★★☆☆☆ | **Default** - everyday use |
| `small` | ~244 MB | ⚡⚡⚡ | ★★★☆☆ | General purpose |
| `medium` | ~769 MB | ⚡⚡ | ★★★★☆ | Accurate transcription |
| `large-v3` | ~1.5 GB | ⚡ | ★★★★★ | Maximum accuracy |
| `large-v3-turbo` | ~809 MB | ⚡⚡⚡⚡ | ★★★★★ | Fast + accurate |

> [!TIP]
> The app defaults to `base` for fast startup. Switch to `large-v3-turbo` for near-maximum accuracy with great speed. Models download automatically on first use.

---

<details>
<summary><h2>Building from Source</h2></summary>

### Requirements

- Xcode 16.2+

### Clone and Build

```bash
# Clone the repository
git clone https://github.com/sadiksaifi/WhisperX.git
cd WhisperX

# Open in Xcode
open whisperX.xcodeproj

# Build and run (Cmd+R)
```

### Command Line Build

```bash
# Install development dependencies (first time only)
make setup

# Build debug app
make build-debug

# Build release app
make build-release

# Build and run
make run

# Show current version (auto-calculated from git tags)
make version
```

### Create DMG

```bash
# Create release DMG (auto-versioned)
make dmg-release

# Create DMG with specific version
make VERSION=1.0.0 dmg-release
```

> [!NOTE]
> Versions are automatically calculated from git tags (e.g., `0.1.0-dev.2` means 2 commits after `v0.1.0`). See `docs/RELEASES.md` for release workflow details.

</details>

---

## License

[MIT](LICENSE) — Free and open source.
