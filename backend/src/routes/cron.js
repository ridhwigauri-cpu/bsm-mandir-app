import { Router } from 'express';
import { asyncH } from '../middleware/validate.js';
import { requireServiceKey } from '../middleware/auth.js';
import { config } from '../config.js';
import { sendAartiAlert } from '../services/fcm.js';

export const cronRouter = Router();

/**
 * EventBridge (CloudWatch Events) यह endpoint तय समय पर कॉल करता है।
 * Lambda पर `setInterval` नहीं चलता, इसलिए आरती अलर्ट इसी रास्ते जाता है।
 *
 * POST /api/cron/aarti        (x-service-key)
 * body: { "name": "संध्या आरती", "time": "19:00" }   — दोनों वैकल्पिक
 */
cronRouter.post('/aarti', requireServiceKey, asyncH(async (req, res) => {
  // IST = UTC + 5:30
  const ist = new Date(Date.now() + 330 * 60_000);
  const hhmm = `${String(ist.getUTCHours()).padStart(2, '0')}:${String(ist.getUTCMinutes()).padStart(2, '0')}`;

  const names = { '06:30': 'मंगला आरती', '12:00': 'भोग आरती', '19:00': 'संध्या आरती' };
  const name = req.body?.name ?? names[hhmm] ?? 'आरती';
  const time = req.body?.time ?? hhmm;

  const result = await sendAartiAlert({ name, time });
  if (!result.ok) return res.status(502).json({ error: 'FCM भेजने में गड़बड़', detail: result.error });
  res.json({ sent: true, demo: Boolean(result.demo), name, time, messageId: result.id ?? null });
}));

/** स्वास्थ्य जाँच — cron सही जुड़ा है या नहीं */
cronRouter.get('/ping', requireServiceKey, (req, res) => {
  res.json({
    ok: true,
    lambda: config.isLambda,
    aartiTimes: config.aartiTimes,
    reportsBucket: config.reportsBucket || null,
    time: new Date().toISOString(),
  });
});
