import 'dart:async';

import '../config/app_config.dart';

/// पुश नोटिफिकेशन (आरती / श्रृंगार अलर्ट) — FCM के लिए तैयार ढाँचा।
///
/// अभी `firebase_messaging` जोड़ा नहीं गया है, क्योंकि `google-services.json`
/// के बिना Android बिल्ड फेल होता है। Firebase प्रोजेक्ट बनने पर
/// `docs/SETUP_SERVICES.md` के FCM हिस्से के 7 कदम पूरे करें, फिर नीचे दिया
/// कोड uncomment कर दें — बाकी ऐप को छूने की ज़रूरत नहीं।
class NotificationService {
  const NotificationService._();

  /// ऐप शुरू होते समय एक बार — टॉपिक सब्सक्राइब + अनुमति
  static Future<void> init() async {
    if (!AppConfig.hasBackend && AppConfig.isDemoMode) {
      // डेमो मोड — कुछ नहीं करना
      return;
    }
    await _initFcm();
  }

  static Future<void> _initFcm() async {
    // ── Firebase जोड़ने के बाद यह हिस्सा uncomment करें ──────────────
    //
    // await Firebase.initializeApp();
    // final messaging = FirebaseMessaging.instance;
    //
    // // अनुमति (Android 13+ पर ज़रूरी)
    // await messaging.requestPermission(alert: true, badge: true, sound: true);
    //
    // // आरती अलर्ट टॉपिक
    // await messaging.subscribeToTopic(AppConfig.fcmTopicAarti);
    //
    // // फ़ोरग्राउंड में आने वाला मैसेज
    // FirebaseMessaging.onMessage.listen((msg) {
    //   // यहाँ चाहें तो local notification दिखाएँ
    // });
    //
    // // ऐप बंद/बैकग्राउंड से खुलने पर
    // FirebaseMessaging.onMessageOpenedApp.listen((msg) {
    //   // सीधे दर्शन टैब खोलें
    // });
  }

  /// आरती अलर्ट चालू/बंद
  static Future<void> setAartiAlerts(bool on) async {
    if (on) {
      await _subscribe();
    } else {
      await _unsubscribe();
    }
  }

  static Future<void> _subscribe() async {
    // await FirebaseMessaging.instance.subscribeToTopic(AppConfig.fcmTopicAarti);
  }

  static Future<void> _unsubscribe() async {
    // await FirebaseMessaging.instance.unsubscribeFromTopic(AppConfig.fcmTopicAarti);
  }

  /// डेमो में सिर्फ़ नकली रिमाइंडर
  static Future<void> demoReminder() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
