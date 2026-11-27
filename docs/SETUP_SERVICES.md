# असली सेवाएँ चालू करने की गाइड

ऐप में चार सेवाओं का **integration तैयार** है — सिर्फ़ keys/URLs भरने हैं।
सारी सेटिंग एक ही फ़ाइल में: **`lib/config/app_config.dart`**

```dart
static const String razorpayKeyId      = '';   // भुगतान
static const String liveStreamUrl      = '';   // लाइव दर्शन (m3u8)
static const String securityApiBaseUrl = '';   // AI सुरक्षा
static const String apiBaseUrl         = '';   // बैकएंड (आगे)
```

जो खाली है, वह सेवा **डेमो मोड** में चलती रहेगी — ऐप कभी टूटेगा नहीं।

---

## 1. भुगतान — Razorpay (दान + 80G रसीद)

**अकाउंट बनाना (भारत):**
1. [dashboard.razorpay.com/signup](https://dashboard.razorpay.com/signup) → मोबाइल/ईमेल से साइनअप
2. Business details: ट्रस्ट/फाउंडेशन का नाम, PAN, ट्रस्ट पंजीकरण/80G सर्टिफिकेट, बैंक खाता (settlement के लिए)
3. KYC में लगते हैं ~1–3 कार्यदिवस। **टेस्ट मोड** में KYC के बिना भी चेकआउट चल जाता है।

**Key लेना:**
- Dashboard ▸ **Account & Settings ▸ API Keys ▸ Generate Key**
- `Key Id` (`rzp_test_…` या `rzp_live_…`) कॉपी करके `razorpayKeyId` में डालें
- ⚠️ **Key Secret कभी ऐप में न डालें** — वह सर्वर पर रहता है (signature verify के लिए)

**ऐप में क्या होता है:**
- `lib/services/payment_service.dart` → Razorpay चेकआउट खोलता है (amount paise में, prefill नाम/मोबाइल, theme मैरून)
- सफल होने पर दान दर्ज होकर 80G रसीद बनती है, माध्यम "Razorpay" दिखता है

**टेस्ट कार्ड (टेस्ट मोड):** `4111 1111 1111 1111` · किसी भी भविष्य की तारीख़ · CVV `123`

**बाकी बचा काम (जब बैकएंड बने):** भुगतान के बाद `payment_id + order_id + signature` सर्वर पर verify कराना — `payment_service.dart` में `TODO(backend)` पर निशान लगा है।

---

## 2. 24x7 लाइव दर्शन (HLS)

कैमरा सीधे ऐप में नहीं चलता — उसे **HLS (m3u8)** में बदलना पड़ता है। तीन रास्ते:

| तरीका | कैसे | खर्च |
|---|---|---|
| **A. RTMP सर्विस (सबसे आसान)** | कैमरे/NVR का RTMP आउटपुट (या OBS से) → YouTube Live (unlisted) / Cloudflare Stream / Mux → वहाँ से HLS लिंक | YouTube मुफ़्त · Cloudflare ~$5/माह |
| **B. NVR + मीडिया सर्वर** | मंदिर के NVR से RTSP → सर्वर पर `ffmpeg`/MediaMTX → HLS | सर्वर का खर्च |
| **C. प्रोवाइडर** | स्थानीय CCTV/streaming विक्रेता से सीधे HLS URL लें | पैकेज पर निर्भर |

**YouTube Live से (मुफ़्त, सबसे तेज़ शुरुआत):**
1. YouTube Studio ▸ **Create ▸ Go Live** ▸ Stream key लें
2. कैमरा/NVR/OBS से उस key पर RTMP भेजें
3. Live शुरू होने पर वीडियो का लिंक मिलेगा — HLS के लिए `https://manifest.googlevideo.com/...` नहीं, बल्कि YouTube का **embed/HLS** इस्तेमाल नहीं होता; इसके लिए Cloudflare Stream या Mux बेहतर है (वहाँ सीधा `.m3u8` मिलता है)।

**Cloudflare Stream (सीधा HLS):** Stream ▸ Live Inputs ▸ Create → RTMP URL + key मिलते हैं → कैमरा वहाँ भेजें → Playback का **HLS manifest URL** कॉपी करें।

फिर `liveStreamUrl` में वह `.m3u8` URL डालें। ऐप में `LiveStreamView` (video_player) उसे चला देगा — प्ले/लूप/म्यूट सब तैयार है।

> सुझाव: स्ट्रीम को कम से कम 720p, 2–3 Mbps रखें — गाँव/कस्बे के नेटवर्क पर भी चलेगा।

---

## 3. AI सुरक्षा (YOLOv8)

ऐप हर घटना पर आपकी सर्विस को यह कॉल करता है:

```
POST {securityApiBaseUrl}/detect
Authorization: Bearer {securityApiKey}
{"cam": "03"}
```

जवाब में चाहिए:

```json
{
  "event": {
    "label": "अनधिकृत प्रवेश",
    "confidence": 97,
    "alert": true,
    "photo_url": "https://…/evd-1.jpg",
    "clip_url":  "https://…/evd-1.mp4"
  }
}
```

**सर्विस कहाँ चलाएँ:** Render / Railway / कोई GPU VPS (YOLOv8n CPU पर भी ~5–10 FPS देता है)।

ढाँचा (Python, सरल):
```python
# pip install fastapi uvicorn ultralytics opencv-python
from fastapi import FastAPI, Header
from ultralytics import YOLO
app = FastAPI(); model = YOLO("yolov8n.pt")

@app.post("/detect")
def detect(body: dict, authorization: str = Header(default="")):
    cam = body.get("cam", "01")
    frame = grab_frame(cam)              # NVR/RTSP से एक फ्रेम
    r = model(frame, verbose=False)[0]
    person = any(int(b.cls) == 0 and float(b.conf) > 0.5 for b in r.boxes)
    if not person:
        return {"event": None}
    photo, clip = save_evidence(frame, cam)   # 10 सेकंड क्लिप बनाएँ
    return {"event": {"label": "अनधिकृत प्रवेश", "confidence": 97,
                      "alert": True, "photo_url": photo, "clip_url": clip}}
```
साथ में **थाना अलर्ट** (SMS/E-mail) सर्वर से भेजें — ऐप सिर्फ़ नतीजा दिखाता है।

अभी API खाली है तो ऐप अपना सिमुलेशन चलाता है (डेमो में वही दिखता है)।

---

## 4. पुश नोटिफिकेशन (FCM — आरती/श्रृंगार)

Firebase प्रोजेक्ट बनने तक यह जान-बूझकर नहीं जोड़ा गया (बिना `google-services.json` बिल्ड फेल होता है)।

**कदम:**
1. [console.firebase.google.com](https://console.firebase.google.com) → Add project → `bsm-mandir`
2. **Add app ▸ Android** → package name: `org.bsmfoundation.bsm_mandir` → `google-services.json` डाउनलोड
3. वह फ़ाइल `android/app/google-services.json` में रखें
4. `pubspec.yaml` में जोड़ें:
   ```yaml
   firebase_core: ^4.0.0
   firebase_messaging: ^16.0.0
   ```
5. `android/settings.gradle.kts` में `id("com.google.gms.google-services") version "4.4.2" apply false`
   और `android/app/build.gradle.kts` के plugins में `id("com.google.gms.google-services")`
6. `lib/services/notifications_service.dart` में दिया कोड uncomment करें और `main.dart` में
   `await NotificationService.init();` जोड़ें
7. Console ▸ Cloud Messaging से टॉपिक `aarti_alerts` पर टेस्ट मैसेज भेजें

---

## 5. बैकएंड (अगला चरण)

जब बैकएंड बने (Node + Postgres), `apiBaseUrl` भर दें — तब ये काम सर्वर पर जाएँगे:
- भुगतान signature verify + रसीद PDF सर्वर से
- पूजा स्लॉट / धर्मशाला की सच्ची उपलब्धता (एक से ज़्यादा फ़ोन पर भी सही रहे)
- दान-खर्च का ऑडिट लॉग
- थाना अलर्ट का रिकॉर्ड

---

## जाँच की सूची

- [ ] `razorpayKeyId` भरा → दान करके टेस्ट कार्ड से भुगतान
- [ ] `liveStreamUrl` भरा → दर्शन टैब पर असली फ़ीड
- [ ] `securityApiBaseUrl` भरा → AI सुरक्षा में असली डिटेक्शन
- [ ] Firebase + `google-services.json` → आरती नोटिफिकेशन
- [ ] बैकएंड → `apiBaseUrl`

हर बदलाव के बाद: `flutter run` (फ़ोन पर) या push करके GitHub Actions से नया APK।
