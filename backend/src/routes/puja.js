import { Router } from 'express';
import { z } from 'zod';
import { q } from '../db.js';
import { config } from '../config.js';
import { validate, asyncH } from '../middleware/validate.js';

export const pujaRouter = Router();

export const PUJA_SLOTS = [
  '05:30 – 06:30', '07:00 – 08:00', '09:00 – 10:00',
  '11:00 – 12:00', '17:00 – 18:00', '19:00 – 20:00',
];

function newPassId() {
  const s = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let out = '';
  for (let i = 0; i < 5; i++) out += s[Math.floor(Math.random() * s.length)];
  return `BSM-PJ-${out}`;
}

const today = () => new Date().toISOString().slice(0, 10);

/** उपलब्ध स्लॉट — कितनी सीटें बाकी */
pujaRouter.get('/slots', asyncH(async (req, res) => {
  const date = (req.query.date ?? today()).toString();
  const rows = await q(
    'SELECT slot, COUNT(*)::int AS taken FROM puja_passes WHERE date = $1 GROUP BY slot',
    [date],
  );
  const taken = Object.fromEntries(rows.map((r) => [r.slot, r.taken]));
  res.json({
    date,
    capacity: config.slotCapacity,
    slots: PUJA_SLOTS.map((slot) => {
      const used = taken[slot] ?? 0;
      return { slot, taken: used, left: Math.max(0, config.slotCapacity - used), full: used >= config.slotCapacity };
    }),
  });
}));

const bookSchema = z.object({
  name: z.string().trim().min(2).max(80),
  phone: z.string().trim().regex(/^[6-9]\d{9}$/).optional().or(z.literal('')),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  slot: z.string().min(3),
  type: z.string().min(2).max(40),
});

/** स्लॉट बुक करें — सीट नंबर UNIQUE से double-booking नहीं होती */
pujaRouter.post('/', validate(bookSchema), asyncH(async (req, res) => {
  const { name, phone = '', date, slot, type } = req.body;

  for (let seat = 1; seat <= config.slotCapacity; seat++) {
    const passId = newPassId();
    try {
      const rows = await q(
        `INSERT INTO puja_passes (pass_id, name, phone, date, slot, type, seat)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING pass_id, date, slot, type, seat`,
        [passId, name, phone, date, slot, type, seat],
      );
      return res.status(201).json({ pass: rows[0], message: 'पास जारी' });
    } catch (e) {
      // 23505 = unique violation → यह सीट भर गई, अगली आज़माएँ
      if (e.code === '23505' || /duplicate key|unique/i.test(String(e.message))) continue;
      throw e;
    }
  }
  res.status(409).json({ error: 'यह स्लॉट भर गया है — दूसरा स्लॉट चुनें' });
}));

/** गेट स्कैनर — पास सत्यापित करें (दोबारा इस्तेमाल नहीं) */
pujaRouter.post('/verify', asyncH(async (req, res) => {
  const passId = String(req.body?.passId ?? '').trim().toUpperCase();
  if (!passId) return res.status(400).json({ error: 'पास आईडी दें' });

  const rows = await q('SELECT * FROM puja_passes WHERE pass_id = $1', [passId]);
  const pass = rows[0];
  if (!pass) return res.status(404).json({ error: 'पास नहीं मिला' });
  if (pass.used) return res.status(409).json({ error: 'यह पास पहले प्रयोग हो चुका है', usedAt: pass.used_at });

  await q('UPDATE puja_passes SET used = TRUE, used_at = now() WHERE pass_id = $1', [passId]);
  res.json({
    verified: true,
    pass: { passId: pass.pass_id, name: pass.name, date: pass.date, slot: pass.slot, type: pass.type },
  });
}));

/** आज के पास (एडमिन) */
pujaRouter.get('/passes', asyncH(async (req, res) => {
  const date = (req.query.date ?? today()).toString();
  const rows = await q('SELECT * FROM puja_passes WHERE date = $1 ORDER BY slot, seat', [date]);
  res.json({ date, count: rows.length, passes: rows });
}));
