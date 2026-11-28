import { Router } from 'express';
import { q } from '../db.js';
import { asyncH } from '../middleware/validate.js';
import { requireAdmin } from '../middleware/auth.js';
import { foundation } from '../services/foundation.js';
import { htmlToPdf, receiptHtml, registerHtml } from '../services/receiptPdf.js';
import { donationsXlsx, lekhaXlsx } from '../services/reports.js';
import { sendFile } from '../services/files.js';

export const reportsRouter = Router();

const today = () => new Date().toISOString().slice(0, 10);
const firstOfMonth = () => today().slice(0, 8) + '01';

function range(req) {
  return { from: String(req.query.from ?? firstOfMonth()), to: String(req.query.to ?? today()) };
}

async function paidBetween(from, to) {
  return q(
    `SELECT * FROM donations
      WHERE status = 'paid' AND COALESCE(paid_at, created_at)::date BETWEEN $1::date AND $2::date
      ORDER BY COALESCE(paid_at, created_at) ASC`,
    [from, to],
  );
}

/* ---------- 1) रसीद PDF ---------- */

export { newReceiptToken } from '../services/donations.js';

/**
 * GET /api/reports/receipt/:id.pdf
 * एडमिन JWT या ?token=<receipt_token>
 */
reportsRouter.get('/receipt/:id.pdf', asyncH(async (req, res) => {
  const id = Number(req.params.id);
  const rows = await q('SELECT * FROM donations WHERE id = $1', [id]);
  const d = rows[0];
  if (!d) return res.status(404).json({ error: 'दान नहीं मिला' });

  const token = String(req.query.token ?? '');
  if (token !== (d.receipt_token ?? '')) {
    // टोकन नहीं है तो एडमिन जाँच
    return requireAdmin(req, res, async () => sendReceipt(res, d));
  }
  return sendReceipt(res, d);
}));

async function sendReceipt(res, d) {
  if (d.status !== 'paid') {
    return res.status(409).json({ error: 'रसीद अभी जारी नहीं हुई (भुगतान लंबित)' });
  }
  const pdf = await htmlToPdf(receiptHtml(d, { foundation }));
  return sendFile(res, {
    buffer: pdf,
    filename: `rasid-${(d.receipt_no ?? 'x').replaceAll('/', '-')}.pdf`,
    contentType: 'application/pdf',
  });
}

/* ---------- 2) 80G रजिस्टर ---------- */

/** GET /api/reports/register.xlsx?from=&to= */
reportsRouter.get('/register.xlsx', requireAdmin, asyncH(async (req, res) => {
  const { from, to } = range(req);
  const rows = await paidBetween(from, to);
  const buf = await donationsXlsx(rows, { from, to });
  return sendFile(res, {
    buffer: buf,
    filename: `80g-register-${from}-to-${to}.xlsx`,
    contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  });
}));

/** GET /api/reports/register.pdf?from=&to= */
reportsRouter.get('/register.pdf', requireAdmin, asyncH(async (req, res) => {
  const { from, to } = range(req);
  const rows = await paidBetween(from, to);
  const total = rows.reduce((s, r) => s + Number(r.amount), 0);
  const pdf = await htmlToPdf(registerHtml(rows, { from, to, foundation, total }), { landscape: true });
  return sendFile(res, {
    buffer: pdf,
    filename: `80g-register-${from}-to-${to}.pdf`,
    contentType: 'application/pdf',
  });
}));

/** GET /api/reports/lekha.xlsx */
reportsRouter.get('/lekha.xlsx', requireAdmin, asyncH(async (_req, res) => {
  const rows = await q('SELECT * FROM lekha ORDER BY id');
  const buf = await lekhaXlsx(rows);
  return sendFile(res, {
    buffer: buf,
    filename: 'lekha.xlsx',
    contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  });
}));
