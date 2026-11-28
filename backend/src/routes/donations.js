import { Router } from 'express';
import { z } from 'zod';
import { q, tx } from '../db.js';
import { validate, asyncH } from '../middleware/validate.js';
import { requireAdmin } from '../middleware/auth.js';
import { createOrder, verifyPaymentSignature, verifyWebhookSignature } from '../services/razorpay.js';
import { markPaid } from '../services/donations.js';

export const donationsRouter = Router();

const orderSchema = z.object({
  name: z.string().trim().min(2).max(80),
  phone: z.string().trim().regex(/^[6-9]\d{9}$/).optional().or(z.literal('')),
  category: z.string().trim().min(2).max(40),
  amount: z.number().int().min(11).max(10_000_000),
});

/** 1) ऑर्डर बनाएँ — रज़ोरपे order id के साथ */
donationsRouter.post('/order', validate(orderSchema), asyncH(async (req, res) => {
  const { name, phone = '', category, amount } = req.body;

  const rows = await q(
    `INSERT INTO donations (name, phone, category, amount, method, status)
     VALUES ($1, $2, $3, $4, 'RAZORPAY', 'pending') RETURNING id`,
    [name, phone, category, amount],
  );
  const donationId = rows[0].id;

  const order = await createOrder({
    amountRupees: amount,
    receipt: `bsm-${donationId}`,
    notes: { donationId: String(donationId), category },
  });

  await q('UPDATE donations SET razorpay_order_id = $1 WHERE id = $2', [order.id, donationId]);

  res.status(201).json({
    donationId,
    orderId: order.id,
    amount,
    amountPaise: amount * 100,
    currency: 'INR',
    keyId: process.env.RAZORPAY_KEY_ID ?? '',
    demo: Boolean(order.demo),
  });
}));

const verifySchema = z.object({
  donationId: z.number().int().positive(),
  razorpay_order_id: z.string().min(3),
  razorpay_payment_id: z.string().min(3),
  razorpay_signature: z.string().min(3),
});

/** 2) भुगतान जाँच — signature सही हो तभी रसीद */
donationsRouter.post('/verify', validate(verifySchema), asyncH(async (req, res) => {
  const { donationId, razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

  if (!verifyPaymentSignature({
    orderId: razorpay_order_id,
    paymentId: razorpay_payment_id,
    signature: razorpay_signature,
  })) {
    return res.status(400).json({ error: 'भुगतान हस्ताक्षर गलत है' });
  }

  const result = await markPaid({
    donationId,
    orderId: razorpay_order_id,
    paymentId: razorpay_payment_id,
  });

  res.json(result);
}));

const manualSchema = z.object({
  name: z.string().trim().min(2).max(80),
  phone: z.string().trim().max(15).optional().or(z.literal('')),
  category: z.string().trim().min(2).max(40),
  amount: z.number().int().min(11).max(10_000_000),
  method: z.enum(['UPI_QR', 'BANK', 'CASH']),
  utr: z.string().trim().max(40).optional().or(z.literal('')),
});

/** QR / बैंक से आया दान — सत्यापन लंबित */
donationsRouter.post('/manual', validate(manualSchema), asyncH(async (req, res) => {
  const { name, phone = '', category, amount, method, utr = '' } = req.body;
  const rows = await q(
    `INSERT INTO donations (name, phone, category, amount, method, status, utr)
     VALUES ($1, $2, $3, $4, $5, 'pending_verification', $6) RETURNING id`,
    [name, phone, category, amount, method, utr],
  );
  res.status(201).json({
    donationId: rows[0].id,
    status: 'pending_verification',
    message: 'UTR के साथ दर्ज — कार्यालय सत्यापन के बाद रसीद जारी होगी',
  });
}));

/** सत्यापन लंबित दान को स्वीकृत करें (एडमिन) */
donationsRouter.post('/:id/approve', requireAdmin, asyncH(async (req, res) => {
  const id = Number(req.params.id);
  const result = await markPaid({ donationId: id, utr: req.body?.utr });
  res.json(result);
}));

donationsRouter.get('/', requireAdmin, asyncH(async (req, res) => {
  const limit = Math.min(Number(req.query.limit ?? 50), 200);
  const status = req.query.status;
  const rows = status
    ? await q('SELECT * FROM donations WHERE status = $1 ORDER BY created_at DESC LIMIT $2', [status, limit])
    : await q('SELECT * FROM donations ORDER BY created_at DESC LIMIT $1', [limit]);
  res.json({ count: rows.length, donations: rows });
}));

/** रज़ोरपे वेबहुक — raw body (server.js में express.raw) */
export async function razorpayWebhook(req, res) {
  const signature = req.headers['x-razorpay-signature'];
  const raw = req.body; // Buffer

  if (!verifyWebhookSignature({ rawBody: raw, signature })) {
    return res.status(400).json({ error: 'वेबहुक हस्ताक्षर गलत' });
  }

  let event;
  try { event = JSON.parse(raw.toString('utf8')); } catch { return res.status(400).json({ error: 'गलत JSON' }); }

  if (event.event === 'payment.captured' || event.event === 'order.paid') {
    const payment = event.payload?.payment?.entity;
    const orderId = payment?.order_id;
    const paymentId = payment?.id;
    if (orderId) {
      const rows = await q('SELECT id FROM donations WHERE razorpay_order_id = $1', [orderId]);
      if (rows[0]) {
        await markPaid({ donationId: rows[0].id, orderId, paymentId });
      }
    }
  }
  res.json({ received: true });
}

export { markPaid };
