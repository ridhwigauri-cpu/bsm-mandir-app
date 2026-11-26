class Donation {
  const Donation({
    required this.id,
    required this.name,
    required this.phone,
    required this.cat,
    required this.amt,
    required this.method,
    required this.ts,
    required this.receipt,
  });

  final String id;
  final String name;
  final String phone;
  final String cat;
  final int amt;
  final String method;
  final DateTime ts;
  final String receipt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'cat': cat,
        'amt': amt,
        'method': method,
        'ts': ts.millisecondsSinceEpoch,
        'receipt': receipt,
      };

  static Donation fromJson(Map<String, dynamic> j) => Donation(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        cat: j['cat'] as String? ?? '',
        amt: (j['amt'] as num?)?.toInt() ?? 0,
        method: j['method'] as String? ?? '',
        ts: DateTime.fromMillisecondsSinceEpoch((j['ts'] as num?)?.toInt() ?? 0),
        receipt: j['receipt'] as String? ?? '',
      );
}

class PujaPass {
  const PujaPass({
    required this.passId,
    required this.name,
    required this.phone,
    required this.date,
    required this.slot,
    required this.type,
    required this.ts,
    this.used = false,
  });

  final String passId;
  final String name;
  final String phone;
  final String date;
  final String slot;
  final String type;
  final DateTime ts;
  final bool used;

  PujaPass copyWith({bool? used}) => PujaPass(
        passId: passId,
        name: name,
        phone: phone,
        date: date,
        slot: slot,
        type: type,
        ts: ts,
        used: used ?? this.used,
      );

  Map<String, dynamic> toJson() => {
        'passId': passId,
        'name': name,
        'phone': phone,
        'date': date,
        'slot': slot,
        'type': type,
        'ts': ts.millisecondsSinceEpoch,
        'used': used,
      };

  static PujaPass fromJson(Map<String, dynamic> j) => PujaPass(
        passId: j['passId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        date: j['date'] as String? ?? '',
        slot: j['slot'] as String? ?? '',
        type: j['type'] as String? ?? '',
        ts: DateTime.fromMillisecondsSinceEpoch((j['ts'] as num?)?.toInt() ?? 0),
        used: j['used'] as bool? ?? false,
      );
}

class RoomBooking {
  const RoomBooking({
    required this.passId,
    required this.roomId,
    required this.roomName,
    required this.kirtan,
    required this.date,
    required this.name,
    required this.phone,
    required this.aadhaarMask,
    required this.ts,
  });

  final String passId;
  final String roomId;
  final String roomName;
  final String kirtan;
  final String date;
  final String name;
  final String phone;
  final String aadhaarMask;
  final DateTime ts;

  Map<String, dynamic> toJson() => {
        'passId': passId,
        'roomId': roomId,
        'roomName': roomName,
        'kirtan': kirtan,
        'date': date,
        'name': name,
        'phone': phone,
        'aadhaarMask': aadhaarMask,
        'ts': ts.millisecondsSinceEpoch,
      };

  static RoomBooking fromJson(Map<String, dynamic> j) => RoomBooking(
        passId: j['passId'] as String? ?? '',
        roomId: j['roomId'] as String? ?? '',
        roomName: j['roomName'] as String? ?? '',
        kirtan: j['kirtan'] as String? ?? '',
        date: j['date'] as String? ?? '',
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        aadhaarMask: j['aadhaarMask'] as String? ?? '',
        ts: DateTime.fromMillisecondsSinceEpoch((j['ts'] as num?)?.toInt() ?? 0),
      );
}

class SecurityAlert {
  const SecurityAlert({
    required this.id,
    required this.camId,
    required this.cam,
    required this.label,
    required this.conf,
    required this.ts,
    required this.location,
  });

  final String id;
  final String camId;
  final String cam;
  final String label;
  final int conf;
  final DateTime ts;
  final String location;

  Map<String, dynamic> toJson() => {
        'id': id,
        'camId': camId,
        'cam': cam,
        'label': label,
        'conf': conf,
        'ts': ts.millisecondsSinceEpoch,
        'location': location,
      };

  static SecurityAlert fromJson(Map<String, dynamic> j) => SecurityAlert(
        id: j['id'] as String? ?? '',
        camId: j['camId'] as String? ?? '',
        cam: j['cam'] as String? ?? '',
        label: j['label'] as String? ?? '',
        conf: (j['conf'] as num?)?.toInt() ?? 0,
        ts: DateTime.fromMillisecondsSinceEpoch((j['ts'] as num?)?.toInt() ?? 0),
        location: j['location'] as String? ?? '',
      );
}

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.cap,
    this.occupied = false,
    this.who = '',
  });

  final String id;
  final String name;
  final int cap;
  final bool occupied;
  final String who;

  Room copyWith({bool? occupied, String? who}) => Room(
        id: id,
        name: name,
        cap: cap,
        occupied: occupied ?? this.occupied,
        who: who ?? this.who,
      );

  Map<String, dynamic> toJson() => {'id': id, 'occupied': occupied, 'who': who};
}

class Project {
  const Project({
    required this.name,
    required this.spent,
    required this.target,
    required this.progress,
    required this.status,
  });

  final String name;
  final int spent;
  final int target;
  final int progress;
  final String status;
}

class Lekha {
  const Lekha({
    required this.month,
    required this.daan,
    required this.kharch,
    required this.status,
  });

  final String month;
  final int daan;
  final int kharch;
  final String status;
}

class Cam {
  const Cam({required this.id, required this.name, required this.sub});

  final String id;
  final String name;
  final String sub;
}

class Funds {
  const Funds({
    required this.total,
    required this.bank,
    required this.cash,
    required this.online,
  });

  final int total;
  final int bank;
  final int cash;
  final int online;
}

class Dept {
  const Dept({required this.name, required this.count});

  final String name;
  final int count;
}

class SalaryMonth {
  const SalaryMonth({required this.month, required this.paid});

  final String month;
  final bool paid;
}
