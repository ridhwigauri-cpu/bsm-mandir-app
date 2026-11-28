export const validate = (schema) => (req, res, next) => {
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: 'इनपुट गलत है',
      details: parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`),
    });
  }
  req.body = parsed.data;
  next();
};

export const asyncH = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
