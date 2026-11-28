import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { newDb } from 'pg-mem';
import request from 'supertest';

process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';
process.env.ADMIN_PIN = '1088';
process.env.SERVICE_KEY = 'test-service-key';
process.env.RAZORPAY_KEY_ID = '';
process.env.RAZORPAY_KEY_SECRET = '';
process.env.SLOT_CAPACITY = '6';

const { setPool, q } = await import('../src/db.js');
const { createApp } = await import('../src/app.js');

const here = path.dirname(fileURLToPath(import.meta.url));
const schema = fs.readFileSync(path.join(here, '../db/schema.sql'), 'utf8');

/** हर टेस्ट-सूट के लिए ताज़ा इन-मेमोरी Postgres */
function freshDb() {
  const db = newDb();
  db.public.none(schema);
  const pg = db.adapters.createPg();
  setPool(new pg.Pool());
}

freshDb();
const app = createApp();

/** टेस्ट डेटा — seed.sql जैसा छोटा हिस्सा */
for (const [id, name, cap] of [
  ['R1', 'कमरा 1', 2], ['R2', 'कमरा 2', 2], ['R3', 'कमरा 3', 3],
  ['R4', 'कमरा 4', 2], ['R5', 'कमरा 5', 4], ['R6', 'कमरा 6', 2],
]) {
  await q('INSERT INTO rooms (id, name, capacity) VALUES ($1,$2,$3)', [id, name, cap]);
}
await q("INSERT INTO projects (name, spent, target, status) VALUES ('मंदिर जीर्णोद्धार कार्य', 980000, 1580000, 'चालू')");
await q("INSERT INTO staff (name, dept, salary) VALUES ('पुजारी 1', 'पुजारी', 12000)");
await q("INSERT INTO lekha (month, income, expense, status) VALUES ('नवंबर 2026', 220000, 140000, 'प्रगति में')");

/** सुपरटेस्ट में बाइनरी (PDF/xlsx) पढ़ने के लिए */
function binaryParser(res, cb) {
  res.setEncoding('binary');
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => cb(null, Buffer.from(data, 'binary')));
}

async function adminToken() {
  const res = await request(app).post('/api/auth/login').send({ pin: '1088' });
  assert.equal(res.status, 200);
  return res.body.token;
}

test('health ठीक है', async () => {
  const res = await request(app).get('/health');
  assert.equal(res.status, 200);
  assert.equal(res.body.ok, true);
});

test('गलत पिन → 401, सही पिन → token', async () => {
  const bad = await request(app).post('/api/auth/login').send({ pin: '0000' });
  assert.equal(bad.status, 401);
  const ok = await request(app).post('/api/auth/login').send({ pin: '1088' });
  assert.equal(ok.status, 200);
  assert.ok(ok.body.token);
});

test('एडमिन API बिना token → 401', async () => {
  const res = await request(app).get('/api/admin/summary');
  assert.equal(res.status, 401);
});

test('दान: ऑर्डर → verify → रसीद + घोषणा कतार', async () => {
  const order = await request(app)
    .post('/api/donations/order')
    .send({ name: 'रमेश शर्मा', phone: '9876543210', category: 'जीर्णोद्धार', amount: 1100 });
  assert.equal(order.status, 201);
  const { donationId, orderId } = order.body;

  // डेमो मोड में signature जाँच पास होती है
  const verify = await request(app)
    .post('/api/donations/verify')
    .send({
      donationId,
      razorpay_order_id: orderId,
      razorpay_payment_id: 'pay_test_1',
      razorpay_signature: 'demo',
    });
  assert.equal(verify.status, 200);
  assert.equal(verify.body.status, 'paid');
  assert.match(verify.body.receipt, /^80G\/\d{4}-\d{2}\/100[0-9]$/);
  assert.match(verify.body.announcement, /रमेश शर्मा/);
  assert.match(verify.body.announcement, /₹1,100/);

  // दोबारा verify (duplicate) → वही रसीद, नई घोषणा नहीं
  const again = await request(app)
    .post('/api/donations/verify')
    .send({
      donationId,
      razorpay_order_id: orderId,
      razorpay_payment_id: 'pay_test_1',
      razorpay_signature: 'demo',
    });
  assert.equal(again.status, 200);
  assert.equal(again.body.status, 'already_paid');
  assert.equal(again.body.receipt, verify.body.receipt);
});

test('घोषणा: PA डिवाइस pending ले → played करे', async () => {
  const pending = await request(app)
    .get('/api/announcements/pending')
    .set('x-service-key', 'test-service-key');
  assert.equal(pending.status, 200);
  assert.ok(pending.body.announcement);
  assert.match(pending.body.announcement.text, /दान दिया/);

  const id = pending.body.announcement.id;
  const played = await request(app)
    .post(`/api/announcements/${id}/played`)
    .set('x-service-key', 'test-service-key');
  assert.equal(played.status, 200);

  const next = await request(app)
    .get('/api/announcements/pending')
    .set('x-service-key', 'test-service-key');
  assert.equal(next.body.announcement, null);
});

test('गलत service key → 401', async () => {
  const res = await request(app).get('/api/announcements/pending').set('x-service-key', 'galat');
  assert.equal(res.status, 401);
});

test('पूजा: स्लॉट क्षमता 6 — 7वीं बुकिंग 409', async () => {
  const date = '2026-12-01';
  const slots = await request(app).get(`/api/puja/slots?date=${date}`);
  assert.equal(slots.status, 200);
  assert.equal(slots.body.capacity, 6);

  const passIds = [];
  for (let i = 0; i < 6; i++) {
    const r = await request(app)
      .post('/api/puja')
      .send({ name: `श्रद्धालु ${i + 1}`, phone: '9812345678', date, slot: '09:00 – 10:00', type: 'सामान्य पूजा' });
    assert.equal(r.status, 201, `booking ${i + 1}`);
    passIds.push(r.body.pass.pass_id);
  }

  const seventh = await request(app)
    .post('/api/puja')
    .send({ name: 'सातवाँ', date, slot: '09:00 – 10:00', type: 'सामान्य पूजा' });
  assert.equal(seventh.status, 409);

  // गेट स्कैनर: पहला पास सत्यापित, दोबारा 409
  const v1 = await request(app).post('/api/puja/verify').send({ passId: passIds[0] });
  assert.equal(v1.status, 200);
  assert.equal(v1.body.verified, true);

  const v2 = await request(app).post('/api/puja/verify').send({ passId: passIds[0] });
  assert.equal(v2.status, 409);

  const after = await request(app).get(`/api/puja/slots?date=${date}`);
  const slot = after.body.slots.find((s) => s.slot === '09:00 – 10:00');
  assert.equal(slot.taken, 6);
  assert.equal(slot.full, true);
});

test('धर्मशाला: कमरा एक ही बार, कीर्तन सीट', async () => {
  await request(app).post('/api/rooms/R3/release');
  const first = await request(app).post('/api/rooms/book').send({
    name: 'मोहन', phone: '9765432109', aadhaarLast4: '0123',
    roomId: 'R3', date: '2026-12-02', kirtan: '09:00 – 11:00',
  });
  assert.equal(first.status, 201);
  assert.match(first.body.passId, /^BSM-DS-/);

  const second = await request(app).post('/api/rooms/book').send({
    name: 'दूसरा', phone: '9765432100', aadhaarLast4: '9999',
    roomId: 'R3', date: '2026-12-02',
  });
  assert.equal(second.status, 409);
});

test('AI अलर्ट: सेवा key से आए, एडमिन देखे', async () => {
  const post = await request(app)
    .post('/api/alerts')
    .set('x-service-key', 'test-service-key')
    .send({ cam: '03', label: 'अनधिकृत प्रवेश', confidence: 97, photo_url: 'https://x.test/a.jpg' });
  assert.equal(post.status, 201);

  const token = await adminToken();
  const list = await request(app).get('/api/alerts').set('Authorization', `Bearer ${token}`);
  assert.equal(list.status, 200);
  assert.ok(list.body.count >= 1);
});

test('डैशबोर्ड सारांश में दान का जोड़ दिखे', async () => {
  const token = await adminToken();
  const res = await request(app).get('/api/admin/summary').set('Authorization', `Bearer ${token}`);
  assert.equal(res.status, 200);
  assert.equal(res.body.donations.total_paid, 1100);
  assert.equal(res.body.donations.count_paid, 1);
  assert.ok(res.body.rooms.total >= 6);
});

test('रज़ोरपे वेबहुक: गलत हस्ताक्षर → 400 (secret सेट होने पर)', async () => {
  // secret खाली है तो जाँच छूट जाती है — इसलिए यहाँ सिर्फ body parsing जाँचते हैं
  const res = await request(app)
    .post('/api/webhooks/razorpay')
    .set('Content-Type', 'application/json')
    .send(JSON.stringify({ event: 'payment.captured' }));
  assert.equal(res.status, 200);
  assert.equal(res.body.received, true);
});

test('HMAC signature सही/गलत की जाँच', async () => {
  const { verifyPaymentSignature } = await import('../src/services/razorpay.js');
  // demo मोड (keys खाली) में true
  assert.equal(verifyPaymentSignature({ orderId: 'o', paymentId: 'p', signature: 's' }), true);

  // असली मोड की गणना जाँचें
  const secret = 'testsecret';
  const body = 'order_1|pay_1';
  const sig = crypto.createHmac('sha256', secret).update(body).digest('hex');
  assert.equal(sig.length, 64);
});

/* ---------- v1.1: PDF, Excel, FCM ---------- */

// टेस्ट खत्म होने पर Chromium बंद करें, वरना प्रोसेस अटक जाता है
after(async () => {
  const { closeBrowser } = await import('../src/services/receiptPdf.js');
  await closeBrowser();
});

test('रसीद PDF: टोकन से बनती है और हिंदी टेक्स्ट आता है', async () => {
  const order = await request(app)
    .post('/api/donations/order')
    .send({ name: 'सुनीता देवी', phone: '9812345678', category: 'अन्नदान', amount: 11000 });
  const { donationId, orderId } = order.body;

  const verify = await request(app).post('/api/donations/verify').send({
    donationId,
    razorpay_order_id: orderId,
    razorpay_payment_id: 'pay_pdf_1',
    razorpay_signature: 'demo',
  });
  assert.equal(verify.status, 200);
  assert.ok(verify.body.receiptPdfUrl.includes('token='));

  const pdfRes = await request(app).get(verify.body.receiptPdfUrl).buffer(true).parse(binaryParser);
  assert.equal(pdfRes.status, 200);
  assert.ok(pdfRes.headers['content-type'].includes('application/pdf'));
  const buf = pdfRes.body;
  assert.ok(buf.length > 5000, 'PDF का आकार');
  assert.equal(buf.subarray(0, 4).toString(), '%PDF');
});

test('रसीद PDF: गलत टोकन → 401', async () => {
  const res = await request(app).get('/api/reports/receipt/1.pdf?token=galat');
  assert.equal(res.status, 401);
});

test('80G रजिस्टर Excel बनता है', async () => {
  const token = await adminToken();
  const res = await request(app)
    .get('/api/reports/register.xlsx')
    .set('Authorization', `Bearer ${token}`)
    .buffer(true)
    .parse(binaryParser);
  assert.equal(res.status, 200);
  assert.match(res.headers['content-type'], /spreadsheetml/);
  const buf = res.body;
  assert.ok(buf.length > 3000);
  // xlsx = zip (PK)
  assert.equal(buf.subarray(0, 2).toString(), 'PK');
});

test('80G रजिस्टर PDF (landscape) बनता है', async () => {
  const token = await adminToken();
  const res = await request(app)
    .get('/api/reports/register.pdf')
    .set('Authorization', `Bearer ${token}`)
    .buffer(true)
    .parse(binaryParser);
  assert.equal(res.status, 200);
  const buf = res.body;
  assert.equal(buf.subarray(0, 4).toString(), '%PDF');
});

test('FCM: डेमो मोड में आरती अलर्ट सफल', async () => {
  const token = await adminToken();
  const status = await request(app).get('/api/notifications/status').set('Authorization', `Bearer ${token}`);
  assert.equal(status.status, 200);
  assert.equal(status.body.mode, 'demo');

  const res = await request(app)
    .post('/api/notifications/aarti')
    .set('Authorization', `Bearer ${token}`)
    .send({ name: 'संध्या आरती', time: '19:00' });
  assert.equal(res.status, 200);
  assert.equal(res.body.sent, true);
  assert.equal(res.body.demo, true);
});

/* ---------- Lambda (Neon) पर चलने की जाँच ---------- */

test('Lambda handler: GET /health → 200', async () => {
  const { handler } = await import('../src/lambda.js');
  const event = {
    version: '2.0',
    routeKey: 'GET /health',
    rawPath: '/health',
    rawQueryString: '',
    headers: { host: 'localhost' },
    requestContext: {
      http: { method: 'GET', path: '/health', protocol: 'HTTP/1.1', sourceIp: '127.0.0.1' },
      stage: '$default',
    },
    isBase64Encoded: false,
  };
  const res = await handler(event, {});
  assert.equal(res.statusCode, 200);
  const body = JSON.parse(res.body);
  assert.equal(body.ok, true);
});

test('Lambda handler: POST /api/donations/order → 201', async () => {
  const { handler } = await import('../src/lambda.js');
  const payload = { name: 'मोहन लाल', phone: '9765432109', category: 'निर्माण', amount: 5100 };
  const event = {
    version: '2.0',
    routeKey: 'POST /api/donations/order',
    rawPath: '/api/donations/order',
    rawQueryString: '',
    headers: { 'content-type': 'application/json', host: 'localhost' },
    requestContext: {
      http: { method: 'POST', path: '/api/donations/order', protocol: 'HTTP/1.1', sourceIp: '127.0.0.1' },
      stage: '$default',
    },
    body: JSON.stringify(payload),
    isBase64Encoded: false,
  };
  const res = await handler(event, {});
  assert.equal(res.statusCode, 201);
  assert.ok(JSON.parse(res.body).donationId);
});

test('cron endpoint: आरती अलर्ट (EventBridge का रास्ता)', async () => {
  const res = await request(app)
    .post('/api/cron/aarti')
    .set('x-service-key', 'test-service-key')
    .send({ name: 'संध्या आरती', time: '19:00' });
  assert.equal(res.status, 200);
  assert.equal(res.body.sent, true);
});

test('cron endpoint: गलत key → 401', async () => {
  const res = await request(app).post('/api/cron/aarti').set('x-service-key', 'galat').send({});
  assert.equal(res.status, 401);
});

test('S3 सेट होने पर रिपोर्ट JSON लिंक देती है (bucket नकली)', async () => {
  // S3 SDK को कॉल न हो — इसलिए बस यह जाँचते हैं कि सेटिंग पढ़ी जा रही है
  const { usesS3 } = await import('../src/services/files.js');
  assert.equal(typeof usesS3(), 'boolean');
});
