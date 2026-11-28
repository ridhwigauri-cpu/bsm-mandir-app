# Lambda + Neon पर तैनाती (सबसे सस्ता रास्ता)

यह गाइड बैकएंड को **AWS Lambda + Neon Postgres** पर चलाती है।
अनुमानित खर्च: **सामान्य महीना ≈ ₹35 · मेला महीना ≈ ₹4,100** (5 लाख श्रद्धालु)।

```
ऐप / PA डिवाइस
      │  HTTPS
      ▼
API Gateway (HTTP API · $1 प्रति दस लाख requests)
      │
      ▼
Lambda (Node 20 · arm64 · 1 GB)  ──►  Neon Postgres (pooled connection)
      │
      ├──► S3 (रसीद PDF / 80G रजिस्टर — 15 मिनट का लिंक)
      └──► FCM (आरती पुश)
EventBridge ──► वही Lambda (आरती अलर्ट, रोज़ 3 बार)
```

---

## 1. Neon डेटाबेस (10 मिनट, मुफ़्त)

1. https://neon.tech पर साइन अप करें → **New Project**
   - Region: **AWS ap-south-1 (Mumbai)**
   - Database name: `bsm`
2. **Dashboard → Connect** खोलें और **Pooled connection** चुनें (host में `-pooler` दिखेगा)।
   कुछ ऐसा:
   ```
   postgresql://bsm_owner:PASSWORD@ep-cool-name-123456-pooler.ap-south-1.aws.neon.tech/bsm?sslmode=require
   ```
   ⚠️ **pooled ही लें** — Lambda में हर invocation अलग connection खोलता है, सीधा (direct) host देने पर
   मेला के दिन “too many connections” आ जाएगा।
3. टेबल बनाएँ — Neon के **SQL Editor** में `db/schema.sql` का पूरा कंटेंट पेस्ट करके Run करें
   (या लोकल से: `psql "<pooled-url>" -f db/schema.sql`)
4. शुरुआती डेटा (कमरे, परियोजनाएँ, स्टाफ, लेखा):
   `psql "<pooled-url>" -f db/seed.sql` — या Neon SQL Editor में `src/scripts/seed.js` के INSERT चला दें।

**Free plan** में 0.5 GB storage + कुछ compute घंटे मिलते हैं — सामान्य महीनों के लिए काफ़ी।
**मेला महीने से पहले** **Launch ($19/माह)** पर अपग्रेड कर लें (सिर्फ़ उस महीने, बाद में वापस Free)।

---

## 2. ज़रूरी टूल (एक बार)

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip && sudo ./aws/install
aws configure          # ap-south-1, access key

# AWS SAM CLI (डिप्लॉय के लिए)
pip install aws-sam-cli     # या: brew install aws-sam-cli
sam --version
```

---

## 3. डिप्लॉय

```bash
cd bsm-backend
sam build
sam deploy --guided
```

`--guided` में ये जवाब दें:

| सवाल | जवाब |
|---|---|
| Stack Name | `bsm-mandir-api` |
| AWS Region | `ap-south-1` |
| Parameter NeonDatabaseUrl | Neon का **pooled** URL |
| Parameter AdminPin | `1088` (या अपना) |
| Parameter ServiceKey | `openssl rand -hex 24` से बनाई key |
| Parameter JwtSecret | `openssl rand -hex 32` |
| Parameter RazorpayKeyId / Secret / WebhookSecret | Razorpay Dashboard से |
| Parameter FirebaseServiceAccountJson | service-account JSON का **पूरा टेक्स्ट एक लाइन में** (खाली छोड़ें तो डेमो मोड) |
| Parameter AartiTimes | `06:30,12:00,19:00` |
| Allow SAM CLI IAM role creation | `Y` |
| Save arguments to configuration file | `Y` |

डिप्लॉय के अंत में **ApiUrl** दिखेगा:

```
https://abc123xyz.execute-api.ap-south-1.amazonaws.com
```

जाँचें:

```bash
curl https://abc123xyz.execute-api.ap-south-1.amazonaws.com/health
# {"ok":true,"service":"bsm-mandir-api",...}

curl -X POST https://<api>/api/donations/order \
  -H "Content-Type: application/json" \
  -d '{"name":"रमेश शर्मा","phone":"9876543210","category":"जीर्णोद्धार","amount":1100}'
```

ऐप में `lib/config/app_config.dart` → `apiBaseUrl` में यही URL डालें।

---

## 4. बाकी जोड़ें

**Razorpay वेबहुक** — Dashboard → Settings → Webhooks → Add:
`https://<api>/api/webhooks/razorpay` · event `payment.captured` · secret वही जो Parameter में दिया।

**PA स्पीकर (मंदिर)** — मंदिर के Raspberry Pi/PC पर:
```bash
API=https://<api> SERVICE_KEY=<वही key> POLL_SECONDS=15 python3 tools/pa_device.py
```
15 सेकंड रखें — 2 सेकंड पर Lambda invocations 13 लाख/महीना हो जाते हैं (बेकार का खर्च)।

**आरती अलर्ट** — EventBridge नियम template में पहले से है (06:30, 12:00, 19:00 IST)।
हाथ से जाँचें:
```bash
curl -X POST https://<api>/api/cron/aarti -H "x-service-key: <key>" \
  -H "Content-Type: application/json" -d '{"name":"संध्या आरती","time":"19:00"}'
```

---

## 5. रसीद PDF — दो विकल्प

| तरीका | कैसे | कब |
|---|---|---|
| **ऐप में PDF** (डिफ़ॉल्ट) | `printing` पैकेज, फ़ोन पर ही बनती है | हमेशा — सबसे सस्ता, सर्वर पर ज़ीरो लोड |
| **सर्वर से PDF** | `Dockerfile.lambda` (Chromium सहित container image) | जब “लिंक से रसीद” चाहिए |

सर्वर PDF चाहिए तो zip deploy की जगह container image से डिप्लॉय करें:

```bash
# ECR में image
aws ecr create-repository --repository-name bsm-api --region ap-south-1
docker build -f Dockerfile.lambda -t bsm-api .
docker tag bsm-api:latest <account>.dkr.ecr.ap-south-1.amazonaws.com/bsm-api:latest
aws ecr get-login-password | docker login --username AWS --password-stdin <account>.dkr.ecr.ap-south-1.amazonaws.com
docker push <account>.dkr.ecr.ap-south-1.amazonaws.com/bsm-api:latest
```
फिर Lambda console में **Image** चुनकर वही image लगाएँ (memory 2048 MB, timeout 29s)।

**80G रजिस्टर / लेखा Excel** हमेशा S3 लिंक के रूप में मिलते हैं
(JSON में `url` — 15 मिनट तक वैध), क्योंकि Lambda का response 6 MB से बड़ा नहीं हो सकता।

---

## 6. लोकल में जाँच

```bash
npm test                     # 22 टेस्ट (बिना Postgres, pg-mem से)
npm start                    # सामान्य सर्वर — http://localhost:8080/health
sam local start-api          # Lambda जैसा (Docker चाहिए)
```

---

## 7. खर्च और उस पर काबू

| मद | सामान्य महीना | मेला महीना (1.27 करोड़ requests) |
|---|---|---|
| API Gateway (HTTP) | ₹17 | ₹1,070 |
| Lambda requests | ₹0 (free tier) | ₹195 |
| Lambda compute | ₹0 (free tier) | ₹770 |
| CloudWatch Logs (7 दिन retention) | ₹15 | ₹265 |
| Neon | ₹0 (Free) | ₹1,600 (Launch) |
| S3 (रिपोर्ट) | ₹5 | ₹40 |
| **कुल** | **≈ ₹35** | **≈ ₹3,900 – 4,100** |

काबू रखने के तीन नियम:
1. **HTTP API** ही रखें (REST API 3.5 गुना महँगा है)।
2. **लॉग retention 7 दिन** (template में सेट है) — वरना लॉग का बिल Lambda से बड़ा हो जाएगा।
3. **Billing → Budgets** में $20 का बजट + अलर्ट लगाएँ।

---

## 8. अपडेट करना

```bash
git pull
sam build && sam deploy        # 1–2 मिनट में नया version live
```

---

## 9. समस्या-समाधान

| लक्षण | कारण | हल |
|---|---|---|
| `too many connections` | Neon का direct (pooled नहीं) URL | `-pooler` वाला URL डालें, `DB_MAX_CONNECTIONS=3` रखें |
| पहला request 3–5 सेकंड | Neon auto-suspend (Free plan) | सामान्य है; मेला में Launch plan लें |
| `Task timed out after 29s` | भारी काम (PDF/रिपोर्ट) | PDF ऐप में बनाएँ; रिपोर्ट S3 लिंक से दें |
| CORS error | ऐप का origin | `CORS_ORIGINS` में origin डालें या `*` रखें |
| वेबहुक 400 | secret गलत | Parameter `RazorpayWebhookSecret` फिर से डालें |
| PDF 503 | Chromium नहीं | `Dockerfile.lambda` से deploy करें, या ऐप में PDF रखें |
| आरती अलर्ट नहीं आया | FCM JSON गलत/खाली | `FIREBASE_SERVICE_ACCOUNT` जाँचें; डेमो मोड में लॉग में दिखेगा |

---

## 10. EC2 से तुलना (आपके ट्रैफ़िक पर)

| | सामान्य महीना | मेला महीना | साल |
|---|---|---|---|
| **Lambda + Neon** | ₹35 | ₹4,100 | **₹4,500 – 8,000** |
| EC2 t4g.small + Postgres उसी बॉक्स पर | ₹1,250 | ₹1,250 | ₹15,000 |
| EC2 + RDS | ₹2,400 | ₹2,400 | ₹28,800 |

स्पाइक वाले ट्रैफ़िक (11 महीने शांत, 1 महीना 5 लाख) पर **Lambda सबसे सस्ता** है — और मेला में
कुछ भी तैयार करने की ज़रूरत नहीं, AWS खुद scale कर लेता है।
