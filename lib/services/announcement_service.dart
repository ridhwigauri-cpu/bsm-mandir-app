import 'dart:convert';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../utils/format.dart';

/// दान की घोषणा — (1) दाता के फ़ोन पर आवाज़, (2) मंदिर परिसर के PA सिस्टम पर
///
/// फ़ोन: `flutter_tts` से हिंदी में बोला जाता है (इंटरनेट की ज़रूरत नहीं)।
/// परिसर: `AppConfig.paSystemUrl` भरने पर वहाँ POST जाता है —
///   { "name": "...", "amount": 1100, "text": "..." }
/// उस URL पर मंदिर का PA सर्वर (Raspberry Pi / PC + स्पीकर) घोषणा बजा देगा।
class AnnouncementService {
  const AnnouncementService._();

  static FlutterTts? _tts;
  static bool _ready = false;

  static Future<FlutterTts?> _engine() async {
    if (_tts != null) return _tts;
    try {
      final tts = FlutterTts();
      await tts.setLanguage('hi-IN');
      await tts.setSpeechRate(0.46);
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);
      await tts.awaitSpeakCompletion(true);
      _tts = tts;
      _ready = true;
      return tts;
    } catch (_) {
      return null;
    }
  }

  /// ऐप खुलते ही — "जय बाबा सिद्धनाथ"
  static Future<void> welcome() async {
    final tts = await _engine();
    if (tts == null) return;
    try {
      await tts.speak('जय बाबा सिद्धनाथ');
    } catch (_) {}
  }

  /// दान होने पर घोषणा
  static Future<void> announceDonation({
    required String name,
    required int amount,
    String category = '',
  }) async {
    final safeName = name.trim().isEmpty ? 'एक श्रद्धालु' : name.trim();
    final text = 'जय बाबा सिद्धनाथ! श्री $safeName जी ने '
        '${inr(amount)} का दान दिया। बाबा सिद्धनाथ आपका कल्याण करें।';

    // 1. फ़ोन पर
    final tts = await _engine();
    if (tts != null) {
      try {
        await tts.speak(text);
      } catch (_) {}
    }

    // 2. मंदिर परिसर के PA सिस्टम पर (एक साथ)
    await sendToTemplePa(name: safeName, amount: amount, text: text, category: category);
  }

  /// मंदिर के PA सर्वर को घोषणा भेजें
  static Future<bool> sendToTemplePa({
    required String name,
    required int amount,
    required String text,
    String category = '',
  }) async {
    if (!AppConfig.hasPaSystem) return false;
    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.paSystemUrl}/announce'),
            headers: {
              'Content-Type': 'application/json',
              if (AppConfig.paSystemKey.isNotEmpty)
                'Authorization': 'Bearer ${AppConfig.paSystemKey}',
            },
            body: jsonEncode({
              'name': name,
              'amount': amount,
              'category': category,
              'text': text,
              'ts': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// ज़रूरत पड़े तो बंद करें
  static Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  static bool get isPhoneVoiceReady => _ready;
}
