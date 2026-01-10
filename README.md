# WhisperX

> [!WARNING]
> This project is in active development and not yet ready for general use. If you'd like to try it, you can build it manually at your own risk.

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
- Xcode 16.2+ (for building)

## Getting Started

```bash
# Clone the repository
git clone https://github.com/yourusername/whisperX.git
cd whisperX

# Open in Xcode
open whisperX.xcodeproj

# Build and run (Cmd+R)
```

Or build from command line:

```bash
xcodebuild build -scheme whisperX -configuration Release
```

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
