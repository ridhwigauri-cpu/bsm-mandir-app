/// असली सेवाओं की सारी keys/URLs — सिर्फ़ यहीं बदलें, बाकी ऐप अपने आप उठा लेगा।
///
/// खाली छोड़ने पर वह सेवा **डेमो मोड** में चलती रहती है (ऐप टूटता नहीं)।
/// हर key कहाँ से मिलेगी — `docs/SETUP_SERVICES.md` देखें।
class AppConfig {
  const AppConfig._();

  // ── 1. भुगतान (Razorpay) ────────────────────────────────────────────
  // Dashboard ▸ Account & Settings ▸ API Keys ▸ Generate Key
  // शुरुआत में टेस्ट key (`rzp_test_...`) से जाँचें, फिर लाइव key डालें।
  static const String razorpayKeyId = '';
  // ⚠️ Key Secret कभी ऐप में न डालें — वह सर्वर पर रहता है (signature verify के लिए)।

  // ── 2. 24x7 लाइव दर्शन (HLS) ───────────────────────────────────────
  // कैमरा/NVR से RTMP → किसी स्ट्रीमिंग सर्विस से मिला `.m3u8` URL
  // उदाहरण: 'https://stream.bsmmandir.org/live/garbhagrih.m3u8'
  static const String liveStreamUrl = '';

  // ── 3. AI सुरक्षा (YOLOv8 सर्विस) ───────────────────────────────────
  // अपनी YOLOv8 सर्विस का base URL — POST {base}/detect
  // उदाहरण: 'https://ai.bsmmandir.org'
  static const String securityApiBaseUrl = '';
  static const String securityApiKey = '';

  // ── 4. बैकएंड API (रसीद, स्लॉट, भुगतान सत्यापन) ─────────────────────
  // अभी खाली — जब Node/Postgres बैकएंड तैयार हो तब भरें।
  static const String apiBaseUrl = '';

  // ── 5. पुश नोटिफिकेशन (FCM) ────────────────────────────────────────
  // Firebase प्रोजेक्ट बनने पर `android/app/google-services.json` डालें और
  // `docs/SETUP_SERVICES.md` के FCM हिस्से के हिसाब से pubspec में
  // firebase_core + firebase_messaging जोड़ें (बिना json के बिल्ड फेल होता है,
  // इसलिए यह डिपेंडेंसी अभी जान-बूझकर नहीं जोड़ी गई)।
  static const String fcmTopicAarti = 'aarti_alerts';

  static bool get hasRazorpay => razorpayKeyId.trim().isNotEmpty;
  static bool get hasLiveStream => liveStreamUrl.trim().isNotEmpty;
  static bool get hasSecurityApi => securityApiBaseUrl.trim().isNotEmpty;
  static bool get hasBackend => apiBaseUrl.trim().isNotEmpty;

  /// जब तक कोई असली सेवा कॉन्फ़िगर नहीं, ऐप डेमो डेटा से चलता है।
  static bool get isDemoMode =>
      !hasRazorpay && !hasLiveStream && !hasSecurityApi && !hasBackend;

  /// ऐप में दिखाने के लिए छोटा लेबल
  static String get modeLabel => isDemoMode ? 'डेमो मोड' : 'लाइव सेवाएँ';
}
