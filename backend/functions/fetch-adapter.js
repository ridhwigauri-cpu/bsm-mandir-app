/**
 * Node-style handler (Express) → `fetch(request) → Response`
 *
 * Neon Functions एक fetch handler चाहते हैं, Express `(req, res)` चाहता है।
 * यह छोटा adapter असली `IncomingMessage`/`ServerResponse` बनाकर Express को
 * वही देता है जो उसे चाहिए, और आख़िर में Response लौटा देता है।
 */
import { IncomingMessage, ServerResponse } from 'node:http';
import { Socket } from 'node:net';

export function nodeToFetch(handler, { timeoutMs = 25_000 } = {}) {
  return async function fetch(request) {
    const url = new URL(request.url);

    // ── request बनाएँ ──
    const socket = new Socket();
    const req = new IncomingMessage(socket);
    req.method = request.method;
    req.url = `${url.pathname}${url.search}`;
    req.httpVersion = '1.1';
    req.httpVersionMajor = 1;
    req.httpVersionMinor = 1;
    req.headers = Object.fromEntries(request.headers.entries());
    // rate-limit / logging के लिए IP (Socket के getters हैं, इसलिए defineProperty)
    const ip = (request.headers.get('x-forwarded-for') ?? '').split(',')[0].trim() || '127.0.0.1';
    Object.defineProperty(socket, 'remoteAddress', { value: ip, configurable: true });
    Object.defineProperty(socket, 'remotePort', { value: 0, configurable: true });
    req.socket = socket;
    req.rawHeaders = [...request.headers.entries()].flat();

    const hasBody = !(request.method === 'GET' || request.method === 'HEAD');
    if (hasBody) {
      const buf = Buffer.from(await request.arrayBuffer());
      if (buf.length > 0) {
        req.headers['content-length'] = String(buf.length);
        req.push(buf);
      }
    }
    req.push(null);

    // ── response इकट्ठा करें ──
    const res = new ServerResponse(req);
    const chunks = [];

    let timer;
    const done = new Promise((resolve, reject) => {
      res.write = (chunk, encoding, cb) => {
        if (chunk) chunks.push(Buffer.from(chunk, typeof encoding === 'string' ? encoding : undefined));
        if (typeof encoding === 'function') encoding();
        else if (typeof cb === 'function') cb();
        return true;
      };
      res.end = (chunk, encoding, cb) => {
        if (chunk && typeof chunk !== 'function') {
          chunks.push(Buffer.from(chunk, typeof encoding === 'string' ? encoding : undefined));
        }
        if (typeof chunk === 'function') chunk();
        else if (typeof encoding === 'function') encoding();
        else if (typeof cb === 'function') cb();
        clearTimeout(timer);
        resolve();
        return res;
      };
      res.on('error', (e) => { clearTimeout(timer); reject(e); });
      timer = setTimeout(() => reject(new Error('handler timeout')), timeoutMs);
      if (typeof timer.unref === 'function') timer.unref();
    });

    handler(req, res);
    await done;

    // ── Response ──
    const headers = new Headers();
    for (const [k, v] of Object.entries(res.getHeaders())) {
      if (v === undefined) continue;
      if (Array.isArray(v)) v.forEach((item) => headers.append(k, String(item)));
      else headers.set(k, String(v));
    }

    const status = res.statusCode || 200;
    const body = chunks.length > 0 && !(status === 204 || status === 304) ? Buffer.concat(chunks) : null;
    return new Response(body, { status, headers });
  };
}
