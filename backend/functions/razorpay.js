/**
 * Neon Function — `razorpay` : भुगतान वेबहुक
 *
 * Razorpay का सर्वर यहाँ POST करता है (`payment.captured` / `order.paid`)।
 * हस्ताक्षर जाँचने के बाद दान `paid` होता है, रसीद नंबर बनता है और घोषणा
 * कतार में चली जाती है — भले ऐप बंद हो या फ़ोन का नेट गया हो।
 *
 *  GET  /health → जाँच
 *  POST /       → वेबहुक (HMAC जाँच के साथ)
 *
 * ⚠️ इस रास्ते पर JWT/सेशन नहीं — पहचान सिर्फ़ हस्ताक्षर से होती है।
 */
import { verifyWebhookSignature } from '../src/services/razorpay.js';
import { markPaid, donationIdByOrder } from '../src/services/donations.js';
import { config } from '../src/config.js';

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });

/**
 * वेबहुक की असली प्रक्रिया — raw body + signature से।
 * (टेस्ट में सीधे यही बुलाया जाता है)
 */
export async function handleRazorpayEvent(rawBody, signature) {
  if (!config.razorpay.webhookSecret && !signature) {
    return { status: 400, body: { error: 'वेबहुक secret सेट नहीं है' } };
  }
  if (!verifyWebhookSignature({ rawBody, signature })) {
    return { status: 400, body: { error: 'वेबहुक हस्ताक्षर गलत' } };
  }

  let event;
  try {
    event = JSON.parse(rawBody.toString('utf8'));
  } catch {
    return { status: 400, body: { error: 'गलत JSON' } };
  }

  const type = event?.event ?? '';
  if (type !== 'payment.captured' && type !== 'order.paid') {
    // बाकी घटनाएँ चुपचाप स्वीकार (Razorpay को 200 चाहिए)
    return { status: 200, body: { received: true, ignored: type } };
  }

  const payment = event?.payload?.payment?.entity ?? {};
  const orderId = payment.order_id;
  const paymentId = payment.id;

  if (!orderId) return { status: 200, body: { received: true, ignored: 'no_order_id' } };

  const donationId = await donationIdByOrder(orderId);
  if (!donationId) return { status: 200, body: { received: true, ignored: 'unknown_order' } };

  const result = await markPaid({ donationId, orderId, paymentId });
  return { status: 200, body: { received: true, ...result } };
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, '') || '/';

    if (request.method === 'GET' && (path === '/health' || path === '/')) {
      return json({
        ok: true,
        function: 'razorpay-webhook',
        branch: process.env.NEON_BRANCH ?? null,
        signatureCheck: Boolean(config.razorpay.webhookSecret),
      });
    }

    if (request.method === 'POST') {
      const raw = Buffer.from(await request.arrayBuffer());
      const signature = request.headers.get('x-razorpay-signature') ?? '';
      const { status, body } = await handleRazorpayEvent(raw, signature);
      return json(body, status);
    }

    return json({ error: 'रास्ता नहीं मिला' }, 404);
  },
};
