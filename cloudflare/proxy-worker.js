// Cloudflare Worker to proxy mindapx.lafabriqueduleader.com to S3 over HTTPS.
// Set environment variable S3_HOST to your bucket host, e.g. "your-bucket.s3.us-east-1.amazonaws.com".
// Route: mindapx.lafabriqueduleader.com/*
export default {
  async fetch(request, env) {
    const targetHost = env.S3_HOST;
    if (!targetHost) {
      return new Response('S3_HOST not configured', { status: 500 });
    }

    const upstream = new URL(request.url);
    upstream.protocol = 'https:';
    upstream.hostname = targetHost;

    const headers = new Headers(request.headers);
    headers.set('host', targetHost);

    const init = {
      method: request.method,
      headers,
      redirect: 'follow',
      body: ['GET', 'HEAD'].includes(request.method) ? undefined : request.body,
    };

    // Try requested path
    let res = await fetch(upstream, init);

    // SPA fallback for S3 website-style 403/404
    if (res.status === 403 || res.status === 404) {
      const fallback = new URL(upstream);
      fallback.pathname = '/index.html';
      res = await fetch(fallback, init);
    }

    return new Response(res.body, {
      status: res.status,
      statusText: res.statusText,
      headers: res.headers,
    });
  },
};
