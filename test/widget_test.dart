import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsm_mandir/app.dart';
import 'package:bsm_mandir/data/app_state.dart';
import 'package:bsm_mandir/data/foundation_info.dart';
import 'package:bsm_mandir/data/models.dart';
import 'package:bsm_mandir/theme/app_theme.dart';
import 'package:bsm_mandir/widgets/donation_certificate.dart';
import 'package:bsm_mandir/widgets/donation_qr_card.dart';

Widget _wrap(Widget child) {
  return AppScope(
    state: AppState(),
    child: MaterialApp(theme: AppTheme.build(), home: child),
  );
}

/// स्क्रीन में चलती एनिमेशन/टाइमर हैं, इसलिए `pumpAndSettle` की जगह
/// तय समय के लिए `pump` करते हैं — वरना टेस्ट कभी "settle" नहीं होता।
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('होम स्क्रीन पर ब्रांड और कुल दान दिखता है', (tester) async {
    await tester.pumpWidget(_wrap(const RootShell()));
    await _settle(tester);

    expect(find.text('बाबा सिद्धनाथ मंदिर'), findsOneWidget);
    expect(find.text('जय बाबा सिद्धनाथ'), findsOneWidget);
    expect(find.text('₹25,00,000'), findsOneWidget);
  });

  testWidgets('दान टैब खुलता है और गलत इनपुट रुकता है', (tester) async {
    await tester.pumpWidget(_wrap(const RootShell()));
    await _settle(tester);

    await tester.tap(find.text('दान'));
    await _settle(tester);

    expect(find.text('ऑनलाइन दान'), findsOneWidget);
    expect(find.text('UPI / कार्ड से भुगतान करें'), findsOneWidget);

    // नाम खाली है — भुगतान शीट नहीं खुलनी चाहिए
    await tester.tap(find.text('UPI / कार्ड से भुगतान करें'));
    await _settle(tester);
    expect(find.text('पेमेंट गेटवे'), findsNothing);
  });

  testWidgets('परिचय टैब खुलता है (फाउंडेशन की कहानी)', (tester) async {
    await tester.pumpWidget(_wrap(const RootShell()));
    await _settle(tester);

    await tester.tap(find.text('परिचय'));
    await _settle(tester);

    // हीरो हिस्सा स्क्रीन के ऊपर ही है
    expect(find.text('हमारी कहानी'), findsOneWidget);
  });

  testWidgets('दान QR कार्ड — UPI व बैंक विवरण', (tester) async {
    await tester.pumpWidget(
      _wrap(const SingleChildScrollView(child: DonationQrCard())),
    );
    await _settle(tester);

    expect(find.text('QR से सीधे दान करें'), findsOneWidget);
    expect(find.text('6203051369m@pnb'), findsOneWidget);
    expect(find.text('1573002100004142'), findsOneWidget);
    expect(find.text('PUNB157300'), findsOneWidget);
    expect(find.text('कॉपी'), findsWidgets);
  });

  testWidgets('दान प्रशस्ति पत्र — CIN, PAN व राशि', (tester) async {
    final donation = Donation(
      id: 'DN-1',
      name: 'रमेश शर्मा',
      phone: '9876543210',
      cat: 'जीर्णोद्धार',
      amt: 11000,
      method: 'UPI',
      ts: DateTime(2026, 11, 27, 10, 30),
      receipt: '80G/2026-27/1001',
    );
    await tester.pumpWidget(
      _wrap(SingleChildScrollView(child: DonationCertificate(donation: donation))),
    );
    await _settle(tester);

    expect(find.text('दान प्रशस्ति पत्र'), findsOneWidget);
    expect(find.text('Certificate of Commendation'), findsOneWidget);
    expect(find.textContaining('रमेश शर्मा', findRichText: true), findsWidgets);
    expect(find.text('₹11,000'), findsOneWidget);
    expect(find.textContaining('U94910BR2026NPL085916'), findsWidgets);
  });

  test('पंजीयन विवरण — CIN, PAN, TAN, Section 8', () {
    expect(FoundationInfo.cin, 'U94910BR2026NPL085916');
    expect(FoundationInfo.pan, 'AAOCB8762B');
    expect(FoundationInfo.tan, 'PTNB10218F');
    expect(FoundationInfo.section8Licence, '187252');
    expect(FoundationInfo.registrationDocs.length, 4);
    expect(FoundationInfo.notices.length, 2);
    expect(FoundationInfo.registration.any((r) => r.$2.contains('U94910BR2026NPL085916')), isTrue);
  });
}
