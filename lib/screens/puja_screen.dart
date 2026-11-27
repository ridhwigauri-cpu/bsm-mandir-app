import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_state.dart';
import '../data/base_data.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/docs.dart';
import '../utils/format.dart';
import '../services/pdf_service.dart';
import '../widgets/common.dart';
import '../widgets/three_d.dart';
import 'daan_screen.dart' show StepTag;

class PujaScreen extends StatefulWidget {
  const PujaScreen({super.key, required this.state});

  final AppState state;

  @override
  State<PujaScreen> createState() => _PujaScreenState();
}

class _PujaScreenState extends State<PujaScreen> {
  String _type = BaseData.pujaTypes.first;
  String _date = nextDates(5)[1].key;
  String _slot = '09:00 – 10:00';
  String _name = '';
  String _phone = '';
  PujaPass? _pass;
  final TextEditingController _gate = TextEditingController();
  String? _gateMsg;
  bool _gateOk = false;

  @override
  void dispose() {
    _gate.dispose();
    super.dispose();
  }

  void _book() {
    if (_name.trim().isEmpty) {
      showToast(context, 'कृपया नाम भरें');
      return;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_phone.trim())) {
      showToast(context, 'सही 10 अंकों का मोबाइल नंबर भरें');
      return;
    }
    if (widget.state.pujaTaken(_slot, _date) >= BaseData.slotCap) {
      showToast(context, 'यह स्लॉट भर गया है, दूसरा चुनें');
      return;
    }
    final pass = PujaPass(
      passId: newId('BSM-PJ'),
      name: _name.trim(),
      phone: _phone.trim(),
      date: _date,
      slot: _slot,
      type: _type,
      ts: DateTime.now(),
    );
    widget.state.addPuja(pass);
    setState(() {
      _pass = pass;
      _gateMsg = null;
    });
    showToast(context, 'पास जारी — QR स्कैन से सीधे प्रवेश');
  }

  void _scan() {
    final value = _gate.text.trim().toUpperCase();
    if (value.isEmpty) {
      setState(() {
        _gateOk = false;
        _gateMsg = 'पास आईडी डालें';
      });
      return;
    }
    final found = widget.state.findPass(value);
    if (found == null) {
      setState(() {
        _gateOk = false;
        _gateMsg = 'अमान्य पास — प्रवेश अस्वीकृत';
      });
      return;
    }
    if (found.used) {
      setState(() {
        _gateOk = false;
        _gateMsg = 'यह पास पहले प्रयोग हो चुका है';
      });
      return;
    }
    widget.state.markPujaUsed(found.passId);
    setState(() {
      _gateOk = true;
      _gateMsg = 'सत्यापित — ${found.name} · ${found.type} · ${found.slot}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pass = _pass;
    final state = widget.state;

    return BsmScreen(
      children: [
        const FeatheredBanner(
          image: 'assets/images/mandir_original.jpg',
          title: 'पूजा व VIP दर्शन',
          subtitle: 'स्लॉट बुक करें · QR पास से सीधे प्रवेश',
          badge: 'पूजा बुकिंग',
        ),
        if (pass != null)
          BsmCard(
            borderColor: const Color(0x591E7A46),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: C.green2, shape: BoxShape.circle),
                  child: const AppIcon('ticket', size: 24, color: C.green),
                ),
                const SizedBox(height: 8),
                const Text(
                  'बुकिंग सफल · डिजिटल पास जारी',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: C.green),
                ),
                const SizedBox(height: 3),
                const MutedText(
                  'गेट पर यही QR स्कैन कराएँ — लाइन में लगने की ज़रूरत नहीं',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    QrView(value: pass.passId, side: 104),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pass.passId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: C.maroon,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(pass.type, style: T.kvLeft),
                          Text('${dateLabel(pass.date)} · ${pass.slot}', style: T.kvLeft),
                          Text(pass.name, style: T.kvLeft),
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
                        label: 'PDF',
                        icon: 'download',
                        kind: BtnKind.gold,
                        small: true,
                        onPressed: () async {
                          final ok = await PdfService.savePass(
                            html: pujaPassHtml(pass),
                            name: 'puja-pass-${pass.passId}',
                          );
                          if (!context.mounted) return;
                          if (!ok) showToast(context, 'PDF नहीं बन सका');
                        },
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: BsmButton(
                        label: 'पास कॉपी',
                        icon: 'copy',
                        kind: BtnKind.dark,
                        small: true,
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(
                            text: passText(pass.passId, [
                              ['प्रकार', pass.type],
                              ['दिनांक', dateLabel(pass.date)],
                              ['स्लॉट', pass.slot],
                              ['नाम', pass.name],
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
                          _pass = null;
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
                const CardHead(
                  icon: 'lamp',
                  title: 'पूजा व VIP दर्शन बुकिंग',
                  trailing: StepTag('चरण 1 / 2'),
                ),
                const Text('पूजा का प्रकार', style: T.label),
                const SizedBox(height: 6),
                PillGrid(
                  items: BaseData.pujaTypes,
                  selected: _type,
                  columns: 3,
                  onSelect: (t) => setState(() => _type = t),
                ),
                const SizedBox(height: 8),
                const Text('दिनांक', style: T.label),
                const SizedBox(height: 6),
                _dateChips(),
                const SizedBox(height: 8),
                const Text('उपलब्ध स्लॉट चुनें', style: T.label),
                const SizedBox(height: 6),
                PillGrid(
                  items: BaseData.pujaSlots,
                  selected: _slot,
                  columns: 2,
                  enabledFor: (s) => state.pujaTaken(s, _date) < BaseData.slotCap,
                  labelFor: (s) => state.pujaTaken(s, _date) >= BaseData.slotCap ? '$s · भर गया' : s,
                  onSelect: (s) => setState(() => _slot = s),
                ),
                MutedText(
                  'चुना गया स्लॉट: $_slot · शेष सीट: '
                  '${(BaseData.slotCap - state.pujaTaken(_slot, _date)).clamp(0, BaseData.slotCap)}',
                ),
                const SizedBox(height: 11),
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
                BsmButton(label: 'स्लॉट बुक करें', icon: 'ticket', onPressed: _book),
                const OkLine('यूनिक QR पास · गेट स्कैनर से बिना लाइन प्रवेश'),
              ],
            ),
          ),
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'door', title: 'गेट स्कैनर (डेमो)'),
              const MutedText(
                'पास आईडी डालकर प्रवेश सत्यापन जाँचें — जैसे गेट पर स्कैनर करता है।',
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gate,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: state.pujas.isEmpty ? 'BSM-PJ-XXXX' : state.pujas.first.passId,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  SizedBox(
                    width: 110,
                    child: BsmButton(
                      label: 'स्कैन करें',
                      kind: BtnKind.dark,
                      small: true,
                      onPressed: _scan,
                    ),
                  ),
                ],
              ),
              if (_gateMsg != null) ...[
                const SizedBox(height: 9),
                if (_gateOk)
                  OkLine(_gateMsg!)
                else
                  Row(
                    children: [
                      const AppIcon('close', size: 13, color: C.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _gateMsg!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: C.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
        const BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardHead(icon: 'list', title: 'बुकिंग कैसे होती है'),
              KVRow(left: 'तिथि व स्लॉट चुनें', right: 'श्रद्धालु'),
              KVRow(left: 'डेटाबेस खाली स्लॉट जाँचता है', right: 'बैकएंड'),
              KVRow(left: 'हर भक्त के लिए यूनिक QR पास', right: 'स्वचालित'),
              KVRow(left: 'गेट पर स्कैनर से एंट्री सत्यापित', right: 'प्रवेश', divider: false),
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
