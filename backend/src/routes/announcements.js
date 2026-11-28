import { Router } from 'express';
import { z } from 'zod';
import { q } from '../db.js';
import { validate, asyncH } from '../middleware/validate.js';
import { requireAdmin, requireServiceKey } from '../middleware/auth.js';
import { announcementText } from '../services/receipts.js';

export const announcementsRouter = Router();

const createSchema = z.object({
  name: z.string().trim().min(2).max(80),
  amount: z.number().int().min(0).max(10_000_000).optional(),
  text: z.string().trim().min(5).max(400).optional(),
});

/** घोषणा कतार में डालें (एडमिन या मंदिर डिवाइस) */
announcementsRouter.post('/', requireAdmin, validate(createSchema), asyncH(async (req, res) => {
  const { name, amount = 0, text } = req.body;
  const body = text ?? announcementText(name, amount);
  const rows = await q(
    'INSERT INTO announcements (name, amount, text) VALUES ($1, $2, $3) RETURNING id, status, created_at',
    [name, amount, body],
  );
  res.status(201).json({ announcement: { ...rows[0], text: body } });
}));

/**
 * मंदिर का PA डिवाइस इस endpoint को हर 2 सेकंड पोल करे।
 * जो घोषणा लौटे उसे बजाकर POST /:id/played कर दे।
 */
announcementsRouter.get('/pending', requireServiceKey, asyncH(async (req, res) => {
  const rows = await q(
    `SELECT id, name, amount, text, created_at FROM announcements
      WHERE status = 'queued' ORDER BY created_at ASC LIMIT 1`,
  );
  if (rows.length === 0) return res.json({ announcement: null });
  const a = rows[0];
  await q("UPDATE announcements SET status = 'playing' WHERE id = $1", [a.id]);
  res.json({ announcement: a });
}));

/** डिवाइस ने बजा दिया */
announcementsRouter.post('/:id/played', requireServiceKey, asyncH(async (req, res) => {
  await q(
    "UPDATE announcements SET status = 'played', played_at = now() WHERE id = $1",
    [Number(req.params.id)],
  );
  res.json({ ok: true });
}));

/** अगर डिवाइस बजाने में नाकाम रहा — वापस कतार में */
announcementsRouter.post('/:id/retry', requireServiceKey, asyncH(async (req, res) => {
  await q("UPDATE announcements SET status = 'queued' WHERE id = $1", [Number(req.params.id)]);
  res.json({ ok: true });
}));

/** हाल की घोषणाएँ (एडमिन) */
announcementsRouter.get('/', requireAdmin, asyncH(async (req, res) => {
  const rows = await q('SELECT * FROM announcements ORDER BY created_at DESC LIMIT 50');
  res.json({ count: rows.length, announcements: rows });
}));
