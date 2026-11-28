import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bsm_mandir/services/api_client.dart';

/// नकली सर्वर — असली Neon बैकएंड जैसे ही जवाब देता है
MockClient fakeServer({Map<String, dynamic>? lastBody, List<String>? calls}) {
  return MockClient((request) async {
    calls?.add('${request.method} ${request.url.path}');
    if (lastBody != null && request.body.isNotEmpty) {
      lastBody.addAll(jsonDecode(request.body) as Map<String, dynamic>);
    }
    final path = request.url.path;

    if (path == '/health') {
      return http.Response(jsonEncode({'ok': true}), 200,
          headers: {'content-type': 'application/json'});
    }
    if (path == '/api/auth/login') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (body['pin'] == '1088') {
        return http.Response(jsonEncode({'token': 'tok123'}), 200);
      }
      return http.Response(jsonEncode({'error': 'गलत पिन'}), 401);
    }
    if (path == '/api/donations/order') {
      return http.Response(
        jsonEncode({'donationId': 7, 'orderId': 'order_x', 'amount': 1100, 'demo': true}),
        201,
      );
    }
    if (path == '/api/donations/verify') {
      return http.Response(
        jsonEncode({
          'status': 'paid',
          'receipt': '80G/2026-27/1001',
          'receiptPdfUrl': '/api/reports/receipt/7.pdf?token=abc',
          'announcement': 'जय बाबा सिद्धनाथ! श्री रमेश शर्मा जी ने ₹1,100 का दान दिया।',
        }),
        200,
      );
    }
    if (path == '/api/puja/slots') {
      return http.Response(
        jsonEncode({
          'date': '2026-12-01',
          'capacity': 6,
          'slots': [
            {'slot': '09:00 – 10:00', 'taken': 6, 'left': 0, 'full': true},
            {'slot': '11:00 – 12:00', 'taken': 2, 'left': 4, 'full': false},
          ],
        }),
        200,
      );
    }
    if (path == '/api/rooms') {
      return http.Response(
        jsonEncode({
          'date': '2026-12-01',
          'rooms': [
            {'id': 'R1', 'name': 'कमरा 1', 'capacity': 2, 'available': true},
            {'id': 'R2', 'name': 'कमरा 2', 'capacity': 2, 'available': false},
          ],
          'kirtan': [{'slot': '09:00 – 11:00', 'taken': 1, 'left': 3, 'full': false}],
        }),
        200,
      );
    }
    if (path == '/api/admin/public/summary') {
      return http.Response(
        jsonEncode({
          'donations': {'total_paid': 251000, 'count_paid': 42},
          'rooms': {'total': 6, 'occupied': 2},
        }),
        200,
      );
    }
    return http.Response(jsonEncode({'error': 'रास्ता नहीं मिला'}), 404);
  });
}

void main() {
  test('बैकएंड नहीं जुड़ा → enabled=false, कुछ नहीं टूटता', () async {
    final api = ApiClient(baseUrl: '', httpClient: fakeServer());
    expect(api.enabled, isFalse);
    expect(await api.health(), isFalse);
    expect(() => api.publicSummary(), throwsA(isA<ApiException>()));
  });

  test('health ठीक है', () async {
    final api = ApiClient(baseUrl: 'https://neon.test', httpClient: fakeServer());
    expect(api.enabled, isTrue);
    expect(await api.health(), isTrue);
  });

  test('लॉगिन: गलत पिन → ApiException, सही पिन → token', () async {
    final api = ApiClient(baseUrl: 'https://neon.test', httpClient: fakeServer());
    await expectLater(api.login('0000'), throwsA(isA<ApiException>()));
    final token = await api.login('1088');
    expect(token, 'tok123');
    expect(api.isLoggedIn, isTrue);
  });

  test('दान: ऑर्डर → सत्यापन → रसीद नंबर', () async {
    final api = ApiClient(baseUrl: 'https://neon.test', httpClient: fakeServer());
    final order = await api.createDonationOrder(
      name: 'रमेश शर्मा',
      phone: '9876543210',
      category: 'जीर्णोद्धार',
      amount: 1100,
    );
    expect(order.donationId, 7);
    expect(order.orderId, 'order_x');

    final receipt = await api.verifyDonation(
      donationId: order.donationId,
      orderId: order.orderId,
      paymentId: 'pay_1',
      signature: 'sig',
    );
    expect(receipt.isPaid, isTrue);
    expect(receipt.receipt, '80G/2026-27/1001');
    expect(receipt.receiptPdfUrl, contains('token='));
    expect(receipt.announcement, contains('₹1,100'));
  });

  test('पूजा स्लॉट: भरा स्लॉट full=true', () async {
    final api = ApiClient(baseUrl: 'https://neon.test', httpClient: fakeServer());
    final slots = await api.pujaSlots(date: '2026-12-01');
    expect(slots.length, 2);
    expect(slots.first.full, isTrue);
    expect(slots.last.left, 4);
  });

  test('धर्मशाला: उपलब्ध कमरे गिने जाते हैं', () async {
    final api = ApiClient(baseUrl: 'https://neon.test', httpClient: fakeServer());
    final rooms = await api.rooms();
    expect(rooms.rooms.length, 2);
    expect(rooms.availableCount, 1);
    expect(rooms.kirtan.first.left, 3);
  });

  test('सार्वजनिक सारांश: असली जोड़', () async {
    final api = ApiClient(baseUrl: 'https://neon.test', httpClient: fakeServer());
    final s = await api.publicSummary();
    expect(s.totalPaid, 251000);
    expect(s.countPaid, 42);
    expect(s.roomsOccupied, 2);
  });

  test('नेटवर्क टूटा → ApiException (ऐप नहीं टूटता)', () async {
    final api = ApiClient(
      baseUrl: 'https://neon.test',
      httpClient: MockClient((_) async => throw Exception('offline')),
    );
    await expectLater(api.publicSummary(), throwsA(isA<ApiException>()));
  });
}
