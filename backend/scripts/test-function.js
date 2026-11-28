#!/usr/bin/env node
/** Neon Function (fetch handler) की जाँच — बिना deploy, बिना network */
import fn from '../functions/api.js';

const call = async (path, init) => {
  const res = await fn.fetch(new Request(`http://neon.local${path}`, init));
  const text = await res.text();
  let json; try { json = JSON.parse(text); } catch { json = null; }
  return { status: res.status, json, text };
};

let failed = 0;
const check = (name, ok, extra = '') => {
  console.log(`${ok ? '✓' : '✗'} ${name}${extra ? ' — ' + extra : ''}`);
  if (!ok) failed++;
};

const health = await call('/health');
check('GET /health → 200', health.status === 200 && health.json?.ok === true, `status ${health.status}`);

const bad = await call('/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ pin: '0000' }),
});
check('POST /api/auth/login (गलत पिन) → 401', bad.status === 401, `status ${bad.status}`);

const guard = await call('/api/admin/summary');
check('GET /api/admin/summary बिना token → 401', guard.status === 401, `status ${guard.status}`);

const notFound = await call('/api/nahi-hai');
check('अज्ञात रास्ता → 404', notFound.status === 404, `status ${notFound.status}`);

console.log(failed === 0 ? '\n✓ Neon Function handler ठीक चल रहा है' : `\n✗ ${failed} जाँच फेल`);
process.exit(failed === 0 ? 0 : 1);
