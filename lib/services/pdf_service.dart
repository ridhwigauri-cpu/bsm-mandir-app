import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../data/models.dart';
import '../utils/docs.dart';

/// रसीद/पास का PDF — `printing` पैकेज से।
///
/// HTML को नेटिव WebView से PDF में बदला जाता है (Devanagari सही रेंडर होती है),
/// इसलिए अलग फ़ॉन्ट फ़ाइल की ज़रूरत नहीं। तस्वीरें base64 में इनलाइन होती हैं।
class PdfService {
  const PdfService._();

  /// PDF बनाकर सिस्टम के "सेव / प्रिंट" डायलॉग में खोलें
  /// (Android पर "Save as PDF" चुनकर फ़ाइल डाउनलोड हो जाती है)
  static Future<bool> saveReceipt(Donation d) async {
    try {
      final html = await _prepare(receiptHtml(d));
      final bytes = await Printing.convertHtml(html: html);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'rasid-${d.receipt.replaceAll('/', '-')}',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// PDF बनाकर शेयर शीट में भेजें (WhatsApp / Drive / ईमेल)
  static Future<bool> shareReceipt(Donation d) async {
    try {
      final html = await _prepare(receiptHtml(d));
      final bytes = await Printing.convertHtml(html: html);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'rasid-${d.receipt.replaceAll('/', '-')}.pdf',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// पास (पूजा / धर्मशाला) का PDF
  static Future<bool> savePass({required String html, required String name}) async {
    try {
      final prepared = await _prepare(html);
      final bytes = await Printing.convertHtml(html: prepared);
      await Printing.layoutPdf(onLayout: (format) async => bytes, name: name);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// HTML में लगी `assets/images/...` तस्वीरों को base64 data-URI में बदलें
  static Future<String> _prepare(String html) async {
    var out = html;
    final paths = RegExp(r'assets/images/[A-Za-z0-9_.]+')
        .allMatches(html)
        .map((m) => m.group(0)!)
        .toSet();

    for (final path in paths) {
      try {
        final data = await rootBundle.load(path);
        final mime = path.endsWith('.png') ? 'image/png' : 'image/jpeg';
        final b64 = base64Encode(data.buffer.asUint8List());
        out = out.replaceAll('src="$path"', 'src="data:$mime;base64,$b64"');
      } catch (_) {
        // तस्वीर न मिले तो HTML वैसा ही रहने दें
      }
    }
    return out;
  }
}
