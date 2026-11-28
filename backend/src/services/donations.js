import crypto from 'node:crypto';
import { tx } from '../db.js';
import { nextReceiptNo, announcementText } from './receipts.js';

/** रसीद के सार्वजनिक लिंक का टोकन */
export function newReceiptToken() {
  return crypto.randomBytes(16).toString('hex');
}

/**
 * भुगतान दर्ज करें — idempotent (वेबहुक दो बार आए तो भी एक ही रसीद)।
 * API (routes/donations.js) और Razorpay वेबहुक function — दोनों यही इस्तेमाल करते हैं।
 */
export async function markPaid({ donationId, orderId, paymentId, utr }) {
  return tx(async (client) => {
    const cur = await client.query('SELECT * FROM donations WHERE id = $1', [donationId]);
    const donation = cur.rows[0];
    if (!donation) throw Object.assign(new Error('दान नहीं मिला'), { status: 404 });

    if (donation.status === 'paid') {
      return { status: 'already_paid', receipt: donation.receipt_no, donationId };
    }

    const receiptNo = await nextReceiptNo(client);
    const receiptToken = newReceiptToken();

    await client.query(
      `UPDATE donations
          SET status = 'paid', paid_at = now(), receipt_no = $2,
              razorpay_payment_id = COALESCE(razorpay_payment_id, $3),
              razorpay_order_id  = COALESCE(razorpay_order_id, $4),
              utr = COALESCE($5, utr),
              receipt_token = COALESCE(receipt_token, $6)
        WHERE id = $1`,
      [donationId, receiptNo, paymentId ?? null, orderId ?? null, utr ?? null, receiptToken],
    );

    await client.query(
      'INSERT INTO announcements (name, amount, text) VALUES ($1, $2, $3)',
      [donation.name, donation.amount, announcementText(donation.name, donation.amount)],
    );
    await client.query('UPDATE donations SET announced = TRUE WHERE id = $1', [donationId]);
    await client.query(
      'INSERT INTO audit_log (actor, action, payload) VALUES ($1, $2, $3)',
      ['system', 'donation_paid', JSON.stringify({ donationId, receiptNo })],
    );

    return {
      status: 'paid',
      donationId,
      receipt: receiptNo,
      receiptPdfUrl: `/api/reports/receipt/${donationId}.pdf?token=${receiptToken}`,
      name: donation.name,
      amount: donation.amount,
      announcement: announcementText(donation.name, donation.amount),
    };
  });
}

/** order id से दान खोजें (वेबहुक के लिए) */
export async function donationIdByOrder(orderId) {
  const { q } = await import('../db.js');
  const rows = await q('SELECT id FROM donations WHERE razorpay_order_id = $1', [orderId]);
  return rows[0]?.id ?? null;
}
