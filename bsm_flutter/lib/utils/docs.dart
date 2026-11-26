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

/// 80G ई-रसीद का HTML — प्रिंट/PDF के लिए (package:printing से जोड़ें)
String receiptHtml(Donation d) => '''
<!doctype html><html lang="hi"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><style>$_css</style></head><body>
<div class="sheet">
  <div class="top">
    <div class="em">ॐ</div>
    <div><h1>बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन</h1>
    <p>धर्मार्थ ट्रस्ट · पंजीकृत · 80G कर छूट प्रमाणित</p></div>
    <div class="tag">80G ई-रसीद</div>
  </div>
  <div class="body">
    <h2>दान रसीद / Donation Receipt</h2>
    <table>
      <tr><td>रसीद संख्या</td><td>${d.receipt}</td></tr>
      <tr><td>दिनांक</td><td>${timeLabel(d.ts)}</td></tr>
      <tr><td>दाता का नाम</td><td>${d.name}</td></tr>
      <tr><td>मोबाइल</td><td>${d.phone}</td></tr>
      <tr><td>दान श्रेणी</td><td>${d.cat}</td></tr>
      <tr><td>भुगतान माध्यम</td><td>${d.method}</td></tr>
      <tr><td>स्थिति</td><td>सफल / Successful</td></tr>
    </table>
    <div class="amt">${inr(d.amt)}</div>
    <div class="words">राशि शब्दों में: ${amountWords(d.amt)}</div>
    <div class="note">यह रसीद आयकर अधिनियम की धारा 80G के अंतर्गत कर छूट हेतु मान्य है। दान पूर्णतः स्वैच्छिक है और किसी सेवा के बदले नहीं लिया गया। राशि का उपयोग मंदिर जीर्णोद्धार, धर्मशाला मरम्मत एवं अन्नदान सेवा में किया जाएगा।</div>
    <div class="sign"><div><div class="line"></div>दाता हस्ताक्षर</div><div><div class="line"></div>ट्रस्ट प्रबंधक / कोषाध्यक्ष</div></div>
  </div>
  <div class="foot">बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन · तकनीकी पार्टनर: RGT Memorial Foundation<br>यह कंप्यूटर जनित रसीद है — हस्ताक्षर की आवश्यकता नहीं।</div>
</div></body></html>
''';

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
80G ई-रसीद

रसीद संख्या : ${d.receipt}
दिनांक       : ${timeLabel(d.ts)}
दाता         : ${d.name}
मोबाइल       : ${d.phone}
श्रेणी       : ${d.cat}
माध्यम       : ${d.method}
राशि         : ${inr(d.amt)} (${amountWords(d.amt)})
स्थिति       : सफल

यह रसीद धारा 80G के अंतर्गत कर छूट हेतु मान्य है।
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
