import { Router } from 'express';
import { z } from 'zod';
import { q } from '../db.js';
import { validate, asyncH } from '../middleware/validate.js';
import { requireAdmin, requireServiceKey } from '../middleware/auth.js';

export const alertsRouter = Router();

const alertSchema = z.object({
  cam: z.string().min(1).max(20),
  label: z.string().min(2).max(80),
  confidence: z.number().int().min(0).max(100).optional(),
  photo_url: z.string().url().optional().or(z.literal('')),
  clip_url: z.string().url().optional().or(z.literal('')),
});

/** YOLOv8 सर्विस घटना भेजे (x-service-key) */
alertsRouter.post('/', requireServiceKey, validate(alertSchema), asyncH(async (req, res) => {
  const { cam, label, confidence = 90, photo_url = '', clip_url = '' } = req.body;
  const rows = await q(
    'INSERT INTO alerts (cam, label, confidence, photo_url, clip_url) VALUES ($1, $2, $3, $4, $5) RETURNING *',
    [cam, label, confidence, photo_url, clip_url],
  );
  res.status(201).json({ alert: rows[0] });
}));

alertsRouter.get('/', requireAdmin, asyncH(async (req, res) => {
  const limit = Math.min(Number(req.query.limit ?? 50), 200);
  const rows = await q('SELECT * FROM alerts ORDER BY created_at DESC LIMIT $1', [limit]);
  res.json({ count: rows.length, alerts: rows });
}));
