import { defineConfig } from "@neon/config/v1";

/**
 * बाबा सिद्धनाथ मंदिर — Neon backend (infrastructure as code)
 *
 *  api       → पूरा Express API (दान, पूजा, धर्मशाला, घोषणा, रिपोर्ट)
 *  razorpay  → भुगतान वेबहुक (हस्ताक्षर जाँच → रसीद → घोषणा कतार)
 *  nightly   → रोज़ का हिसाब + सफ़ाई (Function Trigger: schedule)
 */
export default defineConfig({
  auth: false, // एडमिन लॉगिन अपना PIN + JWT (src/routes/auth.js)

  functions: {
    api: {
      name: "BSM Mandir API",
      source: "./functions/api.js",
      env: {
        RAZORPAY_KEY_ID: { value: process.env.RAZORPAY_KEY_ID, required: false },
        RAZORPAY_KEY_SECRET: { value: process.env.RAZORPAY_KEY_SECRET, required: false },
        RAZORPAY_WEBHOOK_SECRET: { value: process.env.RAZORPAY_WEBHOOK_SECRET, required: false },
        JWT_SECRET: { value: process.env.JWT_SECRET, required: true },
        ADMIN_PIN: { value: process.env.ADMIN_PIN ?? "1088", required: false },
        SERVICE_KEY: { value: process.env.SERVICE_KEY, required: true },
        FIREBASE_SERVICE_ACCOUNT: { value: process.env.FIREBASE_SERVICE_ACCOUNT, required: false },
        AARTI_TIMES: { value: process.env.AARTI_TIMES ?? "06:30,12:00,19:00", required: false },
      },
    },

    razorpay: {
      name: "Razorpay Webhook",
      source: "./functions/razorpay.js",
      env: {
        RAZORPAY_WEBHOOK_SECRET: { value: process.env.RAZORPAY_WEBHOOK_SECRET, required: true },
        RAZORPAY_KEY_SECRET: { value: process.env.RAZORPAY_KEY_SECRET, required: false },
      },
    },

    nightly: {
      name: "Nightly Report",
      source: "./functions/nightly.js",
    },
  },

  triggers: {
    "nightly-report": {
      type: "schedule",
      function: "nightly",
      cron: "30 20 * * *", // 20:30 UTC = रोज़ रात 2:00 बजे IST
      functionPath: "/cron",
    },
  },

  branch: (branch) => {
    if (branch.isDefault) {
      // production: nodejs24 (Neon Functions का runtime)
      return { functions: { api: { runtime: "nodejs24" }, razorpay: { runtime: "nodejs24" }, nightly: { runtime: "nodejs24" } } };
    }
    if (!branch.exists) return { ttl: "7d" };
    return {};
  },
});
