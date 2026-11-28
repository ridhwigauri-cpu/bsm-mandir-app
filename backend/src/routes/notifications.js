import { Router } from 'express';
import { z } from 'zod';
import { validate, asyncH } from '../middleware/validate.js';
import { requireAdmin } from '../middleware/auth.js';
import { config } from '../config.js';
import { sendToTopic, sendAartiAlert, isConfigured } from '../services/fcm.js';

export const notificationsRouter = Router();

/** स्थिति — Firebase जुड़ा है या डेमो मोड */
notificationsRouter.get('/status', requireAdmin, (_req, res) => {
  res.json({
    configured: isConfigured(),
    topic: config.fcmTopic,
    aartiTimes: config.aartiTimes,
    mode: isConfigured() ? 'live' : 'demo',
  });
});

const aartiSchema = z.object({
  name: z.string().trim().min(2).max(60),
  time: z.string().regex(/^\d{2}:\d{2}$/).optional(),
});

/** आरती अलर्ट — टॉपिक aarti_alerts पर */
notificationsRouter.post('/aarti', requireAdmin, validate(aartiSchema), asyncH(async (req, res) => {
  const { name, time = '' } = req.body;
  const result = await sendAartiAlert({ name, time });
  if (!result.ok) return res.status(502).json({ error: 'FCM भेजने में गड़बड़', detail: result.error });
  res.json({ sent: true, demo: Boolean(result.demo), messageId: result.id ?? null });
}));

const topicSchema = z.object({
  title: z.string().trim().min(2).max(80),
  body: z.string().trim().min(2).max(300),
  topic: z.string().trim().min(2).max(60).optional(),
  data: z.record(z.string()).optional(),
});

/** कोई भी सूचना (एडमिन) */
notificationsRouter.post('/send', requireAdmin, validate(topicSchema), asyncH(async (req, res) => {
  const { title, body, topic, data = {} } = req.body;
  const result = await sendToTopic({ title, body, topic: topic ?? config.fcmTopic, data });
  if (!result.ok) return res.status(502).json({ error: 'FCM भेजने में गड़बड़', detail: result.error });
  res.json({ sent: true, demo: Boolean(result.demo), messageId: result.id ?? null });
}));
