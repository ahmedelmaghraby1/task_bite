# Cloudflare Worker – minimal AI proxy

This Worker forwards audio transcription and task generation requests to Groq while keeping `GROQ_API_KEY` a secret.

## Setup
1. Install [Wrangler](https://developers.cloudflare.com/workers/wrangler/).
2. Set the secret:
   ```sh
   wrangler secret put GROQ_API_KEY
   ```
3. Deploy:
   ```sh
   wrangler deploy
   ```

## Environment
- `GROQ_API_KEY` (secret) – Groq API key (e.g. `gsk_...`)
- `TRANSCRIBE_ENDPOINT` (optional) – default `https://api.groq.com/openai/v1/audio/transcriptions`
- `CHAT_ENDPOINT` (optional) – default `https://api.groq.com/openai/v1/chat/completions`

## Routes
- `POST /transcribe` – multipart/form-data. Required: `file`, `model`. Optional: `language`, `response_format`. Returns Groq’s response (typically `{ text: ... }`).
- `POST /task` – `application/json`. Forwards the body (OpenAI chat-completions shape). Returns Groq’s response.

All responses include CORS headers for local dev if needed.
