# Step 3 — Local Wispr model integration (Apple silicon)

## Goal
Run Wispr transcription locally on device using the selected model variant, and produce a transcript string from the recorded audio file.

## Deliverables
- `WisprModelRunner` service with a stable Swift API:
  - `transcribe(audioURL: URL, model: WisprModelVariant) async throws -> String`
- Model management (download/import, storage path, basic integrity checks).
- Model selection list (Tiny → Large‑v3 Turbo) surfaced through settings (actual UI in Step 4).

## TODOs
- [ ] Define `WisprModelVariant` enum with metadata table:
  - name, parameter count, VRAM, recommended use case.
- [ ] Create a model storage layout under `~/Library/Application Support/<AppName>/Models/`:
  - one folder per variant
  - optional checksum file for integrity
- [ ] Add `WisprModelRunner` abstraction:
  - Implementation detail isolated from the rest of the app.
  - Provide graceful fallback errors if model files are missing.
- [ ] Integrate open‑source Wispr runtime:
  - Prefer a Swift Package if available; otherwise add a local framework/binary.
  - Ensure Apple Silicon optimized backend (Metal/Accelerate) is used.
- [ ] Audio preprocessing:
  - Convert or validate incoming audio to the format required by Wispr.
  - Centralize format conversion; avoid repeated work.
- [ ] Add cancellation support:
  - If the user releases the key and immediately presses again, cancel previous transcription.
- [ ] Add a minimal benchmarking log line (model variant + latency).

## Design notes
- **Isolation**: only `WisprModelRunner` knows about model files or runtime APIs.
- **No network requirement**: all inference runs offline; any model downloads are optional and user‑initiated.
- **Concurrency**: transcription runs on a background Task; UI stays responsive.

## Verification plan (human)
- With a model present on disk, transcription returns a string without UI hangs.
- Missing model → clear, actionable error (e.g., “Model not installed”).
- Switching model variant changes which model file is used.
- Basic latency logging appears in console.

## Agent documentation requirements
- Document the model storage directory and naming convention in code.
- Add a doc comment on `WisprModelRunner` explaining threading/cancellation behavior.
- Keep any runtime bridging code heavily commented (especially unsafe pointers/C APIs).
