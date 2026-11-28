import { Router } from 'express';
import { z } from 'zod';
import rateLimit from 'express-rate-limit';
import { config } from '../config.js';
import { validate } from '../middleware/validate.js';
import { signAdminToken } from '../middleware/auth.js';

export const authRouter = Router();

const loginLimiter = rateLimit({ windowMs: 10 * 60 * 1000, max: 20, standardHeaders: true });

/** एडमिन लॉगिन — PIN (env ADMIN_PIN) → JWT */
authRouter.post('/login', loginLimiter, validate(z.object({ pin: z.string().min(4).max(12) })), (req, res) => {
  if (req.body.pin !== config.adminPin) {
    return res.status(401).json({ error: 'गलत पिन' });
  }
  res.json({ token: signAdminToken(), role: 'admin', expiresIn: '12h' });
});
