import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/brand_footer.dart';
import '../widgets/common.dart';
import '../widgets/three_d.dart';
import '../data/api_models.dart';
import '../services/api_client.dart';

class _Tile {
  const _Tile(this.tab, this.icon, this.title, this.desc);

  final String tab;
  final String icon;
  final String title;
  final String desc;
}

const List<_Tile> _tiles = [
  _Tile('daan', 'heart', 'ऑनलाइन दान', 'UPI/कार्ड से · तुरंत 80G रसीद'),
  _Tile('darshan', 'video', '24x7 लाइव दर्शन', 'गर्भगृह का सीधा प्रसारण'),
  _Tile('puja', 'lamp', 'पूजा व VIP दर्शन', 'स्लॉट बुक करें · QR पास'),
  _Tile('dharamshala', 'bed', 'धर्मशाला व कीर्तन', 'कमरा + अखंड कीर्तन स्लॉट'),
];

class _Aarti {
  const _Aarti(this.time, this.name, this.status, this.tone);

  final String time;
  final String name;
  final String status;
  final String tone;
}

const List<_Aarti> _aarti = [
  _Aarti('06:30', 'मंगला आरती', 'पूर्ण', 'green'),
  _Aarti('12:00', 'भोग आरती', 'पूर्ण', 'green'),
  _Aarti('19:00', 'संध्या आरती', 'अगला', 'amber'),
  _Aarti('20:30', 'श्रृंगार दर्शन', 'लाइव', 'blue'),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state, required this.onTab});

  final AppState state;
  final ValueChanged<String> onTab;

  @override
  Widget build(BuildContext context) {
    final funds = state.funds;
    final passes = <(String, String, String)>[
      for (final d in state.donations.take(3)) ('heart', '${d.cat} · ${d.receipt}', inr(d.amt)),
      for (final p in state.pujas.take(3)) ('lamp', '${p.type} · ${p.slot}', p.passId),
      for (final b in state.roomBookings.take(3))
        ('bed', '${b.roomName} · ${dateLabel(b.date)}', b.passId),
    ];

    return BsmScreen(
      children: [
        const FeatheredBanner(
          image: 'assets/images/mandir_original.jpg',
          title: 'जय बाबा सिद्धनाथ',
          subtitle: 'बाबा सिद्धनाथ मंदिर · तेलहारा (नालंदा), बिहार',
          height: 196,
          badge: 'मंदिर दर्शन',
        ),
        ThreeDPanel(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LiveTotal(
                fallback: funds.total,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: C.gold2,
                  shadows: [Shadow(color: Color(0x88000000), blurRadius: 5)],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'अब तक कुल दान प्राप्त · ${state.donations.length} ऑनलाइन रसीदें',
                style: const TextStyle(fontSize: 10.5, color: C.creamTextDim),
              ),
              const SizedBox(height: 2),
              const Text(
                'मंदिर जीर्णोद्धार में आपका योगदान — पारदर्शी, डिजिटल और सुरक्षित',
                style: TextStyle(fontSize: 11, color: C.creamTextDim, height: 1.45),
              ),
            ],
          ),
        ),
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'temple', title: 'सेवाएँ'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _tileBox(_tiles[0])),
                  const SizedBox(width: 10),
                  Expanded(child: _tileBox(_tiles[1])),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _tileBox(_tiles[2])),
                  const SizedBox(width: 10),
                  Expanded(child: _tileBox(_tiles[3])),
                ],
              ),
            ],
          ),
        ),
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'clock', title: 'आज का कार्यक्रम'),
              for (final a in _aarti) _aartiRow(a),
              const Divider(height: 20, color: C.line),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'आरती व श्रृंगार नोटिफिकेशन',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: C.maroon,
                          ),
                        ),
                        MutedText('समय होते ही पुश-नोटिफिकेशन मिलेगा'),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.notifyOn,
                    onChanged: (_) => state.toggleNotify(),
                    activeThumbColor: Colors.white,
                    activeTrackColor: C.green,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFD8C7CB),
                  ),
                ],
              ),
            ],
          ),
        ),
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardHead(
                icon: 'ticket',
                title: 'मेरे पास व रसीदें',
                trailing: BadgeC(text: '${passes.length}', tone: 'blue'),
              ),
              if (passes.isEmpty)
                const MutedText(
                  'अभी कोई पास या रसीद नहीं है। दान, पूजा या धर्मशाला बुकिंग से शुरू करें।',
                )
              else
                for (var i = 0; i < passes.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        AppIcon(passes[i].$1, size: 14),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            passes[i].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: T.kvLeft,
                          ),
                        ),
                        Text(passes[i].$3, style: T.kvRight),
                      ],
                    ),
                  ),
                  if (i != passes.length - 1) Container(height: 1, color: const Color(0x1A5E0F18)),
                ],
            ],
          ),
        ),
        const BrandFooter(),
        const BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardHead(icon: 'receipt', title: '80G कर लाभ'),
              MutedText(
                'फाउंडेशन पंजीकृत है — हर दान पर तुरंत 80G ई-रसीद ऐप में ही मिलती है। '
                'दान की राशि, परियोजना और खर्च का हिसाब एडमिन डैशबोर्ड पर पारदर्शी रहता है।',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tileBox(_Tile t) {
    return Material(
      color: C.paper,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onTab(t.tab),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: C.amber2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppIcon(t.icon, size: 18, color: C.amber),
              ),
              const SizedBox(height: 9),
              Text(
                t.title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: C.maroon,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                t.desc,
                style: const TextStyle(fontSize: 10.5, color: C.ink3, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aartiRow(_Aarti a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: a.tone == 'amber' ? C.amber2 : C.cream2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              a.time,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: C.maroon,
              ),
            ),
          ),
          Expanded(child: Text(a.name, style: T.kvLeft)),
          BadgeC(text: a.status, tone: a.tone),
        ],
      ),
    );
  }
}

/// असली जोड़ (Neon से) — न मिले तो स्थानीय (डेमो) आँकड़ा
class _LiveTotal extends StatelessWidget {
  const _LiveTotal({required this.fallback, required this.style});

  final int fallback;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (!ApiClient.instance.enabled) return Text(inr(fallback), style: style);
    return FutureBuilder<AdminSummary>(
      future: ApiClient.instance.publicSummary(),
      builder: (context, snap) {
        final total = snap.hasData ? snap.data!.totalPaid : fallback;
        return Text(inr(total), style: style);
      },
    );
  }
}
