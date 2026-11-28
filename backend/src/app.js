import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import pinoHttp from 'pino-http';
import { config } from './config.js';
import { notFound, errorHandler } from './middleware/error.js';
import { authRouter } from './routes/auth.js';
import { donationsRouter, razorpayWebhook } from './routes/donations.js';
import { pujaRouter } from './routes/puja.js';
import { roomsRouter } from './routes/rooms.js';
import { announcementsRouter } from './routes/announcements.js';
import { alertsRouter } from './routes/alerts.js';
import { adminRouter } from './routes/admin.js';
import { reportsRouter } from './routes/reports.js';
import { notificationsRouter } from './routes/notifications.js';
import { cronRouter } from './routes/cron.js';

export function createApp() {
  const app = express();
  app.set('trust proxy', 1);
  app.use(helmet());
  app.use(cors({
    origin: config.corsOrigins.includes('*') ? true : config.corsOrigins,
  }));
  app.use(pinoHttp({ enabled: config.nodeEnv !== 'test', level: config.isLambda ? 'warn' : 'info' }));
  app.use(rateLimit({ windowMs: 60_000, max: 300, standardHeaders: true }));

  // वेबहुक को raw body चाहिए (signature जाँच के लिए)
  app.post('/api/webhooks/razorpay', express.raw({ type: '*/*', limit: '2mb' }), razorpayWebhook);

  app.use(express.json({ limit: '1mb' }));

  app.get('/health', (_req, res) => res.json({ ok: true, service: 'bsm-mandir-api', time: new Date().toISOString() }));

  app.use('/api/auth', authRouter);
  app.use('/api/donations', donationsRouter);
  app.use('/api/puja', pujaRouter);
  app.use('/api/rooms', roomsRouter);
  app.use('/api/announcements', announcementsRouter);
  app.use('/api/alerts', alertsRouter);
  app.use('/api/admin', adminRouter);
  app.use('/api/reports', reportsRouter);
  app.use('/api/notifications', notificationsRouter);
  app.use('/api/cron', cronRouter);

  app.use(notFound);
  app.use(errorHandler);
  return app;
}
