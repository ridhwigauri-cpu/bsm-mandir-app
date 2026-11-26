import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_state.dart';
import '../data/base_data.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/docs.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'daan_screen.dart' show StepTag;

class DharamshalaScreen extends StatefulWidget {
  const DharamshalaScreen({super.key, required this.state});

  final AppState state;

  @override
  State<DharamshalaScreen> createState() => _DharamshalaScreenState();
}

class _DharamshalaScreenState extends State<DharamshalaScreen> {
  String _roomId = '';
  String _kirtan = '';
  String _date = nextDates(5).first.key;
  String _name = '';
  String _phone = '';
  String _aadhaar = '';
  String _aadhaarMask = '';
  bool _aadhaarOk = false;
  bool _verifying = false;
  RoomBooking? _booking;

  Future<void> _verify() async {
    final digits = _aadhaar.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[2-9]\d{11}$').hasMatch(digits)) {
      showToast(context, '12 अंकों का सही आधार नंबर डालें');
      return;
    }
    showToast(context, 'आधार OTP भेजा जा रहा है…');
    setState(() => _verifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() {
      _verifying = false;
      _aadhaarOk = true;
      _aadhaarMask = 'XXXX XXXX ${digits.substring(digits.length - 4)}';
    });
    if (!mounted) return;
    showToast(context, 'आधार सत्यापित ✓');
  }

  void _issue() {
    final room = widget.state.rooms.where((r) => r.id == _roomId).firstOrNull;
    if (room == null) {
      showToast(context, 'कृपया कमरा चुनें');
      return;
    }
    if (room.occupied) {
      showToast(context, 'यह कमरा भरा है — दूसरा चुनें');
      return;
    }
    if (!_aadhaarOk) {
      showToast(context, 'पहले आधार ID सत्यापित करें');
      return;
    }
    if (_kirtan.isEmpty) {
      showToast(context, 'कीर्तन स्लॉट चुनें');
      return;
    }
    if (_name.trim().isEmpty) {
      showToast(context, 'कृपया नाम भरें');
      return;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_phone.trim())) {
      showToast(context, 'सही 10 अंकों का मोबाइल नंबर भरें');
      return;
    }
    if (widget.state.kirtanTaken(_kirtan) >= BaseData.kirtanCap) {
      showToast(context, 'यह कीर्तन स्लॉट भर गया है');
      return;
    }

    final booking = RoomBooking(
      passId: newId('BSM-DS'),
      roomId: room.id,
      roomName: room.name,
      kirtan: _kirtan,
      date: _date,
      name: _name.trim(),
      phone: _phone.trim(),
      aadhaarMask: _aadhaarMask,
      ts: DateTime.now(),
    );
    widget.state.addRoomBooking(booking);
    setState(() => _booking = booking);
    showToast(context, 'डिजिटल रूम पास + कीर्तन अनुमति पास जारी');
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final state = widget.state;

    return BsmScreen(
      children: [
        if (booking != null)
          BsmCard(
            borderColor: const Color(0x591E7A46),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: C.green2, shape: BoxShape.circle),
                  child: const AppIcon('bed', size: 24, color: C.green),
                ),
                const SizedBox(height: 8),
                const Text(
                  'पास जारी — रूम + कीर्तन',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: C.green),
                ),
                const SizedBox(height: 3),
                const MutedText(
                  'दोनों पास एक ही QR में · गेट व कमरा दोनों पर मान्य',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    QrView(value: booking.passId, side: 104),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.passId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: C.maroon,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(booking.roomName, style: T.kvLeft),
                          Text('कीर्तन ${booking.kirtan}', style: T.kvLeft),
                          Text('${dateLabel(booking.date)} · ${booking.name}', style: T.kvLeft),
                          Text(booking.aadhaarMask, style: T.kvLeft),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: BsmButton(
                        label: 'पास कॉपी',
                        icon: 'copy',
                        kind: BtnKind.dark,
                        small: true,
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(
                            text: passText(booking.passId, [
                              ['कमरा', booking.roomName],
                              ['कीर्तन', booking.kirtan],
                              ['दिनांक', dateLabel(booking.date)],
                              ['नाम', booking.name],
                              ['आधार', booking.aadhaarMask],
                            ]),
                          ));
                          if (!context.mounted) return;
                          showToast(context, 'पास कॉपी हो गया');
                        },
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: BsmButton(
                        label: 'नई बुकिंग',
                        kind: BtnKind.ghost,
                        small: true,
                        onPressed: () => setState(() {
                          _booking = null;
                          _roomId = '';
                          _kirtan = '';
                          _aadhaar = '';
                          _aadhaarOk = false;
                          _name = '';
                          _phone = '';
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          BsmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHead(
                  icon: 'bed',
                  title: 'धर्मशाला व अखंड कीर्तन',
                  trailing: StepTag(_aadhaarOk ? 'चरण 2 / 2' : 'चरण 1 / 2'),
                ),
                const Text('कमरा चुनें', style: T.label),
                const SizedBox(height: 6),
                PillGrid(
                  items: state.rooms.map((r) => r.id).toList(),
                  selected: _roomId,
                  columns: 1,
                  enabledFor: (id) =>
                      !(state.rooms.where((r) => r.id == id).firstOrNull?.occupied ?? true),
                  labelFor: (id) {
                    final room = state.rooms.where((r) => r.id == id).first;
                    return '${room.name} · ${room.cap} व्यक्ति'
                        '${room.occupied ? ' · भरा' : ' · उपलब्ध'}';
                  },
                  onSelect: (id) => setState(() => _roomId = id),
                ),
                const SizedBox(height: 8),
                const Text('कीर्तन स्लॉट', style: T.label),
                const SizedBox(height: 6),
                PillGrid(
                  items: BaseData.kirtan,
                  selected: _kirtan,
                  columns: 2,
                  enabledFor: (s) => state.kirtanTaken(s) < BaseData.kirtanCap,
                  labelFor: (s) =>
                      state.kirtanTaken(s) >= BaseData.kirtanCap ? '$s · भरा' : s,
                  onSelect: (s) => setState(() => _kirtan = s),
                ),
                const SizedBox(height: 8),
                const Text('दिनांक', style: T.label),
                const SizedBox(height: 6),
                _dateChips(),
                const Divider(height: 22, color: C.line),
                const Text('आधार ID सत्यापन', style: T.label),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() {
                          _aadhaar = v.replaceAll(RegExp(r'\D'), '');
                          _aadhaarOk = false;
                        }),
                        keyboardType: TextInputType.number,
                        inputFormatters: [LengthLimitingTextInputFormatter(12)],
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(hintText: '12 अंकों का आधार'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    SizedBox(
                      width: 120,
                      child: BsmButton(
                        label: _aadhaarOk
                            ? 'सत्यापित'
                            : _verifying
                                ? 'जाँच…'
                                : 'सत्यापित करें',
                        kind: BtnKind.dark,
                        small: true,
                        enabled: !_verifying,
                        onPressed: _verify,
                      ),
                    ),
                  ],
                ),
                if (_aadhaarOk)
                  OkLine('आधार सत्यापित — $_aadhaarMask')
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: MutedText(
                      'पहचान सत्यापन के बाद ही बुकिंग आगे बढ़ती है (डेमो में OTP सिम्युलेट होता है)।',
                    ),
                  ),
                const SizedBox(height: 12),
                InputField(
                  value: _name,
                  onChanged: (v) => setState(() => _name = v),
                  label: 'नाम',
                  placeholder: 'आपका नाम',
                  maxLength: 60,
                ),
                const SizedBox(height: 11),
                InputField(
                  value: _phone,
                  onChanged: (v) => setState(() => _phone = v.replaceAll(RegExp(r'\D'), '')),
                  label: 'मोबाइल',
                  placeholder: '10 अंक',
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
                const SizedBox(height: 12),
                BsmButton(label: 'पास जारी करें', icon: 'ticket', onPressed: _issue),
              ],
            ),
          ),
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'chart', title: 'रियल-टाइम ऑक्यूपेंसी'),
              for (final r in state.rooms)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${r.name} (${r.cap} व्यक्ति)', style: T.kvLeft),
                      ),
                      BadgeC(
                        text: r.occupied ? 'भरा' : 'खाली',
                        tone: r.occupied ? 'red' : 'green',
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              const MutedText(
                'यही स्थिति एडमिन डैशबोर्ड पर रियल-टाइम दिखती है — कौन-सा कमरा भरा है या खाली।',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateChips() {
    final dates = nextDates(5);
    return Row(
      children: [
        for (final d in dates)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Material(
                color: _date == d.key ? C.maroon3 : Colors.white,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () => setState(() => _date = d.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: _date == d.key ? C.maroon3 : C.line),
                    ),
                    child: Column(
                      children: [
                        Text(
                          d.top,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: _date == d.key ? C.creamTextDim : C.ink3,
                          ),
                        ),
                        Text(
                          d.bottom,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _date == d.key ? C.creamText : C.maroon,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
