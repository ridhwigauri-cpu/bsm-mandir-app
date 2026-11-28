#!/usr/bin/env node
/**
 * `npm run smoke` — सर्वर को असल में चालू करके /health और एक सार्वजनिक रास्ता जाँचता है।
 * (डेटाबेस के बिना भी चलता है — ताकि deploy से पहले पता चले कि ऐप बूट हो रहा है)
 */
import { createApp } from '../src/app.js';

const app = createApp();
const server = app.listen(0);
const port = server.address().port;
const base = `http://127.0.0.1:${port}`;

const checks = [];
const check = async (name, fn) => {
  try {
    const ok = await fn();
    checks.push([name, ok]);
    console.log(`${ok ? '✓' : '✗'} ${name}`);
  } catch (e) {
    checks.push([name, false]);
    console.log(`✗ ${name} — ${e.message}`);
  }
};

await check('GET /health → ok:true', async () => {
  const r = await fetch(`${base}/health`);
  const j = await r.json();
  return r.status === 200 && j.ok === true;
});

await check('POST /api/auth/login (गलत पिन) → 401', async () => {
  const r = await fetch(`${base}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ pin: '0000' }),
  });
  return r.status === 401;
});

await check('GET /api/admin/summary बिना token → 401', async () => {
  const r = await fetch(`${base}/api/admin/summary`);
  return r.status === 401;
});

server.close();
const failed = checks.filter(([, ok]) => !ok).length;
console.log(failed === 0 ? '\n✓ स्मोक टेस्ट पास' : `\n✗ ${failed} जाँच फेल`);
process.exit(failed === 0 ? 0 : 1);
