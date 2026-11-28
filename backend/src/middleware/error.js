export function notFound(req, res) {
  res.status(404).json({ error: 'रास्ता नहीं मिला', path: req.path });
}

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  const status = err.status ?? 500;
  if (status >= 500) req.log?.error({ err }, 'server error');
  res.status(status).json({
    error: status >= 500 ? 'सर्वर में गड़बड़ी' : err.message,
    ...(status >= 500 && process.env.NODE_ENV !== 'production' ? { detail: String(err.message) } : {}),
  });
}
