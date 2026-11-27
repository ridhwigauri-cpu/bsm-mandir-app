# CHANGELOG

## v1.6.0 — PDF डाउनलोड / शेयर
- `printing` पैकेज जोड़ा — रसीद का असली PDF (HTML→PDF, Devanagari सही रेंडर)
- रसीद डायलॉग में चार बटन: **PDF** · **शेयर** · **कॉपी** · **बंद**
- पूजा पास और धर्मशाला पास में भी **PDF** बटन
- `lib/services/pdf_service.dart` — तस्वीरें base64 में इनलाइन, A4 प्रिंट CSS
- झलक: `dart run tool/receipt_preview.dart` → `preview_*.html`

## v1.5.0 — दान रसीद का नया डिज़ाइन
- "दान प्रशस्ति पत्र / Certificate of Commendation" शैली (गोल्ड फ़्रेम, CIN/PAN चिप, मंदिर फ़ोटो, नीली मुहर)
- **₹5,000 से अधिक** → प्रशस्ति पत्र, **₹5,000 तक** → दान रसीद
- दान सफल होते ही यही प्रमाण-पत्र डायलॉग में दिखता है
- `lib/widgets/donation_certificate.dart` (Flutter) + `receiptHtml()` (HTML)
- यूनिट टेस्ट: ₹11,000 → प्रशस्ति पत्र, ₹1,100 → रसीद

## v1.4.0 — दान QR + बैंक विवरण
- आधिकारिक PNB QR (Scan & Pay) + UPI ID `6203051369m@pnb`
- NEFT/IMPS विवरण: A/C 1573002100004142 · IFSC PUNB157300 · PNB तेलहारा
- दान टैब और परिचय टैब — दोनों में कार्ड, टैप पर ज़ूम, हर मान पर **कॉपी** बटन
- `lib/data/donation_info.dart`, `lib/widgets/donation_qr_card.dart`

## v1.3.0 — पंजीयन प्रमाण
- "परिचय" टैब में नया कार्ड **पंजीयन एवं प्रमाण**
- CIN U94910BR2026NPL085916 · PAN AAOCB8762B · TAN PTNB10218F · Section 8 लाइसेंस 187252
- चारों प्रमाण-पत्रों की छवि (Incorporation, Section 8, PAN, TAN) — टैप पर ज़ूम
- mca.gov.in पर सत्यापन का नोट; फुटर में Section 8 + CIN
- `lib/data/foundation_info.dart` में `registration`, `registrationDocs`, `notices`
