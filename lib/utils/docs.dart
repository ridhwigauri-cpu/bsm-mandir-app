import '../data/donation_info.dart';
import '../data/foundation_info.dart';
import '../data/models.dart';
import 'format.dart';

const String _css = '''
*{box-sizing:border-box}
body{font-family:'Noto Sans Devanagari',system-ui,sans-serif;margin:0;padding:20px;background:#F3F1EC;color:#2B1418}
.sheet{max-width:720px;margin:0 auto;background:#fff;border:1px solid #D8C9B4;border-radius:12px;overflow:hidden}
.top{background:linear-gradient(120deg,#7C1521,#420A11);color:#FFF3DC;padding:18px 20px;display:flex;gap:12px;align-items:center}
.em{width:46px;height:46px;border-radius:50%;background:linear-gradient(180deg,#F5D98A,#E8B54A);color:#5E0F18;display:flex;align-items:center;justify-content:center;font-size:22px;font-weight:700}
.top h1{font-size:15px;margin:0}
.top p{margin:3px 0 0;font-size:10px;color:rgba(255,243,220,.75)}
.tag{margin-left:auto;font-size:9px;font-weight:700;background:rgba(232,181,74,.2);border:1px solid rgba(232,181,74,.5);color:#F5D98A;padding:4px 9px;border-radius:99px;white-space:nowrap}
.body{padding:20px}
h2{font-size:12px;letter-spacing:.6px;text-transform:uppercase;color:#8A7278;margin:0 0 8px}
table{width:100%;border-collapse:collapse;font-size:12.5px}
td{padding:7px 0;border-bottom:1px dashed #E6D9C4}
td:first-child{color:#5A4046;width:44%}
td:last-child{text-align:right;font-weight:700;color:#5E0F18}
.amt{font-size:21px;font-weight:800;color:#5E0F18;text-align:right;margin:12px 0 2px}
.words{font-size:10.5px;color:#8A7278;text-align:right}
.note{font-size:10.5px;line-height:1.7;color:#5A4046;margin-top:14px;background:#FFF8EC;border:1px solid #EFE0C8;padding:11px;border-radius:8px}
.sign{display:flex;justify-content:space-between;margin-top:24px;font-size:10.5px;color:#5A4046}
.sign div{text-align:center}
.line{width:140px;border-top:1px solid #B9A38E;margin-bottom:5px}
.foot{padding:11px 20px;background:#FFF8EC;border-top:1px solid #EFE0C8;font-size:9.5px;color:#8A7278;text-align:center;line-height:1.6}
.pass{max-width:340px;margin:0 auto;background:#fff;border:1px solid #D8C9B4;border-radius:14px;overflow:hidden;text-align:center}
.pass .h{background:linear-gradient(120deg,#7C1521,#420A11);color:#FFF3DC;padding:14px}
.pass .h h1{font-size:13px;margin:0}
.pass .h p{font-size:9.5px;margin:3px 0 0;color:rgba(255,243,220,.75)}
.pass .id{font-size:13px;font-weight:800;letter-spacing:.5px;color:#5E0F18;margin:8px 0}
.pass .f{font-size:9px;color:#8A7278;padding:9px;background:#FFF8EC}
.big{font-size:11px;color:#8A7278;text-align:center;margin-bottom:10px}
''';

/// दान रसीद का HTML — "दान प्रशस्ति पत्र" शैली (प्रिंट/PDF के लिए)
/// ₹5,000 से अधिक → प्रशस्ति पत्र, वरना सामान्य रसीद
String receiptHtml(Donation d) {
  final commendation = d.amt > 5000;
  final title = commendation ? 'दान प्रशस्ति पत्र' : 'दान रसीद';
  final titleEn = commendation ? 'Certificate of Commendation' : 'Donation Receipt';
  final body = commendation
      ? 'यह विशेष प्रशस्ति पत्र आदरणीय <b>${d.name}</b> को श्री बाबा सिद्धनाथ मंदिर जीर्णोद्धार '
        'सेवा फाउंडेशन की ओर से आपके बहुमूल्य एवं पुनीत योगदान के लिए अत्यंत आभार प्रकट करने हेतु '
        'प्रदान किया जाता है। आपके उदार सहयोग ने मंदिर के पुनर्निर्माण और सौंदर्यकरण कार्यों को गति प्रदान की है।'
      : 'यह रसीद आदरणीय <b>${d.name}</b> को श्री बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन की '
        'ओर से प्राप्त दान राशि के लिए प्रदान की जाती है। आपके सहयोग हेतु हार्दिक आभार — '
        'बाबा सिद्धनाथ आपका कल्याण करें।';
  final note = commendation
      ? '(यह विशेष प्रशस्ति पत्र ₹5,000/- से अधिक की दान राशि के लिए है)'
      : '(यह रसीद 80G कर छूट हेतु मान्य है)';

  return '''
<!doctype html><html lang="hi"><head><meta charset="utf-8">
<title>$title - ${d.receipt}</title>
<style>
*{box-sizing:border-box}
body{margin:0;padding:18px;background:#EFEBE2;font-family:'Noto Sans Devanagari',system-ui,sans-serif}
@page{size:A4;margin:10mm}
@media print{body{background:#fff;padding:0}.frame{max-width:100%}}
.frame{max-width:760px;margin:0 auto;padding:3px;border-radius:18px;
  background:linear-gradient(135deg,#E8B54A,#B9862A,#E8B54A)}
.inner{background:#FFF9EE;border:1px solid rgba(185,134,42,.8);border-radius:15px;padding:18px 16px}
.top{display:flex;align-items:center;justify-content:space-between;gap:8px}
.chip{background:#5E0F18;color:#FFE9B8;font-size:10px;font-weight:700;padding:4px 8px;border-radius:6px}
.logo{width:72px;height:72px;border-radius:50%;object-fit:cover;border:2px solid #B9862A}
.photo{width:98px;height:74px;object-fit:cover;border-radius:8px;border:1.5px solid #B9862A}
.pill{display:inline-block;background:#1B2A6B;color:#FFF3DC;font-size:16px;font-weight:800;
  padding:6px 20px;border-radius:50px;letter-spacing:.4px}
.en{color:#B01B2E;font-style:italic;font-weight:600;font-size:17px;margin-top:4px}
.body{font-size:13px;line-height:1.75;color:#2B1418;text-align:center;margin:14px 6px 0}
.body b{color:#5E0F18}
.note{color:#B01B2E;font-style:italic;font-weight:700;font-size:11px;text-align:center;margin-top:8px}
.bottom{display:flex;align-items:flex-end;justify-content:space-between;gap:12px;margin-top:18px}
.lbl{font-size:8.5px;letter-spacing:.6px;font-weight:800;color:#5A4046}
.val{font-size:12px;font-weight:800;color:#5E0F18;margin-bottom:8px}
.amtwrap{text-align:center}
.amtpill{display:inline-block;background:#1B2A6B;color:#FFF3DC;font-size:10px;font-weight:700;
  padding:2px 12px;border-radius:50px}
.amt{display:inline-block;margin-top:4px;border:1.5px solid #B9862A;border-radius:50px;
  background:#fff;padding:6px 18px;font-size:15px;font-weight:800;color:#5E0F18}
.seal{width:96px;height:96px;border-radius:50%;border:1.6px solid #1B2A6B;background:#F3F6FF;
  display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;
  color:#1B2A6B;font-size:6px;line-height:1.35}
.seal b{font-size:7px}
.words{font-size:10px;color:#5A4046;text-align:center;margin-top:10px}
.foot{border-top:1px solid rgba(185,134,42,.4);margin-top:12px;padding-top:8px;
  font-size:8.5px;color:#8A7278;text-align:center;line-height:1.6}
</style></head><body>
<div class="frame"><div class="inner">
  <div class="top">
    <div class="chip">CIN : ${FoundationInfo.cin}</div>
    <img class="logo" src="assets/images/foundation_logo.jpg" alt="">
    <div class="chip">PAN : ${FoundationInfo.pan}</div>
  </div>

  <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-top:12px">
    <img class="photo" src="assets/images/mandir.jpg" alt="">
    <div style="text-align:center">
      <div class="pill">$title</div>
      <div class="en">$titleEn</div>
    </div>
    <div style="width:98px"></div>
  </div>

  <div class="body">$body</div>
  <div class="note">$note</div>

  <div class="bottom">
    <div>
      <div class="lbl">CERTIFICATE NUMBER</div>
      <div class="val">${d.receipt}</div>
      <div class="lbl">DATE</div>
      <div class="val">${dateLabel(dateKey(d.ts))}</div>
      <div class="lbl">माध्यम</div>
      <div class="val" style="font-size:11px">${d.method} · ${d.cat}</div>
    </div>
    <div class="amtwrap">
      <div class="amtpill">सहयोग राशि</div><br>
      <div class="amt">${inr(d.amt)}</div>
    </div>
    <div class="seal">
      <div style="font-size:14px">ॐ</div>
      <div><b>बाबा सिद्धनाथ मंदिर</b></div>
      <div>जीर्णोद्धार सेवा फाउंडेशन</div>
      <div style="width:60%;border-top:1px solid #1B2A6B;margin:3px 0"></div>
      <div>CIN: ${FoundationInfo.cin}</div>
      <div><b>Auth. Signatory</b></div>
    </div>
  </div>

  <div class="words">${amountWords(d.amt)}</div>

  <div class="foot">
    बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन · श्री बजरंगबली धर्मशाला, तेलहाड़ा का अंग<br>
    Section 8 कंपनी · पंजीयन 25 जून 2026 · तेलहारा (नालंदा), बिहार
  </div>
</div></div>
</body></html>''';
}

String pujaPassHtml(PujaPass p) => '''
<!doctype html><html lang="hi"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><style>$_css</style></head><body>
<div class="pass">
  <div class="h"><h1>बाबा सिद्धनाथ मंदिर</h1><p>जीर्णोद्धार सेवा फाउंडेशन · पूजा / दर्शन पास</p></div>
  <div style="padding:14px">
    <div class="big">${p.type}</div>
    <div class="id">${p.passId}</div>
    <table>
      <tr><td>दिनांक</td><td>${dateLabel(p.date)}</td></tr>
      <tr><td>स्लॉट</td><td>${p.slot}</td></tr>
      <tr><td>नाम</td><td>${p.name}</td></tr>
      <tr><td>मोबाइल</td><td>${p.phone}</td></tr>
      <tr><td>स्थिति</td><td>${p.used ? 'प्रयुक्त' : 'वैध'}</td></tr>
    </table>
  </div>
  <div class="f">गेट पर यह पास दिखाएँ · यह पास केवल एक बार मान्य है</div>
</div></body></html>
''';

String roomPassHtml(RoomBooking b) => '''
<!doctype html><html lang="hi"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><style>$_css</style></head><body>
<div class="pass">
  <div class="h"><h1>बाबा सिद्धनाथ मंदिर</h1><p>जीर्णोद्धार सेवा फाउंडेशन · धर्मशाला + अखंड कीर्तन पास</p></div>
  <div style="padding:14px">
    <div class="big">${b.roomName}</div>
    <div class="id">${b.passId}</div>
    <table>
      <tr><td>दिनांक</td><td>${dateLabel(b.date)}</td></tr>
      <tr><td>कीर्तन स्लॉट</td><td>${b.kirtan}</td></tr>
      <tr><td>नाम</td><td>${b.name}</td></tr>
      <tr><td>मोबाइल</td><td>${b.phone}</td></tr>
      <tr><td>आधार</td><td>${b.aadhaarMask}</td></tr>
    </table>
  </div>
  <div class="f">गेट व कमरा दोनों पर यह पास मान्य है</div>
</div></body></html>
''';

/// क्लिपबोर्ड के लिए सादा टेक्स्ट रसीद
String receiptText(Donation d) => '''
बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन
${d.amt > 5000 ? 'दान प्रशस्ति पत्र' : 'दान रसीद'} (80G)

रसीद संख्या : ${d.receipt}
दिनांक       : ${timeLabel(d.ts)}
दाता         : ${d.name}
मोबाइल       : ${d.phone}
श्रेणी       : ${d.cat}
माध्यम       : ${d.method}
राशि         : ${inr(d.amt)} (${amountWords(d.amt)})
स्थिति       : सफल

यह रसीद धारा 80G के अंतर्गत कर छूट हेतु मान्य है।
CIN: ${FoundationInfo.cin} · PAN: ${FoundationInfo.pan}
बैंक: ${DonationInfo.bankName} · A/C: ${DonationInfo.accountNo} · IFSC: ${DonationInfo.ifsc}
''';

String passText(String passId, List<List<String>> rows) {
  final buffer = StringBuffer()
    ..writeln('बाबा सिद्धनाथ मंदिर — डिजिटल पास')
    ..writeln('पास आईडी: $passId')
    ..writeln('');
  for (final row in rows) {
    buffer.writeln('${row[0]}: ${row[1]}');
  }
  return buffer.toString();
}
