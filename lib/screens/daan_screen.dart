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

class DaanScreen extends StatefulWidget {
  const DaanScreen({super.key, required this.state});

  final AppState state;

  @override
  State<DaanScreen> createState() => _DaanScreenState();
}

class _DaanScreenState extends State<DaanScreen> {
  String _cat = BaseData.cats.first;
  String _amtText = '1100';
  String _name = '';
  String _phone = '';
  String _method = BaseData.methods.first;
  bool _busy = false;
  Donation? _done;

  int get _amount => int.tryParse(_amtText) ?? 0;

  bool get _phoneOk => RegExp(r'^[6-9]\d{9}$').hasMatch(_phone.trim());

  Future<void> _startPay() async {
    if (_amount < 11) {
      showToast(context, 'कृपया ₹11 या अधिक राशि दर्ज करें');
      return;
    }
    if (_name.trim().isEmpty) {
      showToast(context, 'कृपया नाम भरें');
      return;
    }
    if (!_phoneOk) {
      showToast(context, 'सही 10 अंकों का मोबाइल नंबर भरें');
      return;
    }
    await _openGateway();
  }

  Future<void> _openGateway() async {
    await showBsmSheet<void>(
      context,
      StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> confirm() async {
            setSheetState(() => _busy = true);
            await Future<void>.delayed(const Duration(milliseconds: 1400));
            final donation = widget.state.addDonation(
              name: _name.trim(),
              phone: _phone.trim(),
              cat: _cat,
              amt: _amount,
              method: _method,
            );
            if (!mounted) return;
            Navigator.of(sheetContext).pop();
            setState(() {
              _busy = false;
              _done = donation;
            });
            showToast(context, 'भुगतान सफल · 80G रसीद जारी');
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'पेमेंट गेटवे',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.maroon),
              ),
              const SizedBox(height: 3),
              MutedText('$_cat · ${inr(_amount)} · सुरक्षित भुगतान'),
              const SizedBox(height: 12),
              PillGrid(
                items: BaseData.methods,
                selected: _method,
                columns: 3,
                onSelect: (m) => setSheetState(() => _method = m),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: C.cream2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x145E0F18)),
                ),
                child: Column(
                  children: [
                    KVRow(left: 'दान श्रेणी', right: _cat),
                    KVRow(left: 'दाता', right: _name.isEmpty ? '—' : _name),
                    KVRow(left: 'माध्यम', right: _method),
                    KVRow(left: 'कुल राशि', right: inr(_amount), divider: false),
                  ],
                ),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 3, color: C.goldDeep),
                      ),
                      SizedBox(height: 8),
                      MutedText('भुगतान संसाधित हो रहा है…'),
                    ],
                  ),
                )
              else ...[
                BsmButton(
                  label: _method == 'UPI'
                      ? 'UPI ऐप से भुगतान की पुष्टि करें'
                      : 'भुगतान की पुष्टि करें',
                  onPressed: confirm,
                ),
                const SizedBox(height: 10),
                const MutedText(
                  'डेमो गेटवे — असली ऐप में Razorpay / PhonePe / PayU जुड़ेगा',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                BsmButton(
                  label: 'रद्द करें',
                  kind: BtnKind.ghost,
                  small: true,
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = _done;
    if (done != null) {
      return BsmScreen(
        children: [
          BsmCard(
            color: const Color(0xFFF2FBF5),
            borderColor: const Color(0x661E7A46),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: C.green2, shape: BoxShape.circle),
                  child: const AppIcon('check', size: 26, color: C.green),
                ),
                const SizedBox(height: 8),
                const Text(
                  'भुगतान सफल',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.green),
                ),
                const SizedBox(height: 3),
                MutedText('धन्यवाद, ${done.name} जी — आपका योगदान दर्ज हो गया'),
                const SizedBox(height: 10),
                KVRow(left: 'रसीद नंबर', right: done.receipt),
                KVRow(left: 'श्रेणी', right: done.cat),
                KVRow(left: 'राशि', right: inr(done.amt)),
                KVRow(left: 'माध्यम', right: done.method),
                KVRow(left: 'दिनांक', right: timeLabel(done.ts), divider: false),
                const SizedBox(height: 10),
                const OkLine('80G ई-रसीद तैयार है'),
                const SizedBox(height: 10),
                BsmButton(
                  label: 'रसीद देखें / कॉपी करें',
                  icon: 'receipt',
                  kind: BtnKind.dark,
                  onPressed: () => _showReceipt(done),
                ),
                const SizedBox(height: 8),
                BsmButton(
                  label: 'नया दान करें',
                  kind: BtnKind.ghost,
                  small: true,
                  onPressed: () => setState(() {
                    _done = null;
                    _name = '';
                    _phone = '';
                    _amtText = '1100';
                  }),
                ),
              ],
            ),
          ),
          BsmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardHead(icon: 'search', title: 'यह दान कहाँ लगेगा'),
                for (final p in BaseData.projects)
                  KVRow(left: p.name, right: '${p.progress}% पूर्ण'),
                const SizedBox(height: 8),
                const MutedText(
                  'हर रुपये का हिसाब एडमिन डैशबोर्ड पर परियोजना-वार दिखता है — पूर्ण पारदर्शिता।',
                ),
              ],
            ),
          ),
        ],
      );
    }

    return BsmScreen(
      children: [
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'heart', title: 'ऑनलाइन दान', trailing: _StepTag('चरण 1 / 2')),
              const Text('दान श्रेणी चुनें', style: T.label),
              const SizedBox(height: 6),
              PillGrid(
                items: BaseData.cats,
                selected: _cat,
                columns: 3,
                onSelect: (c) => setState(() => _cat = c),
              ),
              const SizedBox(height: 8),
              const Text('राशि (₹)', style: T.label),
              const SizedBox(height: 6),
              PillGrid(
                items: BaseData.amts.map((a) => a.toString()).toList(),
                selected: BaseData.amts.contains(_amount) ? _amount.toString() : '',
                columns: 4,
                gold: true,
                labelFor: (a) => inr(int.tryParse(a) ?? 0),
                onSelect: (a) => setState(() => _amtText = a),
              ),
              const SizedBox(height: 6),
              InputField(
                value: _amtText,
                onChanged: (v) => setState(() => _amtText = v.replaceAll(RegExp(r'\D'), '')),
                placeholder: 'राशि लिखें',
                keyboardType: TextInputType.number,
                maxLength: 7,
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
                label: 'मोबाइल नंबर',
                placeholder: '10 अंकों का नंबर',
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              const SizedBox(height: 12),
              BsmButton(
                label: 'UPI / कार्ड से भुगतान करें',
                icon: 'lock',
                onPressed: _startPay,
              ),
              const OkLine('सुरक्षित पेमेंट गेटवे · तुरंत 80G रसीद'),
            ],
          ),
        ),
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'list', title: 'भुगतान कैसे होता है'),
              _stepRow(1, 'श्रद्धालु ऐप में श्रेणी व राशि चुनता है'),
              _stepRow(2, 'UPI / कार्ड से सुरक्षित भुगतान'),
              _stepRow(3, 'गेटवे पुष्टि → बैंक रिकॉर्ड स्वतः अपडेट'),
              _stepRow(4, 'तुरंत रसीद + पूरी पारदर्शिता'),
            ],
          ),
        ),
        BsmCard(
          color: C.cream2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'chart', title: 'फाउंडेशन का हिसाब'),
              KVRow(left: 'कुल दान प्राप्त', right: inr(widget.state.funds.total)),
              KVRow(left: 'बैंक खाते में', right: inr(widget.state.funds.bank)),
              KVRow(left: 'नकद', right: inr(widget.state.funds.cash), divider: false),
              const SizedBox(height: 8),
              const MutedText('यही आँकड़े एडमिन डैशबोर्ड पर रियल-टाइम दिखते हैं।'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepRow(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: C.amber2, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: C.amber,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: T.body)),
        ],
      ),
    );
  }

  void _showReceipt(Donation d) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '80G ई-रसीद',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.maroon),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KVRow(left: 'रसीद नंबर', right: d.receipt),
              KVRow(left: 'दाता', right: d.name),
              KVRow(left: 'श्रेणी', right: d.cat),
              KVRow(left: 'राशि', right: inr(d.amt)),
              KVRow(left: 'शब्दों में', right: amountWords(d.amt), divider: false),
              const SizedBox(height: 10),
              const MutedText(
                'यह रसीद धारा 80G के अंतर्गत कर छूट हेतु मान्य है। PDF के लिए README में '
                '"printing" पैकेज जोड़ें — HTML तैयार है (utils/docs.dart)।',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: receiptText(d)));
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              showToast(context, 'रसीद कॉपी हो गई');
            },
            child: const Text('कॉपी करें'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('बंद करें'),
          ),
        ],
      ),
    );
  }
}

class _StepTag extends StatelessWidget {
  const _StepTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: C.amber2, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: C.amber),
      ),
    );
  }
}

/// दूसरी स्क्रीन भी इसी टैग स्टाइल का इस्तेमाल करती हैं
class StepTag extends StatelessWidget {
  const StepTag(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => _StepTag(text);
}
