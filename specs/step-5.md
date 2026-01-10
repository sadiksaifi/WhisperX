# Step 5 — End‑to‑end pipeline + polish

## Goal
Complete the full flow: press → record → transcribe → copy to clipboard, with robust error handling and user feedback.

## Deliverables
- End‑to‑end pipeline wired through `AppState`.
- Clipboard service integration.
- User feedback on errors and transcript availability.
- Optional: sound/haptic cues for start/stop (HIG‑appropriate, minimal).

## TODOs
- [x] Build `TranscriptionPipeline` orchestration:
  - Triggered on key release with audio URL.
  - Calls `WisprModelRunner` and stores last transcript.
  - Exposes state machine: idle → listening → transcribing → idle.
- [x] Add `ClipboardService`:
  - Copy transcript to clipboard automatically if enabled.
  - Manual menu action copies last transcript.
- [x] Error handling UX:
  - Non‑blocking alerts or menu bar status for failures.
  - Log full error details with actionable messages.
- [x] Add lightweight success feedback:
  - Optional tiny HUD "Copied" toast.
  - Menu bar status updates.
- [x] Performance tuning:
  - Avoid main‑thread work in transcription.
  - Ensure audio file cleanup after transcription completes.
- [x] Copy, edit, all user-facing strings/labels/button/etc:
  - Replace developer-centric labels with natural, concise wording for Settings, menu bar, and HUD.
  - Keep text HIG-aligned (short labels, sentence-case where appropriate).

## Verification plan (human)
- Full press‑to‑talk flow produces transcript and copies to clipboard.
- Menu item “Copy last transcript” works.
- Errors (missing model, permissions) show clear guidance without crashing.
- No HUD remains stuck on screen after errors.
- Labels in Settings, menu bar, and HUD read naturally and feel Apple‑native.

## Agent documentation requirements
- Document the pipeline state machine and transitions in code.
- Add comments where cleanup happens (temp audio files, cancellation).
