import crypto from 'node:crypto';
import fs from 'node:fs';
import { config } from '../config.js';

/**
 * Firebase Cloud Messaging (HTTP v1) — बिना भारी SDK, सिर्फ़ node crypto से।
 *
 * .env में:
 *   FIREBASE_SERVICE_ACCOUNT=/path/service-account.json   (या base64 स्ट्रिंग)
 *   FCM_TOPIC=aarti_alerts
 *
 * keys न हों तो "डेमो मोड" — मैसेज लॉग होकर सफल मान लिया जाता है,
 * ताकि बाकी सिस्टम न रुके।
 */

let cachedToken = null; // { token, exp }

function serviceAccount() {
  const raw = config.firebaseServiceAccount;
  if (!raw) return null;
  try {
    if (raw.trim().startsWith('{')) return JSON.parse(raw);
    const text = fs.existsSync(raw)
      ? fs.readFileSync(raw, 'utf8')
      : Buffer.from(raw, 'base64').toString('utf8');
    return JSON.parse(text);
  } catch (e) {
    console.warn('FCM: service account पढ़ा नहीं गया —', e.message);
    return null;
  }
}

const b64url = (buf) =>
  Buffer.from(buf).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

/** Google OAuth2 access token (JWT → token endpoint) */
async function accessToken(sa) {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp - 60 > now) return cachedToken.token;

  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }));
  const signer = crypto.createSign('RSA-SHA256');
  signer.update(`${header}.${claim}`);
  const signature = b64url(signer.sign(sa.private_key));
  const jwt = `${header}.${claim}.${signature}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new Error(`FCM token failed: ${res.status} ${await res.text()}`);
  const data = await res.json();
  cachedToken = { token: data.access_token, exp: now + (data.expires_in ?? 3600) };
  return cachedToken.token;
}

/**
 * टॉपिक पर नोटिफिकेशन भेजें
 * @returns {{ok: boolean, demo?: boolean, id?: string, error?: string}}
 */
export async function sendToTopic({ title, body, topic = config.fcmTopic, data = {} }) {
  const sa = serviceAccount();
  if (!sa) {
    console.log(`[FCM डेमो] ${topic} → ${title}: ${body}`);
    return { ok: true, demo: true };
  }
  try {
    const token = await accessToken(sa);
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: {
            topic,
            notification: { title, body },
            data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
            android: {
              priority: 'high',
              notification: { channel_id: 'aarti_alerts', color: '#B34700', sound: 'default' },
            },
          },
        }),
      },
    );
    if (!res.ok) return { ok: false, error: `${res.status} ${await res.text()}` };
    const json = await res.json();
    return { ok: true, id: json.name };
  } catch (e) {
    return { ok: false, error: e.message };
  }
}

/** आरती अलर्ट */
export async function sendAartiAlert({ name, time }) {
  return sendToTopic({
    title: `${name} — बाबा सिद्धनाथ मंदिर`,
    body: `${time} बजे ${name} होने वाली है। 24x7 लाइव दर्शन ऐप में देखें। जय बाबा सिद्धनाथ!`,
    data: { type: 'aarti', name, time },
  });
}

export function isConfigured() {
  return serviceAccount() !== null;
}

/**
 * रोज़ की आरती के लिए स्वचालित शेड्यूलर (AARTI_TIMES=06:30,12:00,19:00)
 * सर्वर चालू रहने पर हर मिनट जाँचता है।
 */
export function startAartiScheduler(names = { '06:30': 'मंगला आरती', '12:00': 'भोग आरती', '19:00': 'संध्या आरती' }) {
  if (config.aartiTimes.length === 0) return null;
  let lastFired = '';
  const timer = setInterval(async () => {
    const now = new Date();
    const hhmm = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
    if (!config.aartiTimes.includes(hhmm)) return;
    const key = `${now.toDateString()} ${hhmm}`;
    if (lastFired === key) return;
    lastFired = key;
    const name = names[hhmm] ?? 'आरती';
    const result = await sendAartiAlert({ name, time: hhmm });
    console.log(`[आरती अलर्ट] ${hhmm} ${name} →`, result.ok ? 'भेजा' : result.error);
  }, 60_000);
  timer.unref?.();
  return timer;
}
