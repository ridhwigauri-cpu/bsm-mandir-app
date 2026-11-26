CI फ़िक्स — 3 फ़ाइलें अपडेट करें (GitHub web UI)

1) lib/screens/darshan_screen.dart   ← darshan_screen.dart
2) lib/screens/security_screen.dart  ← security_screen.dart
3) test/widget_test.dart             ← widget_test.dart

कैसे: repo में उस फ़ोल्डर तक जाएँ (lib/screens या test) → "Add file ▸ Upload files"
→ यही नाम वाली फ़ाइल डालें → Commit changes.
दोनों स्क्रीन फ़ाइलें एक साथ (lib/screens में), फिर widget_test.dart (test में)।

बदलाव: दर्शन व सुरक्षा स्क्रीन के टाइमर अब dispose() में cancel होते हैं
(इसी वजह से 3 widget टेस्ट "pending timer" से फेल हो रहे थे), और टेस्ट में
pumpAndSettle की जगह तय pump() — क्योंकि स्क्रीन में चलती एनिमेशन हैं।
