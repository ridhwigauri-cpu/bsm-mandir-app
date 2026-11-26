import 'dart:io';

/// फ़ोन पर ऐप के कैश फ़ोल्डर में JSON रखता है — प्लगइन की ज़रूरत नहीं।
/// प्रोडक्शन में इसे `shared_preferences` या SQLite से बदल सकते हैं।
class Storage {
  static File get _file => File('${Directory.systemTemp.path}/bsm_mandir_state.json');

  static Future<String?> read() async {
    try {
      final f = _file;
      if (!await f.exists()) return null;
      return await f.readAsString();
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String value) async {
    try {
      await _file.writeAsString(value, flush: true);
    } catch (_) {
      // स्टोरेज न हो तो भी ऐप चलता रहे
    }
  }
}
