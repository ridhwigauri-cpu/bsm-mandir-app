# बाबा सिद्धनाथ मंदिर — बैकएंड API (Node + PostgreSQL)

फाउंडेशन के ऐप के लिए पूरा सर्वर: **दान (Razorpay + UTR), पूजा/VIP पास, धर्मशाला व कीर्तन, दान की घोषणा (PA सिस्टम), AI सुरक्षा अलर्ट, एडमिन डैशबोर्ड, रसीद PDF, आरती पुश (FCM), 80G रजिस्टर (Excel/PDF)।**
Node 20 · Express · PostgreSQL · JWT · zod · Puppeteer (PDF) · ExcelJS · FCM v1

---

> **Lambda + Neon पर चलाना है?** → [README-LAMBDA.md](README-LAMBDA.md) देखें
> (SAM template, Neon setup, S3 रिपोर्ट, आरती cron — सब तैयार है)

## 1. शुरू करना (लोकल)

```bash
cp .env.example .env          # DATABASE_URL, JWT_SECRET, ADMIN_PIN आदि भरें
npm install
npm run migrate               # टेबल बनाएँ (db/schema.sql)
npm run seed                  # कमरे, परियोजनाएँ, स्टाफ, लेखा डालें
npm start                     # http://localhost:8080/health
```

**Docker से (सबसे आसान):**
```bash
docker compose up --build     # db + api दोनों, माइग्रेशन अपने आप
```

**टेस्ट (Postgres की ज़रूरत नहीं — in-memory):**
```bash
npm test        # 17 टेस्ट: दान, रसीद, घोषणा, स्लॉट, गेट स्कैनर, अलर्ट, डैशबोर्ड, PDF, Excel, FCM
```

> PDF के लिए सर्वर पर **Chromium** चाहिए: `apt install chromium` (Dockerfile में पहले से है)।
> पुराने डेटाबेस पर एक बार चलाएँ: `db/migrations/2026-11-28_receipt_token.sql`

---

## 2. डिप्लॉय (VPS / Render / Railway)

| जगह | तरीका |
|---|---|
| **VPS (₹500–1,000/माह)** | `docker compose up -d` + Nginx reverse proxy + `certbot` (HTTPS) |
| **Render / Railway** | GitHub repo जोड़ें → build `npm ci` → start `npm start` → env vars डालें; Postgres add-on या Neon का `DATABASE_URL` |
| **डेटाबेस** | Neon / Supabase / RDS — `DATABASE_URL` में connection string (SSL के साथ `?sslmode=require`) |

डिप्लॉय के बाद ये सेट करें:
- **Razorpay Dashboard ▸ Webhooks** → `https://<domain>/api/webhooks/razorpay`, event `payment.captured`, secret वही जो `RAZORPAY_WEBHOOK_SECRET` में है
- `ADMIN_PIN` बदलें, `JWT_SECRET` लंबा रैंडम रखें, `SERVICE_KEY` AI सर्विस और PA डिवाइस में डालें

---

## 3. API — एक नज़र में

### लॉगिन
```
POST /api/auth/login   { "pin": "1088" }   → { token }
```
आगे के एडमिन रास्तों पर header: `Authorization: Bearer <token>`

### दान
| Method | रास्ता | काम |
|---|---|---|
| POST | `/api/donations/order` | ऑर्डर — `{name, phone, category, amount}` → `{donationId, orderId, keyId}` |
| POST | `/api/donations/verify` | `{donationId, razorpay_order_id, razorpay_payment_id, razorpay_signature}` → रसीद नंबर |
| POST | `/api/donations/manual` | QR/बैंक से आया दान — `{..., method: UPI_QR, utr}` → सत्यापन लंबित |
| POST | `/api/donations/:id/approve` | (एडमिन) सत्यापन के बाद रसीद जारी |
| GET | `/api/donations?status=paid` | (एडमिन) सूची |
| POST | `/api/webhooks/razorpay` | रज़ोरपे वेबहुक (raw body + HMAC) |

रसीद नंबर: `80G/2026-27/1001` — वित्त-वर्ष काउंटर DB में, **एक ही लेन-देन** में।
`razorpay_payment_id` पर UNIQUE — वेबहुक दो बार आए तो भी रसीद एक ही बनती है।

### पूजा / VIP पास
| Method | रास्ता | काम |
|---|---|---|
| GET | `/api/puja/slots?date=2026-12-01` | हर स्लॉट की बची सीट |
| POST | `/api/puja` | `{name, phone, date, slot, type}` → `{pass: {pass_id, seat}}`; भरा स्लॉट → **409** |
| POST | `/api/puja/verify` | गेट स्कैनर — `{passId}`; दोबारा → **409** |
| GET | `/api/puja/passes?date=…` | दिन के पास |

सीट नंबर + `UNIQUE(date, slot, seat)` — इससे दो फ़ोन एक साथ बुक करें तो भी **double-booking नहीं** होती।

### धर्मशाला + अखंड कीर्तन
| Method | रास्ता | काम |
|---|---|---|
| GET | `/api/rooms?date=…` | कमरे + कीर्तन स्लॉट की स्थिति |
| POST | `/api/rooms/book` | `{name, phone, aadhaarLast4, roomId, date, kirtan}` |
| POST | `/api/rooms/:id/release` | कमरा खाली |

कमरा `UPDATE … WHERE occupied_by IS NULL` से atomic तरीके से कब्ज़े में आता है — दो लोग एक साथ बुक नहीं कर सकते।
⚠️ **आधार का पूरा नंबर कभी न भेजें** — सिर्फ़ आख़िरी 4 अंक।

### दान की घोषणा (मंदिर PA)
| Method | रास्ता | काम |
|---|---|---|
| POST | `/api/announcements` | (एडमिन) कतार में डालें — `{name, amount, text?}` |
| GET | `/api/announcements/pending` | **PA डिवाइस** पोल करे (`x-service-key`) |
| POST | `/api/announcements/:id/played` | बज गया |
| POST | `/api/announcements/:id/retry` | नहीं बजा → वापस कतार में |

भुगतान सफल होते ही घोषणा **अपने आप** कतार में आ जाती है।
डिवाइस स्क्रिप्ट: **`tools/pa_device.py`** (Raspberry Pi / Windows PC — espeak-ng या SAPI से बोलती है)

### AI सुरक्षा
```
POST /api/alerts   (x-service-key)   {cam, label, confidence, photo_url, clip_url}
GET  /api/alerts   (एडमिन)
```

### 3.1 रसीद PDF (सर्वर से)
| Method | रास्ता | काम |
|---|---|---|
| GET | `/api/reports/receipt/:id.pdf?token=…` | **दान प्रशस्ति पत्र PDF** — टोकन से बिना लॉगिन खुलती है (WhatsApp पर भेजने लायक) |

भुगतान के जवाब में `receiptPdfUrl` मिलता है (जैसे `/api/reports/receipt/12.pdf?token=ab12…`)।
HTML → Chromium → PDF, Devanagari फ़ॉन्ट repo के `assets/fonts` से base64 में एम्बेड — हर सर्वर पर एक जैसा।

### 3.2 80G रजिस्टर (Excel / PDF)
| Method | रास्ता | काम |
|---|---|---|
| GET | `/api/reports/register.xlsx?from=2026-11-01&to=2026-11-30` | Excel — रसीद, दाता, मोबाइल, श्रेणी, राशि, माध्यम, UTR/भुगतान ID, कुल जोड़ |
| GET | `/api/reports/register.pdf?from=…&to=…` | वही रजिस्टर A4 landscape PDF में (छपाई के लिए) |
| GET | `/api/reports/lekha.xlsx` | माह-वार लेखा (आय/खर्च/शेष) |

### 3.3 आरती पुश नोटिफिकेशन (FCM)
| Method | रास्ता | काम |
|---|---|---|
| GET | `/api/notifications/status` | Firebase जुड़ा है या डेमो मोड |
| POST | `/api/notifications/aarti` | `{name, time}` → टॉपिक `aarti_alerts` पर सूचना |
| POST | `/api/notifications/send` | कोई भी सूचना `{title, body, topic?, data?}` |

- **स्वचालित**: `.env` में `AARTI_TIMES=06:30,12:00,19:00` — सर्वर हर मिनट जाँचता है और आरती अलर्ट भेज देता है
- Firebase: Project Settings ▸ Service accounts ▸ *Generate new private key* → JSON का path `FIREBASE_SERVICE_ACCOUNT` में
- keys न हों तो **डेमो मोड** — मैसेज लॉग होता है, सिस्टम नहीं रुकता
- ऐप में `firebase_messaging` जोड़कर टॉपिक `aarti_alerts` सब्सक्राइब करें

### एडमिन डैशबोर्ड
```
GET /api/admin/summary     → दान (कुल/आज), method-wise, परियोजनाएँ, स्टाफ, कमरे, अलर्ट, घोषणा कतार, लेखा
GET /api/admin/projects · /staff · /lekha · /audit
```

---

## 4. ऐप से जोड़ना (Flutter)

`lib/config/app_config.dart` में:
```dart
static const String apiBaseUrl   = 'https://api.bsmmandir.org';
static const String paSystemUrl  = 'https://api.bsmmandir.org'; // PA कतार उसी सर्वर पर
static const String razorpayKeyId = 'rzp_live_…';
```
ऐप अभी दान-रसीद क्लाइंट पर बनाता है; बैकएंड जुड़ने पर `payment_service.dart` के
`TODO(backend)` पर signature verify कॉल जोड़ दें — रसीद नंबर सर्वर से आएगा (क्रम टूटेगा नहीं)।

---

## 5. सुरक्षा / अनुपालन

- Helmet, CORS allowlist, rate-limit (300/min, लॉगिन 20/10min), zod validation, JWT (12h)
- रज़ोरपे हस्ताक्षर: `HMAC-SHA256(order_id|payment_id, key_secret)`; वेबहुक raw body पर HMAC
- संवेदनशील डेटा न रखें: PAN/Aadhaar पूरा नहीं — सिर्फ़ आख़िरी 4 अंक
- `audit_log` में हर भुगतान/बदलाव दर्ज
- डेटाबेस **ap-south-1 (मुंबई)** में रखें; बैकअप रोज़ (pg_dump → S3)

---

## 6. फ़ोल्डर

```
src/
├── app.js / server.js     Express ऐप
├── config.js              env
├── db.js                  pool + tx()
├── routes/                auth · donations · puja · rooms · announcements · alerts · admin
├── services/              razorpay.js (order/verify/webhook) · receipts.js (FY रसीद, घोषणा टेक्स्ट)
└── middleware/            auth · validate · error
db/schema.sql · db seed (src/scripts/seed.js)
test/api.test.js           12 टेस्ट (pg-mem — बिना Postgres)
tools/pa_device.py         मंदिर के स्पीकर के लिए पोलिंग स्क्रिप्ट
```

## 7. नया क्या जुड़ा (v1.1)
- ✅ **रसीद PDF सर्वर से** — `puppeteer-core` + Chromium, Devanagari फ़ॉन्ट base64 में, टोकन वाला सार्वजनिक लिंक
- ✅ **FCM आरती पुश** — HTTP v1, सिर्फ़ `node:crypto` से OAuth2 (कोई भारी SDK नहीं), रोज़ का शेड्यूलर
- ✅ **80G रजिस्टर** — Excel (ExcelJS, फ़िल्टर + टोटल) और PDF (A4 landscape), साथ में लेखा Excel

## 8. अगला कदम (ज़रूरत पड़े तो)
- ऐप में FCM सब्सक्राइब + PDF लिंक शेयर बटन
- रसीद का WhatsApp टेम्पलेट (Meta Cloud API)
- दान पर SMS रसीद
