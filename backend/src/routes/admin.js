import { Router } from 'express';
import { q } from '../db.js';
import { requireAdmin } from '../middleware/auth.js';
import { asyncH } from '../middleware/validate.js';

export const adminRouter = Router();

/**
 * सार्वजनिक सारांश — ऐप की होम स्क्रीन के लिए (बिना लॉगिन)
 * सिर्फ़ जोड़ और गिनती — कोई दाता का नाम/फ़ोन नहीं।
 */
adminRouter.get('/public/summary', asyncH(async (_req, res) => {
  const [don, rooms, projects] = await Promise.all([
    q(`SELECT COALESCE(SUM(amount) FILTER (WHERE status = 'paid'), 0)::int AS total_paid,
              COUNT(*) FILTER (WHERE status = 'paid')::int AS count_paid
         FROM donations`),
    q('SELECT COUNT(*)::int AS total, COUNT(*) FILTER (WHERE occupied_by IS NOT NULL)::int AS occupied FROM rooms'),
    q('SELECT name, spent, target, status FROM projects ORDER BY id'),
  ]);
  res.json({ donations: don[0], rooms: rooms[0], projects });
}));

/** डैशबोर्ड सारांश — दान, परियोजनाएँ, स्टाफ, कमरे, अलर्ट, घोषणा */
adminRouter.get('/summary', requireAdmin, asyncH(async (req, res) => {
  const [don, byMethod, proj, staff, rooms, alerts, ann, lekha] = await Promise.all([
    q(`SELECT
         COALESCE(SUM(amount) FILTER (WHERE status = 'paid'), 0)::int AS total_paid,
         COALESCE(SUM(amount) FILTER (WHERE status = 'paid' AND created_at::date = CURRENT_DATE), 0)::int AS today,
         COUNT(*) FILTER (WHERE status = 'paid')::int AS count_paid,
         COUNT(*) FILTER (WHERE status = 'pending_verification')::int AS pending_verification
       FROM donations`),
    q(`SELECT method, COALESCE(SUM(amount), 0)::int AS total
         FROM donations WHERE status = 'paid' GROUP BY method`),
    q('SELECT * FROM projects ORDER BY id'),
    q('SELECT dept, COUNT(*)::int AS count FROM staff GROUP BY dept'),
    q('SELECT COUNT(*)::int AS total, COUNT(*) FILTER (WHERE occupied_by IS NOT NULL)::int AS occupied FROM rooms'),
    q(`SELECT COUNT(*)::int AS total,
              COUNT(*) FILTER (WHERE created_at::date = CURRENT_DATE)::int AS today
         FROM alerts`),
    q(`SELECT COUNT(*)::int AS queued FROM announcements WHERE status <> 'played'`),
    q('SELECT * FROM lekha ORDER BY id DESC LIMIT 12'),
  ]);

  res.json({
    donations: don[0],
    byMethod,
    projects: proj,
    staff: staff,
    rooms: rooms[0],
    alerts: alerts[0],
    announcements: ann[0],
    lekha,
  });
}));

adminRouter.get('/projects', requireAdmin, asyncH(async (_req, res) => {
  res.json({ projects: await q('SELECT * FROM projects ORDER BY id') });
}));

adminRouter.get('/staff', requireAdmin, asyncH(async (_req, res) => {
  res.json({ staff: await q('SELECT * FROM staff ORDER BY dept, name') });
}));

adminRouter.get('/lekha', requireAdmin, asyncH(async (_req, res) => {
  res.json({ lekha: await q('SELECT * FROM lekha ORDER BY id DESC') });
}));

adminRouter.get('/audit', requireAdmin, asyncH(async (_req, res) => {
  res.json({ audit: await q('SELECT * FROM audit_log ORDER BY created_at DESC LIMIT 100') });
}));
