import { Router } from 'express';
import { z } from 'zod';
import { q } from '../db.js';
import { config } from '../config.js';
import { validate, asyncH } from '../middleware/validate.js';

export const roomsRouter = Router();

export const KIRTAN_SLOTS = ['09:00 – 11:00', '12:00 – 14:00', '16:00 – 18:00', '19:00 – 21:00'];

const today = () => new Date().toISOString().slice(0, 10);

/** कमरे + कीर्तन स्लॉट की स्थिति */
roomsRouter.get('/', asyncH(async (req, res) => {
  const date = (req.query.date ?? today()).toString();
  const rooms = await q('SELECT id, name, capacity, occupied_by, occupied_at FROM rooms ORDER BY id');
  const kirtan = await q(
    'SELECT slot, COUNT(*)::int AS taken FROM kirtan_seats WHERE date = $1 GROUP BY slot',
    [date],
  );
  const taken = Object.fromEntries(kirtan.map((r) => [r.slot, r.taken]));
  res.json({
    date,
    rooms: rooms.map((r) => ({ ...r, available: r.occupied_by === null })),
    kirtan: KIRTAN_SLOTS.map((slot) => {
      const used = taken[slot] ?? 0;
      return { slot, taken: used, left: Math.max(0, config.kirtanCapacity - used), full: used >= config.kirtanCapacity };
    }),
  });
}));

const bookSchema = z.object({
  name: z.string().trim().min(2).max(80),
  phone: z.string().trim().regex(/^[6-9]\d{9}$/).optional().or(z.literal('')),
  aadhaarLast4: z.string().regex(/^\d{4}$/),
  roomId: z.string().min(1),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  kirtan: z.string().optional().or(z.literal('')),
});

function newPassId() {
  const s = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let out = '';
  for (let i = 0; i < 5; i++) out += s[Math.floor(Math.random() * s.length)];
  return `BSM-DS-${out}`;
}

/** कमरा बुक करें — UPDATE ... WHERE occupied_by IS NULL (atomic) */
roomsRouter.post('/book', validate(bookSchema), asyncH(async (req, res) => {
  const { name, phone = '', aadhaarLast4, roomId, date, kirtan = '' } = req.body;

  const claim = await q(
    `UPDATE rooms SET occupied_by = $1, occupied_at = now()
      WHERE id = $2 AND occupied_by IS NULL
      RETURNING id, name`,
    [name, roomId],
  );
  if (claim.length === 0) {
    return res.status(409).json({ error: 'यह कमरा पहले से भरा है — दूसरा कमरा चुनें' });
  }

  // कीर्तन सीट (अगर चुना है)
  let kirtanSeat = null;
  if (kirtan) {
    for (let seat = 1; seat <= config.kirtanCapacity; seat++) {
      try {
        await q('INSERT INTO kirtan_seats (slot, date, seat) VALUES ($1, $2, $3)', [kirtan, date, seat]);
        kirtanSeat = seat;
        break;
      } catch (e) {
        if (e.code === '23505' || /duplicate key|unique/i.test(String(e.message))) continue;
        throw e;
      }
    }
    if (kirtanSeat === null) {
      // कमरा वापस छोड़ें
      await q('UPDATE rooms SET occupied_by = NULL, occupied_at = NULL WHERE id = $1', [roomId]);
      return res.status(409).json({ error: 'यह कीर्तन स्लॉट भर गया है' });
    }
  }

  const passId = newPassId();
  await q(
    `INSERT INTO room_bookings (pass_id, room_id, kirtan, date, name, phone, aadhaar_last4)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [passId, roomId, kirtan, date, name, phone, aadhaarLast4],
  );

  res.status(201).json({
    passId,
    room: claim[0].name,
    kirtan,
    kirtanSeat,
    date,
    message: 'कमरा व कीर्तन पास जारी',
  });
}));

/** कमरा खाली करें (एडमिन) */
roomsRouter.post('/:id/release', asyncH(async (req, res) => {
  await q('UPDATE rooms SET occupied_by = NULL, occupied_at = NULL WHERE id = $1', [req.params.id]);
  res.json({ released: req.params.id });
}));
