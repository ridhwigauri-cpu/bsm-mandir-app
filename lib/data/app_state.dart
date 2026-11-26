import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../utils/format.dart';
import 'base_data.dart';
import 'models.dart';
import 'storage.dart';

/// ऐप का पूरा डेटा — दान, पास, बुकिंग, अलर्ट + फाउंडेशन के आँकड़े।
class AppState extends ChangeNotifier {
  AppState() {
    unawaited(_load());
  }

  List<Donation> _donations = [];
  List<PujaPass> _pujas = [];
  List<RoomBooking> _roomBookings = [];
  List<SecurityAlert> _alerts = [];
  List<Room> _rooms = List<Room>.from(BaseData.rooms);
  Map<String, int> _pujaCounts = Map<String, int>.from(BaseData.pujaSeed);
  Map<String, int> _kirtanCounts = Map<String, int>.from(BaseData.kirtanSeed);
  bool _notifyOn = true;

  List<Donation> get donations => List.unmodifiable(_donations);
  List<PujaPass> get pujas => List.unmodifiable(_pujas);
  List<RoomBooking> get roomBookings => List.unmodifiable(_roomBookings);
  List<SecurityAlert> get alerts => List.unmodifiable(_alerts);
  List<Room> get rooms => List.unmodifiable(_rooms);
  bool get notifyOn => _notifyOn;

  /* ---------- गणना ---------- */
  int get onlineSum => _donations.fold(0, (sum, d) => sum + d.amt);

  Funds get funds => Funds(
        total: BaseData.fundTotal + onlineSum,
        bank: BaseData.fundBank + onlineSum,
        cash: BaseData.fundCash,
        online: onlineSum,
      );

  int pujaTaken(String slot, String date) {
    final seeded = _pujaCounts[slot] ?? 0;
    final booked = _pujas.where((p) => p.slot == slot && p.date == date).length;
    return seeded + booked;
  }

  int kirtanTaken(String slot) {
    final seeded = _kirtanCounts[slot] ?? 0;
    final booked = _roomBookings.where((b) => b.kirtan == slot).length;
    return seeded + booked;
  }

  int get alertsToday => _alerts.where((a) => isToday(a.ts)).length;

  List<Donation> get donationsToday => _donations.where((d) => isToday(d.ts)).toList();

  PujaPass? findPass(String passId) {
    final key = passId.trim().toUpperCase();
    for (final p in _pujas) {
      if (p.passId.toUpperCase() == key) return p;
    }
    return null;
  }

  /* ---------- बदलाव ---------- */
  Donation addDonation({
    required String name,
    required String phone,
    required String cat,
    required int amt,
    required String method,
  }) {
    final d = Donation(
      id: newId('DN'),
      name: name,
      phone: phone,
      cat: cat,
      amt: amt,
      method: method,
      ts: DateTime.now(),
      receipt: '80G/2026-27/${1001 + _donations.length}',
    );
    _donations = [d, ..._donations];
    _save();
    return d;
  }

  void addPuja(PujaPass pass) {
    _pujas = [pass, ..._pujas];
    _save();
  }

  void markPujaUsed(String passId) {
    _pujas = _pujas
        .map((p) => p.passId == passId ? p.copyWith(used: true) : p)
        .toList(growable: false);
    _save();
  }

  void addRoomBooking(RoomBooking booking) {
    _roomBookings = [booking, ..._roomBookings];
    _rooms = _rooms
        .map((r) => r.id == booking.roomId ? r.copyWith(occupied: true, who: booking.name) : r)
        .toList(growable: false);
    _kirtanCounts = {..._kirtanCounts, booking.kirtan: (_kirtanCounts[booking.kirtan] ?? 0) + 1};
    _save();
  }

  void addAlert(SecurityAlert alert) {
    _alerts = [alert, ..._alerts];
    _save();
  }

  void toggleNotify() {
    _notifyOn = !_notifyOn;
    notifyListeners();
    _save();
  }

  void resetAll() {
    _donations = [];
    _pujas = [];
    _roomBookings = [];
    _alerts = [];
    _rooms = List<Room>.from(BaseData.rooms);
    _pujaCounts = Map<String, int>.from(BaseData.pujaSeed);
    _kirtanCounts = Map<String, int>.from(BaseData.kirtanSeed);
    _notifyOn = true;
    notifyListeners();
    _save();
  }

  /* ---------- सेव / लोड ---------- */
  Map<String, dynamic> _toJson() => {
        'donations': _donations.map((d) => d.toJson()).toList(),
        'pujas': _pujas.map((p) => p.toJson()).toList(),
        'roomBookings': _roomBookings.map((b) => b.toJson()).toList(),
        'alerts': _alerts.map((a) => a.toJson()).toList(),
        'rooms': _rooms.map((r) => r.toJson()).toList(),
        'kirtanCounts': _kirtanCounts,
        'notify': _notifyOn,
      };

  Future<void> _save() async {
    notifyListeners();
    try {
      await Storage.write(jsonEncode(_toJson()));
    } catch (_) {
      // सेव न हो तो भी ऐप चले
    }
  }

  Future<void> _load() async {
    try {
      final raw = await Storage.read();
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;

      _donations = _list(data['donations']).map(Donation.fromJson).toList();
      _pujas = _list(data['pujas']).map(PujaPass.fromJson).toList();
      _roomBookings = _list(data['roomBookings']).map(RoomBooking.fromJson).toList();
      _alerts = _list(data['alerts']).map(SecurityAlert.fromJson).toList();

      final savedRooms = _list(data['rooms']);
      if (savedRooms.isNotEmpty) {
        _rooms = _rooms.map((r) {
          final match = savedRooms.firstWhere(
            (j) => j['id'] == r.id,
            orElse: () => <String, dynamic>{},
          );
          if (match.isEmpty) return r;
          return r.copyWith(
            occupied: match['occupied'] as bool? ?? r.occupied,
            who: match['who'] as String? ?? r.who,
          );
        }).toList();
      }

      final kc = data['kirtanCounts'];
      if (kc is Map) {
        _kirtanCounts = {
          for (final entry in kc.entries) entry.key.toString(): (entry.value as num).toInt(),
        };
      }

      _notifyOn = data['notify'] as bool? ?? true;
      notifyListeners();
    } catch (_) {
      // खराब डेटा — डिफ़ॉल्ट से शुरू
    }
  }

  List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

/// ऐप के किसी भी हिस्से से AppState पाने के लिए
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope ऊपर नहीं मिला — main.dart में लपेटें');
    return scope!.notifier!;
  }
}
