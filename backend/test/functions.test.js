import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { newDb } from 'pg-mem';

// ── env (config import से पहले) ──
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';
process.env.ADMIN_PIN = '1088';
process.env.SERVICE_KEY = 'test-service-key';
process.env.RAZORPAY_KEY_ID = 'rzp_test_key';
process.env.RAZORPAY_KEY_SECRET = 'test_key_secret';
process.env.RAZORPAY_WEBHOOK_SECRET = 'test_webhook_secret';

const { setPool, q } = await import('../src/db.js');
const razorpayFn = (await import('../functions/razorpay.js')).default;
const { handleRazorpayEvent } = await import('../functions/razorpay.js');
const nightlyFn = (await import('../functions/nightly.js')).default;
const { runNightly } = await import('../functions/nightly.js');

const here = path.dirname(fileURLToPath(import.meta.url));
const schema = fs.readFileSync(path.join(here, '../db/schema.sql'), 'utf8');

const db = newDb();
db.public.none(schema);
const pg = db.adapters.createPg();
setPool(new pg.Pool());

after(async () => {
  try { await pg.Pool.prototype.end?.call?.({}); } catch { /* ignore */ }
});

const sign = (body) =>
  crypto.createHmac('sha256', 'test_webhook_secret').update(body).digest('hex');

const webhookBody = (orderId = 'order_test1', paymentId = 'pay_test1') =>
  JSON.stringify({
    event: 'payment.captured',
    payload: { payment: { entity: { id: paymentId, order_id: orderId, amount: 110000, status: 'captured' } } },
  });

async function seedDonation(orderId = 'order_test1') {
  const rows = await q(
    `INSERT INTO donations (name, phone, category, amount, method, status, razorpay_order_id)
     VALUES ('रमेश शर्मा', '9876543210', 'जीर्णोद्धार', 1100, 'RAZORPAY', 'pending', $1) RETURNING id`,
    [orderId],
  );
  return rows[0].id;
}

/* ---------------- Razorpay webhook ---------------- */

test('वेबहुक: सही हस्ताक्षर → दान paid + रसीद + घोषणा', async () => {
  const donationId = await seedDonation('order_test1');
  const body = webhookBody('order_test1', 'pay_test1');

  const res = await handleRazorpayEvent(Buffer.from(body), sign(body));
  assert.equal(res.status, 200);
  assert.equal(res.body.status, 'paid');
  assert.match(res.body.receipt, /^80G\/\d{4}-\d{2}\/100[0-9]$/);

  const rows = await q('SELECT status, receipt_no, razorpay_payment_id FROM donations WHERE id = $1', [donationId]);
  assert.equal(rows[0].status, 'paid');
  assert.equal(rows[0].razorpay_payment_id, 'pay_test1');

  const ann = await q('SELECT text FROM announcements ORDER BY id DESC LIMIT 1');
  assert.match(ann[0].text, /रमेश शर्मा/);
  assert.match(ann[0].text, /₹1,100/);
});

test('वेबहुक: दोबारा वही event → already_paid, नई रसीद नहीं', async () => {
  const body = webhookBody('order_test1', 'pay_test1');
  const res = await handleRazorpayEvent(Buffer.from(body), sign(body));
  assert.equal(res.status, 200);
  assert.equal(res.body.status, 'already_paid');

  const rows = await q("SELECT COUNT(*)::int AS c FROM donations WHERE status = 'paid'");
  assert.equal(rows[0].c, 1);
});

test('वेबहुक: गलत हस्ताक्षर → 400, दान नहीं बदलता', async () => {
  const donationId = await seedDonation('order_test2');
  const body = webhookBody('order_test2', 'pay_test2');
  const res = await handleRazorpayEvent(Buffer.from(body), 'galat_signature');
  assert.equal(res.status, 400);

  const rows = await q('SELECT status FROM donations WHERE id = $1', [donationId]);
  assert.equal(rows[0].status, 'pending');
});

test('वेबहुक: अनजान order → 200 पर ignored (Razorpay को 200 चाहिए)', async () => {
  const body = webhookBody('order_unknown', 'pay_unknown');
  const res = await handleRazorpayEvent(Buffer.from(body), sign(body));
  assert.equal(res.status, 200);
  assert.equal(res.body.ignored, 'unknown_order');
});

test('वेबहुक: function का fetch handler भी वही करता है', async () => {
  await seedDonation('order_test3');
  const body = webhookBody('order_test3', 'pay_test3');
  const res = await razorpayFn.fetch(
    new Request('https://br-x-razorpay.compute.neon.tech/', {
      method: 'POST',
      headers: { 'x-razorpay-signature': sign(body), 'content-type': 'application/json' },
      body,
    }),
  );
  assert.equal(res.status, 200);
  const j = await res.json();
  assert.equal(j.status, 'paid');
});

test('वेबहुक: health जाँच', async () => {
  const res = await razorpayFn.fetch(new Request('https://br-x-razorpay.compute.neon.tech/health'));
  const j = await res.json();
  assert.equal(res.status, 200);
  assert.equal(j.ok, true);
  assert.equal(j.signatureCheck, true);
});

/* ---------------- nightly (schedule trigger) ---------------- */

test('nightly: कल का सारांश + सफ़ाई', async () => {
  const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  await q(
    `INSERT INTO donations (name, category, amount, method, status, paid_at, receipt_no)
     VALUES ('सुनीता देवी', 'अन्नदान', 11000, 'UPI_QR', 'paid', $1, '80G/2026-27/1050')`,
    [yesterday],
  );
  // पुराना अलर्ट (100 दिन पहले) — सफ़ाई में जाना चाहिए
  const old = new Date(Date.now() - 100 * 24 * 60 * 60 * 1000).toISOString();
  await q("INSERT INTO alerts (cam, label, created_at) VALUES ('03', 'पुराना अलर्ट', $1)", [old]);
  await q("INSERT INTO alerts (cam, label) VALUES ('03', 'नया अलर्ट')");

  const summary = await runNightly();
  assert.equal(summary.paid_count, 1);
  assert.equal(summary.paid_total, 11000);
  assert.equal(summary.big_donations, 1);
  assert.equal(summary.max_donation, 11000);
  assert.equal(summary.alerts_deleted, 1);

  const report = await q('SELECT * FROM daily_reports WHERE report_date = $1', [summary.date]);
  assert.equal(report.length, 1);
  assert.equal(report[0].paid_total, 11000);

  const alertsLeft = await q('SELECT COUNT(*)::int AS c FROM alerts');
  assert.equal(alertsLeft[0].c, 1);
});

test('nightly: दोबारा चलाने पर रिपोर्ट बदलती है, दो नहीं बनतीं', async () => {
  await runNightly();
  const rows = await q('SELECT COUNT(*)::int AS c FROM daily_reports');
  assert.equal(rows[0].c, 1);
});

test('nightly: बिना trigger delivery → 401', async () => {
  const res = await nightlyFn.fetch(
    new Request('https://br-x-nightly.compute.neon.tech/cron', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ version: 1, invocation_id: 'inv-1' }),
    }),
  );
  assert.equal(res.status, 401);
  const j = await res.json();
  assert.equal(j.reason, 'missing_header');
});

test('nightly: असली trigger delivery (header + body मेल) → 200', async () => {
  const invocationId = 'inv-test-123';
  const body = JSON.stringify({
    version: 1,
    invocation_id: invocationId,
    trigger: { type: 'schedule', id: 'trigger-abc', name: 'nightly-report' },
    data: { scheduled_at: new Date().toISOString() },
  });
  const res = await nightlyFn.fetch(
    new Request('https://br-x-nightly.compute.neon.tech/cron', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-neon-trigger-invocation-id': invocationId,
      },
      body,
    }),
  );
  assert.equal(res.status, 200);
  const j = await res.json();
  assert.equal(j.ok, true);
  assert.equal(j.trigger, 'nightly-report');
});

test('nightly: health', async () => {
  const res = await nightlyFn.fetch(new Request('https://br-x-nightly.compute.neon.tech/health'));
  const j = await res.json();
  assert.equal(res.status, 200);
  assert.equal(j.ok, true);
  assert.ok(j.lastReport);
});
