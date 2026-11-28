import 'dotenv/config';

const num = (v, d) => (v === undefined || v === '' ? d : Number(v));

export const config = {
  port: num(process.env.PORT, 8080),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  databaseUrl: process.env.DATABASE_URL ?? '',
  jwtSecret: process.env.JWT_SECRET ?? 'dev-only-change-me',
  adminPin: process.env.ADMIN_PIN ?? '1088',
  corsOrigins: (process.env.CORS_ORIGINS ?? '*').split(',').map((s) => s.trim()),

  razorpay: {
    keyId: process.env.RAZORPAY_KEY_ID ?? '',
    keySecret: process.env.RAZORPAY_KEY_SECRET ?? '',
    webhookSecret: process.env.RAZORPAY_WEBHOOK_SECRET ?? '',
    get enabled() { return this.keyId !== '' && this.keySecret !== ''; },
  },

  serviceKey: process.env.SERVICE_KEY ?? 'dev-service-key',
  // Lambda पर चल रहे हैं? (serverless-http handler सेट करता है)
  isLambda: Boolean(process.env.AWS_LAMBDA_FUNCTION_NAME),

  // Neon / Postgres pool — Lambda पर छोटा रखें (हर invocation अलग)
  dbMaxConnections: num(process.env.DB_MAX_CONNECTIONS, 3),
  dbIdleTimeoutMs: num(process.env.DB_IDLE_TIMEOUT_MS, 5000),

  // रिपोर्ट PDF/Excel को S3 पर रखकर presigned URL देना (Lambda की 6MB सीमा से बचने के लिए)
  reportsBucket:
    process.env.REPORTS_BUCKET ??
    process.env.NEON_BUCKET_NAME ??
    process.env.BUCKET_NAME ??
    '',
  reportsUrlTtl: num(process.env.REPORTS_URL_TTL, 900),

  // PDF रेंडरिंग के लिए Chromium (सर्वर पर: apt install chromium)
  chromiumPath: process.env.CHROMIUM_PATH ?? '/usr/bin/chromium',

  // Firebase (FCM HTTP v1) — service account JSON का path या base64
  firebaseServiceAccount: process.env.FIREBASE_SERVICE_ACCOUNT ?? '',
  fcmTopic: process.env.FCM_TOPIC ?? 'aarti_alerts',
  // रोज़ की आरती के समय (स्वचालित नोटिफिकेशन) — खाली रखें तो बंद
  aartiTimes: (process.env.AARTI_TIMES ?? '').split(',').map((s) => s.trim()).filter(Boolean),

  slotCapacity: num(process.env.SLOT_CAPACITY, 6),
  kirtanCapacity: num(process.env.KIRTAN_CAPACITY, 4),
  fyStartMonth: num(process.env.FY_START_MONTH, 4),
};
