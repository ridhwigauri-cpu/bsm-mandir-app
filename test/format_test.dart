import 'package:flutter_test/flutter_test.dart';
import 'package:bsm_mandir/utils/format.dart';
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
}
