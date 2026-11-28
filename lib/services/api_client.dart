import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../data/api_models.dart';

/// API की गड़बड़ी — संदेश हिंदी में, ऐप में सीधे दिखाया जा सकता है
class ApiException implements Exception {
  ApiException(this.message, {this.status = 0});

  final String message;
  final int status;

  @override
  String toString() => message;
}

/// Neon बैकएंड (Lambda / Neon Functions) से बात करने वाला क्लाइंट
///
/// - `AppConfig.apiBaseUrl` खाली हो ⇒ `enabled == false` और ऐप पूरी तरह
///   डेमो मोड में चलता रहता है (कुछ नहीं टूटता)।
/// - हर कॉल में timeout है; नेटवर्क गिरे तो `ApiException` फेंकता है जिसे
///   स्क्रीन पकड़कर डेमो डेटा दिखा देती है।
class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 12),
  })  : baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).trim().replaceAll(RegExp(r'/+$'), ''),
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  String? _token;

  bool get enabled => baseUrl.isNotEmpty;
  bool get isLoggedIn => _token != null;

  /// ऐप में एक ही क्लाइंट (Neon backend के लिए)
  static ApiClient instance = ApiClient();

  Map<String, String> _headers({bool auth = false}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (auth && _token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
    Map<String, String>? query,
  }) async {
    if (!enabled) throw ApiException('बैकएंड सेट नहीं है (AppConfig.apiBaseUrl खाली है)');

    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)..headers.addAll(_headers(auth: auth));
    if (body != null) request.body = jsonEncode(body);

    http.Response res;
    try {
      final streamed = await _http.send(request).timeout(timeout);
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('सर्वर से जवाब नहीं आया — इंटरनेट जाँचें');
    } catch (e) {
      throw ApiException('सर्वर से जुड़ नहीं पाए: $e');
    }

    dynamic json;
    try {
      // सर्वर charset न भेजे तो भी हिंदी ठीक पढ़ी जाए — बाइट्स से UTF-8
      final text = res.bodyBytes.isEmpty ? '' : utf8.decode(res.bodyBytes, allowMalformed: true);
      json = text.isEmpty ? null : jsonDecode(text);
    } catch (_) {
      json = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return json;

    final msg = (json is Map && json['error'] != null)
        ? json['error'].toString()
        : 'सर्वर त्रुटि (${res.statusCode})';
    throw ApiException(msg, status: res.statusCode);
  }

  /* ---------------- स्वास्थ्य ---------------- */

  Future<bool> health() async {
    try {
      final j = await _send('GET', '/health');
      return j is Map && j['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /* ---------------- एडमिन लॉगिन ---------------- */

  Future<String> login(String pin) async {
    final j = await _send('POST', '/api/auth/login', body: {'pin': pin});
    final token = (j is Map ? j['token'] : null)?.toString() ?? '';
    if (token.isEmpty) throw ApiException('लॉगिन नहीं हो सका');
    _token = token;
    return token;
  }

  void logout() => _token = null;

  /// होम स्क्रीन के लिए सार्वजनिक जोड़ (बिना लॉगिन)
  Future<AdminSummary> publicSummary() async {
    final j = await _send('GET', '/api/admin/public/summary');
    return AdminSummary.fromJson(j as Map<String, dynamic>);
  }

  Future<AdminSummary> adminSummary() async {
    final j = await _send('GET', '/api/admin/summary', auth: true);
    return AdminSummary.fromJson(j as Map<String, dynamic>);
  }

  /* ---------------- दान ---------------- */

  Future<DonationOrder> createDonationOrder({
    required String name,
    required String phone,
    required String category,
    required int amount,
  }) async {
    final j = await _send('POST', '/api/donations/order', body: {
      'name': name,
      'phone': phone,
      'category': category,
      'amount': amount,
    });
    return DonationOrder.fromJson(j as Map<String, dynamic>);
  }

  Future<DonationReceipt> verifyDonation({
    required int donationId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final j = await _send('POST', '/api/donations/verify', body: {
      'donationId': donationId,
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
    });
    return DonationReceipt.fromJson(j as Map<String, dynamic>);
  }

  /// QR / बैंक से आया दान दर्ज करें (UTR के साथ)
  Future<void> recordManualDonation({
    required String name,
    required String phone,
    required String category,
    required int amount,
    required String method, // UPI_QR | BANK | CASH
    String utr = '',
  }) async {
    await _send('POST', '/api/donations/manual', body: {
      'name': name,
      'phone': phone,
      'category': category,
      'amount': amount,
      'method': method,
      'utr': utr,
    });
  }

  /* ---------------- पूजा ---------------- */

  Future<List<PujaSlotInfo>> pujaSlots({String? date}) async {
    final j = await _send('GET', '/api/puja/slots', query: date == null ? null : {'date': date});
    final list = (j is Map ? j['slots'] : null) as List? ?? const [];
    return list.map((e) => PujaSlotInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> bookPuja({
    required String name,
    required String phone,
    required String date,
    required String slot,
    required String type,
  }) async {
    final j = await _send('POST', '/api/puja', body: {
      'name': name,
      'phone': phone,
      'date': date,
      'slot': slot,
      'type': type,
    });
    return (j is Map ? j : const {}) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPujaPass(String passId) async {
    final j = await _send('POST', '/api/puja/verify', body: {'passId': passId});
    return (j is Map ? j : const {}) as Map<String, dynamic>;
  }

  /* ---------------- धर्मशाला ---------------- */

  Future<RoomsState> rooms({String? date}) async {
    final j = await _send('GET', '/api/rooms', query: date == null ? null : {'date': date});
    return RoomsState.fromJson(j as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> bookRoom({
    required String name,
    required String phone,
    required String aadhaarLast4,
    required String roomId,
    required String date,
    String kirtan = '',
  }) async {
    final j = await _send('POST', '/api/rooms/book', body: {
      'name': name,
      'phone': phone,
      'aadhaarLast4': aadhaarLast4,
      'roomId': roomId,
      'date': date,
      'kirtan': kirtan,
    });
    return (j is Map ? j : const {}) as Map<String, dynamic>;
  }

  /* ---------------- घोषणा (मंदिर PA) ---------------- */

  /// घोषणा कतार में डालें (एडमिन) — भुगतान पर सर्वर खुद भी डाल देता है
  Future<void> queueAnnouncement({required String name, int amount = 0, String? text}) async {
    await _send('POST', '/api/announcements', auth: true, body: {
      'name': name,
      if (amount > 0) 'amount': amount,
      if (text != null && text.isNotEmpty) 'text': text,
    });
  }

  /* ---------------- रिपोर्ट ---------------- */

  /// 80G रजिस्टर का Excel/PDF — लौटता है डाउनलोड लिंक (S3/Neon bucket)
  Future<String> reportUrl({
    required String kind, // register.xlsx | register.pdf | lekha.xlsx
    String? from,
    String? to,
  }) async {
    final j = await _send('GET', '/api/reports/$kind', auth: true, query: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    if (j is Map && j['url'] != null) return j['url'].toString();
    // S3 सेट नहीं है तो सर्वर सीधे फ़ाइल भेजता है — तब लिंक नहीं मिलेगा
    throw ApiException('रिपोर्ट लिंक नहीं मिला');
  }

  void dispose() => _http.close();
}
