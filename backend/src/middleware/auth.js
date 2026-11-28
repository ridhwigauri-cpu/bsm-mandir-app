import jwt from 'jsonwebtoken';
import { config } from '../config.js';

export function signAdminToken(payload = {}) {
  return jwt.sign({ role: 'admin', ...payload }, config.jwtSecret, { expiresIn: '12h' });
}

/** एडमिन JWT जाँच */
export function requireAdmin(req, res, next) {
  const header = req.headers.authorization ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return res.status(401).json({ error: 'लॉगिन ज़रूरी है' });
  try {
    const decoded = jwt.verify(token, config.jwtSecret);
    if (decoded.role !== 'admin') return res.status(403).json({ error: 'अनुमति नहीं' });
    req.admin = decoded;
    next();
  } catch {
    return res.status(401).json({ error: 'सत्र समाप्त — फिर लॉगिन करें' });
  }
}

/** AI सुरक्षा सर्विस / PA डिवाइस के लिए साझा key */
export function requireServiceKey(req, res, next) {
  const key = req.headers['x-service-key'] ?? '';
  if (key !== config.serviceKey) return res.status(401).json({ error: 'गलत service key' });
  next();
}
