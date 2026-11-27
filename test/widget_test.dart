import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsm_mandir/app.dart';
import 'package:bsm_mandir/data/app_state.dart';
import 'package:bsm_mandir/theme/app_theme.dart';

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

  testWidgets('एडमिन लॉगिन और डैशबोर्ड', (tester) async {
    await tester.pumpWidget(_wrap(const RootShell()));
    await _settle(tester);

    // हेडर का लॉक आइकन
    await tester.tap(find.byIcon(Icons.lock_outline_rounded));
    await _settle(tester);
    expect(find.text('एडमिन लॉगिन — ट्रस्ट प्रबंधक'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1088');
    await tester.tap(find.text('लॉगिन करें'));
    await _settle(tester);

    expect(find.text('एडमिन डैशबोर्ड — फाउंडेशन प्रबंधन'), findsOneWidget);
    expect(find.text('₹25,00,000'), findsWidgets);
  });

  testWidgets('परिचय टैब में फाउंडेशन का इतिहास दिखता है', (tester) async {
    await tester.pumpWidget(_wrap(const RootShell()));
    await _settle(tester);

    await tester.tap(find.text('परिचय'));
    await _settle(tester);

    expect(find.text('हमारी कहानी'), findsOneWidget);
    expect(find.text('सेवा-इतिहास (क्रमवार)'), findsOneWidget);
    expect(find.textContaining('25 जून 2026'), findsWidgets);
  });
}
