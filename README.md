# बाबा सिद्धनाथ मंदिर — Flutter ऐप

[![Flutter CI](https://github.com/ridhwigauri-cpu/bsm-mandir-app/actions/workflows/flutter.yml/badge.svg)](https://github.com/ridhwigauri-cpu/bsm-mandir-app/actions/workflows/flutter.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![License](https://img.shields.io/badge/license-MIT-green)

बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन की **डिजिटल प्रबंधन एवं AI सुरक्षा प्रणाली** — पूरी तरह Flutter में, हिंदी UI, मैरून-गोल्ड ब्रांडिंग।
तकनीकी पार्टनर: RGT Memorial Foundation · संस्करण 1.0

> बैज में `ridhwigauri-cpu/bsm-mandir-app` को अपने GitHub रिपॉज़िटरी नाम से बदल दें।

---

## ऐप में क्या है

| हिस्सा | स्क्रीन |
|---|---|
| **भक्त ऐप** | होम · दान (80G रसीद) · 24x7 लाइव दर्शन · पूजा/VIP पास · धर्मशाला व अखंड कीर्तन |
| **एडमिन डैशबोर्ड** | कुल दान/बैंक/नकद · चालू परियोजनाएँ · स्टाफ व वेतन · माह-वार लेखा · लाइव ऑक्यूपेंसी · रसीदें — **डेमो पिन `1088`** |
| **AI सुरक्षा** | 6 कैमरा ग्रिड, YOLOv8 स्टाइल डिटेक्शन बॉक्स, घटना सिमुलेशन, 10-सेकंड क्लिप साक्ष्य, थाना SMS/E-mail लॉग |

हेडर के दो आइकन बटन (🛡 सुरक्षा, 🔒 एडमिन) से हिस्से बदलते हैं।
डेटा फ़ोन के कैश में JSON के रूप में रहता है — ऐप बंद करने पर भी दान, बुकिंग और अलर्ट बने रहते हैं।

---

## चलाने का तरीका

```bash
flutter pub get
flutter run                  # जुड़े फ़ोन/एमुलेटर पर
flutter run -d chrome        # ब्राउज़र में झलक
```

**APK बनाने के लिए:**

```bash
flutter build apk --release            # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release      # Play Store के लिए .aab
```

रिलीज़ के लिए अपनी कीस्टोर बनाकर `android/app/build.gradle.kts` में `signingConfig` बदलें:

```bash
keytool -genkey -v -keystore bsm-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias bsm
```

**वेब बिल्ड (GitHub Pages पर भी चला सकते हैं):**

```bash
flutter build web --release --base-href /REPO_NAME/
```

---

## फ़ोल्डर संरचना

```
lib/
├── main.dart                    ऐप एंट्री (AppScope + MaterialApp)
├── app.dart                     हेडर, बॉटम टैब, व्यू स्विचिंग (RootShell)
├── theme/
│   ├── app_colors.dart          मैरून + गोल्ड पैलेट
│   └── app_theme.dart           Material3 थीम + टेक्स्ट स्टाइल
├── data/
│   ├── models.dart              Donation, PujaPass, RoomBooking, SecurityAlert…
│   ├── base_data.dart           वीडियो के आँकड़े (दान, परियोजना, स्टाफ, कमरे, कैमरा)
│   ├── app_state.dart           ChangeNotifier + InheritedNotifier (AppScope)
│   ├── storage.dart             प्लेटफ़ॉर्म के हिसाब से स्टोरेज चुनने वाला शिम
│   ├── storage_io.dart          फ़ोन: फ़ाइल में JSON
│   └── storage_stub.dart        वेब/टेस्ट: मेमोरी
├── utils/
│   ├── format.dart              ₹25,00,000 (भारतीय गिनती), तारीख़ें, राशि शब्दों में
│   ├── qr.dart                  डेमो QR मैट्रिक्स
│   └── docs.dart                80G रसीद / पास का HTML + क्लिपबोर्ड टेक्स्ट
├── widgets/common.dart          कार्ड, बटन, चिप ग्रिड, इनपुट, QR, बॉटम शीट, टोस्ट
└── screens/                     8 स्क्रीन (होम, दान, दर्शन, पूजा, धर्मशाला, एडमिन लॉगिन, एडमिन, AI सुरक्षा)

test/
├── format_test.dart             ₹ फ़ॉर्मेट, तारीख़ें, राशि शब्द, QR
└── widget_test.dart             होम / दान / एडमिन लॉगिन-डैशबोर्ड रेंडर टेस्ट

tool/logic_check.dart            शुद्ध Dart जाँच (flutter की ज़रूरत नहीं): dart run tool/logic_check.dart
```

**ज़ीरो बाहरी पैकेज** — `pubspec.yaml` में सिर्फ़ Flutter SDK है, इसलिए `flutter pub get` कभी वर्ज़न टकराव नहीं देगा।

---

## कहाँ क्या बदलें

| काम | फ़ाइल |
|---|---|
| फाउंडेशन के असली आँकड़े (दान, परियोजना, स्टाफ, कमरे, कैमरा) | `lib/data/base_data.dart` |
| 80G रसीद / पास का डिज़ाइन | `lib/utils/docs.dart` |
| असली पेमेंट गेटवे (Razorpay/PhonePe/PayU) | `lib/screens/daan_screen.dart` → `_openGateway()` का `confirm()` |
| लाइव दर्शन HLS स्ट्रीम | `lib/screens/darshan_screen.dart` → `video_player`/`better_player` जोड़ें |
| YOLOv8 API + थाना SMS/E-mail | `lib/screens/security_screen.dart` → `_trigger()` |
| असली QR (सर्वर से हस्ताक्षरित) | `lib/widgets/common.dart` → `QrView` (या `qr_flutter` पैकेज) |
| Aadhaar e-KYC | `lib/screens/dharamshala_screen.dart` → `_verify()` |
| एडमिन पिन | `lib/screens/admin_login_screen.dart` (डेमो `1088`) |
| ऐप का नाम / पैकेज | `pubspec.yaml`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml` |

### आगे क्या जोड़ें (ज़रूरत के हिसाब से)

```bash
flutter pub add shared_preferences   # पक्का स्टोरेज (अभी फ़ाइल/मेमोरी)
flutter pub add printing             # रसीद/पास का PDF (HTML तैयार है)
flutter pub add share_plus           # रसीद WhatsApp पर भेजना
flutter pub add video_player         # 24x7 लाइव दर्शन (HLS)
flutter pub add qr_flutter           # असली QR
flutter pub add http dio             # बैकएंड API
flutter pub add firebase_messaging   # आरती/श्रृंगार पुश नोटिफिकेशन
```

---

## प्रोडक्शन चेकलिस्ट

- [ ] बैकएंड API (Node/Postgres) — दान, स्लॉट, धर्मशाला, रसीद, ऑडिट लॉग
- [ ] पेमेंट गेटवे + सर्वर वेबहुक → रसीद स्वतः बने
- [ ] असली लॉगिन (OTP + डिवाइस बाइंडिंग) — अभी डेमो पिन
- [ ] मंदिर कैमरे → RTMP → HLS → ऐप में लाइव
- [ ] YOLOv8 सर्विस + FCM पुश + थाना SMS (DLT टेम्पलेट)
- [ ] Aadhaar सत्यापन UIDAI-अनुमत प्रदाता से (या दस्तावेज़ अपलोड)
- [ ] Play Store: कीस्टोर, गोपनीयता नीति, डेटा सेफ़्टी फ़ॉर्म

---

## इस बिल्ड की जाँच

- `dart analyze` → **No issues found** (सभी 17 Dart फ़ाइलें, strict-casts के साथ)।
- `dart run tool/logic_check.dart` → ₹ फ़ॉर्मेट, तारीख़ें, राशि शब्द, QR, रसीद/पास HTML और JSON राउंडट्रिप — **सभी जाँच पास**।
- `test/` में widget टेस्ट मौजूद हैं — अपनी मशीन पर `flutter test` से चलाएँ (इस सैंडबॉक्स में Flutter टूल का नेटवर्क ब्लॉक था)।
- APK बिल्ड यहाँ नहीं चला — `flutter build apk` आपकी मशीन/CI पर चलेगा (GitHub Actions वर्कफ़्लो शामिल है)।

## डेमो प्रकृति

भुगतान, आधार, वीडियो स्ट्रीम और AI डिटेक्शन **सिम्युलेटेड** हैं — हर जगह कोड में टिप्पणी है कि असली सेवा कहाँ जुड़ेगी।
