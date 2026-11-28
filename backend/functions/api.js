/**
 * Neon Function का entry — पूरा Express API, Neon के compute पर।
 *
 * Neon Functions एक `fetch(request) → Response` handler चाहते हैं; Express
 * Node-style `(req, res)` है। `@hono/node-server` का `getRequestListener`
 * इन दोनों के बीच का पुल है (इसलिए दोबारा राउटर नहीं लिखना पड़ा)।
 *
 * DATABASE_URL Neon खुद inject करता है (same branch, same region) — इसलिए
 * `pg` का Pool यहाँ लंबे समय तक खुला रहता है और हर request पर नई connection
 * नहीं खुलती (Lambda से बड़ा फ़ायदा)।
 */
import { createApp } from '../src/app.js';
import { nodeToFetch } from './fetch-adapter.js';

const app = createApp();
const fetchHandler = nodeToFetch(app);

export default {
  fetch: (request) => fetchHandler(request),
};
