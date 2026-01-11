# WhisperX

**Fast, private, offline speech-to-text for Mac.**

Turn your voice into text instantly with a single hotkey. WhisperX runs entirely on your Mac using OpenAI's Whisper model — no internet required, no data leaves your device.

## Why WhisperX?

- **Completely Private** — Your audio never leaves your Mac. No cloud, no servers, no subscriptions.
- **Blazing Fast** — Optimized for Apple Silicon. Transcribe in seconds, not minutes.
- **Dead Simple** — Hold a key, speak, release. Text appears in your clipboard.
- **Works Everywhere** — Paste your transcription into any app instantly.

## Features

- Push-to-talk with customizable global hotkey
- Multiple Whisper model options (tiny to large-v3-turbo)
- Auto-copy to clipboard
- Auto-paste after transcription
- Choose your preferred microphone
- Visual feedback while recording

## Models

Choose the right balance of speed and accuracy for your needs:

| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| tiny | 39 MB | Fastest | Basic |
| base | 74 MB | Fast | Good |
| small | 244 MB | Moderate | Better |
| medium | 769 MB | Slow | High |
| large-v3 | 1.5 GB | Slowest | Highest |
| large-v3-turbo | 809 MB | Fast | High |

Models are downloaded automatically on first use.

## Requirements

- macOS 15.0+
- Apple Silicon (M1/M2/M3/M4)

## Installation

### Download

1. Go to [Releases](https://github.com/sadiksaifi/WhisperX/releases)
2. Download `WhisperX-vX.X.X.dmg` from the latest release
3. Open the DMG and drag WhisperX to your Applications folder

### First Launch (Important)

Since WhisperX is distributed without code signing, macOS will block it by default. To run the app:

**Option 1: Right-click to open**
1. Right-click (or Control-click) on WhisperX.app
2. Select "Open" from the menu
3. Click "Open" in the dialog that appears

**Option 2: Terminal command**

Run this command after moving WhisperX to Applications:

```bash
xattr -cr /Applications/WhisperX.app
```

This removes the quarantine attribute that macOS applies to downloaded apps.

> **Note:** This is safe because you're downloading directly from the official GitHub repository. The app runs entirely locally and doesn't connect to any external servers.

## Building from Source

Requirements:
- macOS 15.0+
- Xcode 16.2+
- Apple Silicon (M1/M2/M3/M4)

```bash
# Clone the repository
git clone https://github.com/sadiksaifi/WhisperX.git
cd WhisperX

# Build and run
make run

# Or open in Xcode (Cmd+R to run)
make xcode
```

### Make Commands

| Command | Description |
|---------|-------------|
| `make build` | Build debug configuration |
| `make build-release` | Build release configuration |
| `make run` | Build and launch the app |
| `make xcode` | Open in Xcode |
| `make dmg` | Create DMG installer |
| `make clean` | Remove build artifacts |
| `make help` | Show all commands |

For DMG creation, first install the required tools:
```bash
make install-tools  # Installs create-dmg and imagemagick
make dmg            # Creates WhisperX.dmg
```

See [docs/development.md](docs/development.md) for detailed documentation.

## How It Works

1. Press and hold your hotkey (default: `Option + Space`)
2. Speak
3. Release — your text is ready to paste

## Permissions

WhisperX needs two system permissions:

- **Microphone** — To capture your voice
- **Accessibility** — To detect the global hotkey

Grant these when prompted, or enable manually in `System Settings → Privacy & Security`.

## License

[MIT](LICENSE)
