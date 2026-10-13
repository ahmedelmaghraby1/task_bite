export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const method = request.method;

    if (method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    const key = env.GROQ_API_KEY;
    if (!key) {
      return json(500, { error: 'GROQ_API_KEY not configured' });
    }

    try {
      if (url.pathname.endsWith('/transcribe') || url.pathname === '/transcribe') {
        if (method !== 'POST') {
          return json(405, { error: 'Method Not Allowed' });
        }
        const contentType = request.headers.get('content-type') || '';
        if (!contentType.includes('multipart/form-data')) {
          return json(400, { error: 'Expected multipart/form-data' });
        }
        const formData = await request.formData();
        const endpoint = env.TRANSCRIBE_ENDPOINT || 'https://api.groq.com/openai/v1/audio/transcriptions';
        const out = await fetch(endpoint, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${key}`,
            Accept: 'application/json',
          },
          body: formData,
        });
        const body = await out.text();
        return new Response(body, {
          status: out.status,
          headers: {
            ...corsHeaders(),
            'content-type': out.headers.get('content-type') || 'application/json',
          },
        });
      }

      if (url.pathname.endsWith('/task') || url.pathname === '/task') {
        if (method !== 'POST') {
          return json(405, { error: 'Method Not Allowed' });
        }
        const body = await request.text();
        const endpoint = env.CHAT_ENDPOINT || 'https://api.groq.com/openai/v1/chat/completions';
        const out = await fetch(endpoint, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${key}`,
            'content-type': 'application/json',
            Accept: 'application/json',
          },
          body,
        });
        const resBody = await out.text();
        return new Response(resBody, {
          status: out.status,
          headers: {
            ...corsHeaders(),
            'content-type': out.headers.get('content-type') || 'application/json',
          },
        });
      }

      return json(404, { error: 'Not found' });
    } catch (err) {
      return json(502, { error: err instanceof Error ? err.message : 'Bad gateway' });
    }
  },
};

function corsHeaders() {
  return {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type,authorization',
  };
}

function json(status, obj) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...corsHeaders(), 'content-type': 'application/json' },
  });
}
