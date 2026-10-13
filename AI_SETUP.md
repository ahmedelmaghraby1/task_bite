# AI Setup Guide

This project implements a two-stage AI pipeline (transcription + task extraction) that never ships secrets in the app.

## Two-stage design
- Stage A: upload a real `.m4a` recording to a speech-to-text service (Groq Whisper). 
- Stage B: send a verified transcript to a chat completion endpoint for structured JSON (title + bullet-point description + optional due date).

The app talks to two configurable HTTP endpoints: `TASK_AI_TRANSCRIBE_ENDPOINT` and `TASK_AI_TASK_ENDPOINT`.

## Recommended: use a server-side proxy (secure)
Production builds must not put an API key in the app. Deploy a tiny proxy that forwards requests to Groq and injects the key server-side.

### Quick Cloudflare Worker reference
`backend/cloudflare-worker/index.js` (see repo) exposes:
- `POST /transcribe` – accepts `multipart/form-data` with `file`, `model`, `language`, `response_format=json` (or just forwards). Forwards to `https://api.groq.com/openai/v1/audio/transcriptions`.
- `POST /task` – accepts JSON. Forwards to `https://api.groq.com/openai/v1/chat/completions`.

Deploy via Wrangler. Set `GROQ_API_KEY` as a secret.

## Local dev (direct to Groq)
For testing with lowest friction (no proxy), point endpoints directly at Groq and pass the key via dart-define. This is for local dev only.

Example `flutter run`:
```sh
flutter run \
  --dart-define=TASK_AI_TRANSCRIBE_ENDPOINT=https://api.groq.com/openai/v1/audio/transcriptions \
  --dart-define=TASK_AI_TASK_ENDPOINT=https://api.groq.com/openai/v1/chat/completions \
  --dart-define=TASK_AI_API_KEY=gsk_... \
  --dart-define=TASK_AI_TRANSCRIBE_MODEL=whisper-large-v3-turbo \
  --dart-define=TASK_AI_MODEL=llama-3.3-70b-versatile
```

## Flutter config file (optional)
You can use `dart_define.example.json` as a template with `--dart-define-from-file dart_define.json` (add the real file to `.gitignore`).

## Notes
- Never hardcode keys in source or commit them.
- Test with a real device: microphone + internet.
- Free tier rate limits apply (see provider docs). The defaults use models typically available on Groq’s free tier.
- If not configured, the UI shows a clear “AI is not configured…” notice; recording is blocked before uploading.
