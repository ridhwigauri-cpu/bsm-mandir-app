import { createApp } from './app.js';
import { config } from './config.js';
import { startAartiScheduler } from './services/fcm.js';

const app = createApp();
app.listen(config.port, () => {
  // eslint-disable-next-line no-console
  console.log(`BSM Mandir API चालू — http://localhost:${config.port}  (env: ${config.nodeEnv})`);
  if (!config.isLambda) startAartiScheduler();
  if (!config.razorpay.enabled) {
    console.log('⚠️  Razorpay keys खाली हैं — भुगतान डेमो मोड में है');
  }
});
