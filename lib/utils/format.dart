/// भारतीय फ़ॉर्मेट, तारीख़ें और राशि शब्दों में — किसी पैकेज पर निर्भर नहीं।

const List<String> monthsHi = [
  'जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
  'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर',
];

const List<String> weekdaysHi = ['रवि', 'सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि'];

/// ₹25,00,000 — लाख/करोड़ वाली भारतीय गिनती
String inr(num value) {
  final v = value.round();
  final negative = v < 0;
  final digits = v.abs().toString();
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    final rest = digits.substring(0, digits.length - 3);
    final buffer = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buffer.write(',');
      buffer.write(rest[i]);
    }
    grouped = '$buffer,$last3';
  }
  return '₹${negative ? '-' : ''}$grouped';
}

String _two(int n) => n.toString().padLeft(2, '0');

String dateKey([DateTime? when]) {
  final d = when ?? DateTime.now();
  return '${d.year}-${_two(d.month)}-${_two(d.day)}';
}

String dateLabel(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return key;
  final month = int.tryParse(parts[1]) ?? 1;
  return '${int.tryParse(parts[2]) ?? 1} ${monthsHi[(month - 1).clamp(0, 11)]} ${parts[0]}';
}

/// 25 नव 10:24
String timeLabel(DateTime ts) =>
    '${ts.day} ${monthsHi[ts.month - 1].substring(0, 3)} ${_two(ts.hour)}:${_two(ts.minute)}';

bool isToday(DateTime ts) {
  final now = DateTime.now();
  return ts.year == now.year && ts.month == now.month && ts.day == now.day;
}

class DateChip {
  const DateChip({required this.key, required this.top, required this.bottom});

  final String key;
  final String top;
  final String bottom;
}

List<DateChip> nextDates([int count = 5]) {
  final out = <DateChip>[];
  final now = DateTime.now();
  for (var i = 0; i < count; i++) {
    final d = now.add(Duration(days: i));
    final top = switch (i) {
      0 => 'आज',
      1 => 'कल',
      2 => 'परसों',
      _ => weekdaysHi[d.weekday % 7],
    };
    out.add(DateChip(
      key: dateKey(d),
      top: top,
      bottom: '${d.day} ${monthsHi[d.month - 1].substring(0, 3)}',
    ));
  }
  return out;
}

const String _idChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

String newId(String prefix) {
  final rnd = DateTime.now().microsecondsSinceEpoch;
  final buffer = StringBuffer(prefix)..write('-');
  for (var i = 0; i < 5; i++) {
    buffer.write(_idChars[(rnd ~/ (i + 1) + i * 7) % _idChars.length]);
  }
  return buffer.toString();
}

/// राशि शब्दों में — एक हज़ार एक सौ रुपये मात्र
String amountWords(int amount) {
  const ones = [
    '', 'एक', 'दो', 'तीन', 'चार', 'पाँच', 'छह', 'सात', 'आठ', 'नौ', 'दस',
    'ग्यारह', 'बारह', 'तेरह', 'चौदह', 'पंद्रह', 'सोलह', 'सत्रह', 'अठारह', 'उन्नीस',
  ];
  const tens = ['', '', 'बीस', 'तीस', 'चालीस', 'पचास', 'साठ', 'सत्तर', 'अस्सी', 'नब्बे'];

  var n = amount;
  if (n <= 0) return 'शून्य रुपये मात्र';

  final parts = <String>[];
  final thousands = n ~/ 1000;
  n %= 1000;
  if (thousands > 0) {
    parts.add('${thousands < 20 ? ones[thousands] : thousands} हज़ार');
  }
  final hundreds = n ~/ 100;
  n %= 100;
  if (hundreds > 0) parts.add('${ones[hundreds]} सौ');
  if (n > 0) {
    parts.add(n < 20 ? ones[n] : '${tens[n ~/ 10]}${n % 10 != 0 ? ' ${ones[n % 10]}' : ''}');
  }
  return '${parts.join(' ')} रुपये मात्र';
}
