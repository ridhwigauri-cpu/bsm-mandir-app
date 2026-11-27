import 'package:flutter_test/flutter_test.dart';
import 'package:bsm_mandir/utils/format.dart';
import 'package:bsm_mandir/data/models.dart';
import 'package:bsm_mandir/utils/docs.dart';
import 'package:bsm_mandir/utils/qr.dart';

void main() {
  group('रुपये का भारतीय फ़ॉर्मेट', () {
    test('लाख व करोड़ की गिनती', () {
      expect(inr(2500000), '₹25,00,000');
      expect(inr(2150000), '₹21,50,000');
      expect(inr(980000), '₹9,80,000');
      expect(inr(1310000), '₹13,10,000');
      expect(inr(1100), '₹1,100');
      expect(inr(999), '₹999');
      expect(inr(0), '₹0');
    });
  });

  group('तारीख़ें', () {
    test('dateKey और dateLabel', () {
      expect(dateKey(DateTime(2026, 11, 25)), '2026-11-25');
      expect(dateLabel('2026-11-25'), '25 नवंबर 2026');
    });

    test('अगली तारीख़ें', () {
      final dates = nextDates(5);
      expect(dates.length, 5);
      expect(dates.first.top, 'आज');
      expect(dates[1].top, 'कल');
    });
  });

  group('राशि शब्दों में', () {
    test('amountWords', () {
      expect(amountWords(1100), 'एक हज़ार एक सौ रुपये मात्र');
      expect(amountWords(2100), 'दो हज़ार एक सौ रुपये मात्र');
      expect(amountWords(5100), 'पाँच हज़ार एक सौ रुपये मात्र');
    });
  });

  group('QR मैट्रिक्स', () {
    test('25x25 और वही पैटर्न', () {
      final a = qrMatrix('BSM-PJ-ABCDE');
      final b = qrMatrix('BSM-PJ-ABCDE');
      expect(a.length, 25);
      expect(a[0].length, 25);
      expect(a, b);
      expect(qrMatrix('X')[0].sublist(0, 3), [true, true, true]);
    });
  });

  test('पास आईडी यूनिक बनती है', () {
    final a = newId('BSM-PJ');
    final b = newId('BSM-PJ');
    expect(a.startsWith('BSM-PJ-'), isTrue);
    expect(a.length, 'BSM-PJ-'.length + 5);
    expect(a == b, isFalse);
  });

  test('रसीद डिज़ाइन — ₹5,000 से अधिक पर प्रशस्ति पत्र', () {
    final big = Donation(
      id: 'DN-1', name: 'रमेश शर्मा', phone: '9876543210', cat: 'जीर्णोद्धार',
      amt: 11000, method: 'UPI', ts: DateTime(2026, 11, 27), receipt: '80G/2026-27/1001',
    );
    final html = receiptHtml(big);
    expect(html.contains('दान प्रशस्ति पत्र'), isTrue);
    expect(html.contains('Certificate of Commendation'), isTrue);
    expect(html.contains('U94910BR2026NPL085916'), isTrue);
    expect(html.contains('₹11,000'), isTrue);
    expect(receiptText(big).contains('दान प्रशस्ति पत्र'), isTrue);

    final small = Donation(
      id: 'DN-2', name: 'सुनीता देवी', phone: '9812345678', cat: 'अन्नदान',
      amt: 1100, method: 'UPI', ts: DateTime(2026, 11, 27), receipt: '80G/2026-27/1002',
    );
    expect(receiptHtml(small).contains('दान रसीद'), isTrue);
    expect(receiptHtml(small).contains('Certificate of Commendation'), isFalse);
  });
}
