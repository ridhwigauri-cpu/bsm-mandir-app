// ignore_for_file: avoid_print
// शुद्ध Dart जाँच — Flutter इंजन की ज़रूरत नहीं
import '../lib/utils/format.dart';
import '../lib/utils/qr.dart';
import '../lib/utils/docs.dart';
import '../lib/data/models.dart';

int failed = 0;
void eq(String name, Object? got, Object? want) {
  final ok = '$got' == '$want';
  if (!ok) {
    failed++;
    print('FAIL $name → got "$got", want "$want"');
  }
}

void main() {
  eq('inr 25L', inr(2500000), '₹25,00,000');
  eq('inr 21.5L', inr(2150000), '₹21,50,000');
  eq('inr 9.8L', inr(980000), '₹9,80,000');
  eq('inr 13.1L', inr(1310000), '₹13,10,000');
  eq('inr 1100', inr(1100), '₹1,100');
  eq('inr 999', inr(999), '₹999');
  eq('inr 0', inr(0), '₹0');
  eq('dateKey', dateKey(DateTime(2026, 11, 25)), '2026-11-25');
  eq('dateLabel', dateLabel('2026-11-25'), '25 नवंबर 2026');
  eq('nextDates len', nextDates(5).length, 5);
  eq('nextDates[0]', nextDates(5)[0].top, 'आज');
  eq('nextDates[1]', nextDates(5)[1].top, 'कल');
  eq('words 1100', amountWords(1100), 'एक हज़ार एक सौ रुपये मात्र');
  eq('words 2100', amountWords(2100), 'दो हज़ार एक सौ रुपये मात्र');
  eq('words 5100', amountWords(5100), 'पाँच हज़ार एक सौ रुपये मात्र');
  eq('qr rows', qrMatrix('BSM-PJ-ABCDE').length, 25);
  eq('qr finder', qrMatrix('X')[0].sublist(0, 3).toString(), '[true, true, true]');
  eq('qr stable', qrMatrix('A').toString() == qrMatrix('A').toString(), true);
  final id = newId('BSM-PJ');
  eq('id prefix', id.startsWith('BSM-PJ-'), true);
  eq('id length', id.length, 'BSM-PJ-'.length + 5);

  final donation = Donation(
    id: 'DN-1', name: 'रमेश शर्मा', phone: '9876543210', cat: 'जीर्णोद्धार',
    amt: 2100, method: 'UPI', ts: DateTime(2026, 11, 25, 10, 24), receipt: '80G/2026-27/1001',
  );
  final html = receiptHtml(donation);
  eq('receipt no', html.contains('80G/2026-27/1001'), true);
  eq('receipt amt', html.contains('₹2,100'), true);
  eq('receipt words', html.contains('दो हज़ार एक सौ रुपये मात्र'), true);
  eq('receipt text', receiptText(donation).contains('रमेश शर्मा'), true);

  final pass = PujaPass(
    passId: 'BSM-PJ-AB123', name: 'सुनीता', phone: '9812345678',
    date: '2026-11-26', slot: '09:00 – 10:00', type: 'सामान्य पूजा', ts: DateTime(2026, 11, 25),
  );
  eq('pass html', pujaPassHtml(pass).contains('BSM-PJ-AB123'), true);
  eq('pass text', passText(pass.passId, [['नाम', pass.name]]).contains('सुनीता'), true);

  final room = RoomBooking(
    passId: 'BSM-DS-X1', roomId: 'R3', roomName: 'कमरा 3', kirtan: '09:00 – 11:00',
    date: '2026-11-26', name: 'मोहन', phone: '9765432109',
    aadhaarMask: 'XXXX XXXX 0123', ts: DateTime(2026, 11, 25),
  );
  eq('room html', roomPassHtml(room).contains('कमरा 3'), true);
  eq('json roundtrip', Donation.fromJson(donation.toJson()).name, 'रमेश शर्मा');
  eq('room json', RoomBooking.fromJson(room.toJson()).roomName, 'कमरा 3');

  print(failed == 0 ? 'सभी जाँच पास ✓' : '$failed जाँच विफल');
}
