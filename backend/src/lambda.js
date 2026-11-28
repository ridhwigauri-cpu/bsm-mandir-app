import serverlessHttp from 'serverless-http';
import { createApp } from './app.js';
import { config } from './config.js';
import { sendAartiAlert } from './services/fcm.js';

/**
 * AWS Lambda handler (API Gateway HTTP API + EventBridge)
 *
 * - HTTP request  → serverless-http से Express ऐप
 * - EventBridge   → आरती अलर्ट (setInterval Lambda पर नहीं चलता)
 *
 * Neon के लिए DATABASE_URL में **pooled** connection string डालें
 * (host में `-pooler` वाला), वरना हर invocation नई connection खोलेगा।
 */

const app = createApp();

const httpHandler = serverlessHttp(app, {
  // बाइनरी response (जब S3 सेट न हो) ठीक से भेजने के लिए
  binary: [
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'image/*',
  ],
});

const AARTI_NAMES = { '06:30': 'मंगला आरती', '12:00': 'भोग आरती', '19:00': 'संध्या आरती' };

function isScheduledEvent(event) {
  return Boolean(event?.source === 'aws.events' || event?.['detail-type'] === 'Scheduled Event');
}

export const handler = async (event, context) => {
  if (isScheduledEvent(event)) {
    const ist = new Date(Date.now() + 330 * 60_000);
    const hhmm = `${String(ist.getUTCHours()).padStart(2, '0')}:${String(ist.getUTCMinutes()).padStart(2, '0')}`;
    const name = AARTI_NAMES[hhmm] ?? 'आरती';
    const result = await sendAartiAlert({ name, time: hhmm });
    console.log(`[cron] ${hhmm} ${name}`, result);
    return { statusCode: 200, body: JSON.stringify({ sent: result.ok, name, time: hhmm, demo: result.demo ?? false }) };
  }

  // HTTP API (payload v2) — serverless-http को context भी चाहिए
  return httpHandler(event, context);
};

/** लोकल जाँच: node -e "import('./src/lambda.js').then(m=>console.log(typeof m.handler))" */
export const __app = app;
export const __config = config;
