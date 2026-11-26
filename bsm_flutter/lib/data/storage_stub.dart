/// वेब/टेस्ट के लिए — मेमोरी में ही रखता है (पेज बंद होने पर मिट जाता है)।
class Storage {
  static String? _memory;

  static Future<String?> read() async => _memory;

  static Future<void> write(String value) async {
    _memory = value;
  }
}
