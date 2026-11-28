import crypto from 'node:crypto';
import { config } from '../config.js';

const API = 'https://api.razorpay.com/v1';

/** रज़ोरपे ऑर्डर बनाएँ (amount पैसे में) */
export async function createOrder({ amountRupees, receipt, notes = {} }) {
  if (!config.razorpay.enabled) {
    // डेमो मोड — keys नहीं हैं तो नकली ऑर्डर
    return { id: `order_demo_${Date.now()}`, amount: amountRupees * 100, currency: 'INR', demo: true };
  }
  const auth = Buffer.from(`${config.razorpay.keyId}:${config.razorpay.keySecret}`).toString('base64');
  const res = await fetch(`${API}/orders`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Basic ${auth}` },
    body: JSON.stringify({
      amount: amountRupees * 100,
      currency: 'INR',
      receipt,
      notes,
      payment_capture: 1,
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw Object.assign(new Error(`Razorpay order failed: ${res.status} ${text}`), { status: 502 });
  }
  return res.json();
}

/** भुगतान की जाँच — order_id|payment_id का HMAC */
export function verifyPaymentSignature({ orderId, paymentId, signature }) {
  if (!config.razorpay.enabled) return true; // डेमो मोड
  if (!orderId || !paymentId || !signature) return false;
  const expected = crypto
    .createHmac('sha256', config.razorpay.keySecret)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');
  return timingSafeEqual(expected, signature);
}

/** वेबहुक हस्ताक्षर — raw body पर HMAC */
export function verifyWebhookSignature({ rawBody, signature }) {
  if (!config.razorpay.webhookSecret) return true;
  if (!signature) return false;
  const expected = crypto
    .createHmac('sha256', config.razorpay.webhookSecret)
    .update(rawBody)
    .digest('hex');
  return timingSafeEqual(expected, signature);
}

function timingSafeEqual(a, b) {
  const ba = Buffer.from(String(a));
  const bb = Buffer.from(String(b));
  if (ba.length !== bb.length) return false;
  return crypto.timingSafeEqual(ba, bb);
}
