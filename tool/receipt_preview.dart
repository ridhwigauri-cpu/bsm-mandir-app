// रसीद डिज़ाइन का झलक (डेवलपर के लिए) — dart run tool/receipt_preview.dart
import 'dart:io';

import '../lib/data/models.dart';
import '../lib/utils/docs.dart';

void main() {
  final big = Donation(
    id: 'DN-1', name: 'रमेश शर्मा', phone: '9876543210', cat: 'जीर्णोद्धार',
    amt: 11000, method: 'UPI', ts: DateTime(2026, 11, 27, 10, 30),
    receipt: '80G/2026-27/1001',
  );
  final small = Donation(
    id: 'DN-2', name: 'सुनीता देवी', phone: '9812345678', cat: 'अन्नदान',
    amt: 1100, method: 'UPI', ts: DateTime(2026, 11, 27, 11, 5),
    receipt: '80G/2026-27/1002',
  );
  File('preview_commendation.html').writeAsStringSync(receiptHtml(big));
  File('preview_receipt.html').writeAsStringSync(receiptHtml(small));
  stdout.writeln('preview HTML बन गए');
}
