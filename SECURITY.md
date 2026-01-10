# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please report it responsibly.

### How to Report

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Email us at [mail@sadiksaifi.dev](mailto:mail@sadiksaifi.dev) with:
   - Description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact
   - Any suggested fixes (optional)

### What to Expect

- We will acknowledge receipt of your report within 48 hours
- We will provide an estimated timeline for a fix
- We will notify you when the vulnerability has been fixed
- We will credit you in the release notes (unless you prefer to remain anonymous)

## Security Considerations

WhisperX requires the following system permissions:

- **Microphone Access**: Required for recording audio for transcription
- **Accessibility (Input Monitoring)**: Required for global hotkey detection

### Data Privacy

- All audio processing is done locally using WhisperKit
- No audio data is sent to external servers
- Transcriptions are only stored in clipboard when auto-copy is enabled
- No telemetry or analytics data is collected

### Best Practices

- Only grant accessibility permissions to applications you trust
- Review the source code if you have concerns about data handling
- Keep your macOS and WhisperX updated to the latest versions
