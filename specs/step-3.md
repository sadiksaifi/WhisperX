# Step 3 — Local Wispr model integration (Apple silicon)

## Goal
Run Wispr transcription locally on device using the selected model variant, and produce a transcript string from the recorded audio file.

## Deliverables
- `WisprModelRunner` service with a stable Swift API:
  - `transcribe(audioURL: URL, model: WisprModelVariant) async throws -> String`
- Model management (download/import, storage path, basic integrity checks).
- Model selection list (Tiny → Large‑v3 Turbo) surfaced through settings (actual UI in Step 4).

## TODOs
- [x] Define `WisprModelVariant` enum with metadata table:
  - name, parameter count, VRAM, recommended use case.
- [x] Create a model storage layout under `~/Library/Application Support/<AppName>/Models/`:
  - WhisperKit manages model storage at its default cache location.
  - Models are downloaded from HuggingFace on first use.
- [x] Add `WisprModelRunner` abstraction:
  - Implementation detail isolated from the rest of the app.
  - Provide graceful fallback errors if model files are missing.
- [x] Integrate open‑source Wispr runtime:
  - Using WhisperKit Swift Package (https://github.com/argmaxinc/WhisperKit).
  - Apple Silicon optimized with Core ML / Neural Engine support.
- [x] Audio preprocessing:
  - AudioValidator utility validates incoming audio files.
  - WhisperKit handles format conversion internally.
- [x] Add cancellation support:
  - If the user releases the key and immediately presses again, cancel previous transcription.
- [x] Add a minimal benchmarking log line (model variant + latency).

## Design notes
- **Isolation**: only `WisprModelRunner` knows about model files or runtime APIs.
- **No network requirement**: all inference runs offline; any model downloads are optional and user‑initiated.
- **Concurrency**: transcription runs on a background Task; UI stays responsive.

## Verification plan (human)
- [x] With a model present on disk, transcription returns a string without UI hangs.
- [x] Missing model → clear, actionable error (e.g., "Model not installed").
- [x] Switching model variant changes which model file is used.
- [x] Basic latency logging appears in console.

## Agent documentation requirements
- [x] Document the model storage directory and naming convention in code (see ModelRunner.swift header).
- [x] Add a doc comment on `WisprModelRunner` explaining threading/cancellation behavior (see ModelRunner.swift).
- [x] Keep any runtime bridging code heavily commented (using pure Swift WhisperKit, no C bridging needed).
