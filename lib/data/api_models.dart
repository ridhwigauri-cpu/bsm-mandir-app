/// Neon बैकएंड से आने वाले डेटा के मॉडल (JSON → Dart)
///
/// हर क्लास `fromJson` से बनती है और खाली/गुम फ़ील्ड पर भी नहीं टूटती —
/// क्योंकि सर्वर का जवाब कभी भी थोड़ा बदल सकता है।

int _asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String _asStr(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

/// पूजा स्लॉट — कितनी सीटें बची हैं
class PujaSlotInfo {
  const PujaSlotInfo({
    required this.slot,
    required this.taken,
    required this.left,
    required this.full,
  });

  final String slot;
  final int taken;
  final int left;
  final bool full;

  factory PujaSlotInfo.fromJson(Map<String, dynamic> j) => PujaSlotInfo(
        slot: _asStr(j['slot']),
        taken: _asInt(j['taken']),
        left: _asInt(j['left']),
        full: j['full'] == true,
      );
}

/// कमरे + कीर्तन की स्थिति
class RoomInfo {
  const RoomInfo({
    required this.id,
    required this.name,
    required this.available,
    this.capacity = 2,
  });

  final String id;
  final String name;
  final bool available;
  final int capacity;

  factory RoomInfo.fromJson(Map<String, dynamic> j) => RoomInfo(
        id: _asStr(j['id']),
        name: _asStr(j['name']),
        available: j['available'] == true,
        capacity: _asInt(j['capacity'], 2),
      );
}

class KirtanSlotInfo {
  const KirtanSlotInfo({required this.slot, required this.left, required this.full});

  final String slot;
  final int left;
  final bool full;

  factory KirtanSlotInfo.fromJson(Map<String, dynamic> j) => KirtanSlotInfo(
        slot: _asStr(j['slot']),
        left: _asInt(j['left']),
        full: j['full'] == true,
      );
}

class RoomsState {
  const RoomsState({required this.date, required this.rooms, required this.kirtan});

  final String date;
  final List<RoomInfo> rooms;
  final List<KirtanSlotInfo> kirtan;

  int get availableCount => rooms.where((r) => r.available).length;

  factory RoomsState.fromJson(Map<String, dynamic> j) => RoomsState(
        date: _asStr(j['date']),
        rooms: ((j['rooms'] as List?) ?? [])
            .map((e) => RoomInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        kirtan: ((j['kirtan'] as List?) ?? [])
            .map((e) => KirtanSlotInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// दान का ऑर्डर (Razorpay)
class DonationOrder {
  const DonationOrder({
    required this.donationId,
    required this.orderId,
    required this.amount,
    this.keyId = '',
    this.demo = false,
  });

  final int donationId;
  final String orderId;
  final int amount;
  final String keyId;
  final bool demo;

  factory DonationOrder.fromJson(Map<String, dynamic> j) => DonationOrder(
        donationId: _asInt(j['donationId']),
        orderId: _asStr(j['orderId']),
        amount: _asInt(j['amount']),
        keyId: _asStr(j['keyId']),
        demo: j['demo'] == true,
      );
}

/// भुगतान सत्यापन के बाद — रसीद
class DonationReceipt {
  const DonationReceipt({
    required this.status,
    required this.receipt,
    this.donationId = 0,
    this.receiptPdfUrl = '',
    this.announcement = '',
  });

  final String status; // paid | already_paid
  final String receipt; // 80G/2026-27/1001
  final int donationId;
  final String receiptPdfUrl;
  final String announcement;

  bool get isPaid => status == 'paid' || status == 'already_paid';

  factory DonationReceipt.fromJson(Map<String, dynamic> j) => DonationReceipt(
        status: _asStr(j['status']),
        receipt: _asStr(j['receipt']),
        donationId: _asInt(j['donationId']),
        receiptPdfUrl: _asStr(j['receiptPdfUrl']),
        announcement: _asStr(j['announcement']),
      );
}

/// एडमिन डैशबोर्ड का सारांश
class AdminSummary {
  const AdminSummary({
    required this.totalPaid,
    required this.todayPaid,
    required this.countPaid,
    required this.pendingVerification,
    required this.roomsTotal,
    required this.roomsOccupied,
    required this.alertsToday,
    required this.announcementsQueued,
  });

  final int totalPaid;
  final int todayPaid;
  final int countPaid;
  final int pendingVerification;
  final int roomsTotal;
  final int roomsOccupied;
  final int alertsToday;
  final int announcementsQueued;

  factory AdminSummary.fromJson(Map<String, dynamic> j) {
    final d = (j['donations'] as Map<String, dynamic>?) ?? const {};
    final r = (j['rooms'] as Map<String, dynamic>?) ?? const {};
    final a = (j['alerts'] as Map<String, dynamic>?) ?? const {};
    final n = (j['announcements'] as Map<String, dynamic>?) ?? const {};
    return AdminSummary(
      totalPaid: _asInt(d['total_paid']),
      todayPaid: _asInt(d['today']),
      countPaid: _asInt(d['count_paid']),
      pendingVerification: _asInt(d['pending_verification']),
      roomsTotal: _asInt(r['total']),
      roomsOccupied: _asInt(r['occupied']),
      alertsToday: _asInt(a['today']),
      announcementsQueued: _asInt(n['queued']),
    );
  }
}
