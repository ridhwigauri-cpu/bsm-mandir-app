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

class AdminScreen extends StatelessWidget {
  const AdminScreen({
    super.key,
    required this.state,
    required this.onSecurity,
    required this.onLogout,
  });

  final AppState state;
  final VoidCallback onSecurity;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final funds = state.funds;
    final spent = BaseData.projects.fold(0, (sum, p) => sum + p.spent);
    final remaining = funds.total - spent;
    final occupied = state.rooms.where((r) => r.occupied).length;
    final today = state.donationsToday;
    final todaySum = today.fold(0, (sum, d) => sum + d.amt);

    return BsmScreen(
      children: [
        // हेडर
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: C.maroon2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x59E8B54A)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle),
                child: const Text(
                  'ट्र',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: C.maroon),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'एडमिन डैशबोर्ड — फाउंडेशन प्रबंधन',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: C.creamText,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'धन, परियोजनाएँ, स्टाफ एवं वेतन · वित्तीय वर्ष 2026–27',
                      style: TextStyle(fontSize: 10, color: C.creamTextDim),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 84,
                child: BsmButton(
                  label: 'लॉगआउट',
                  kind: BtnKind.ghost,
                  small: true,
                  onPressed: onLogout,
                ),
              ),
            ],
          ),
        ),

        // KPI
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                tone: 'gold',
                icon: 'heart',
                label: 'कुल दान प्राप्त',
                value: inr(funds.total),
                sub: 'वित्तीय वर्ष 2026–27 · अप्रैल–जून सहित',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                tone: 'dark',
                icon: 'bank',
                label: 'बैंक खाते में जमा',
                value: inr(funds.bank),
                sub: 'ऑनलाइन दान · ${funds.total == 0 ? 0 : funds.bank * 100 ~/ funds.total}%',
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                tone: 'deep',
                icon: 'cash',
                label: 'नकद के रूप में',
                value: inr(funds.cash),
                sub: 'दानपात्र / काउंटर · ${funds.total == 0 ? 0 : funds.cash * 100 ~/ funds.total}%',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                tone: 'teal',
                icon: 'shield',
                label: 'आज के सुरक्षा अलर्ट',
                value: '${state.alertsToday}',
                sub: 'AI CCTV · थाना पोर्टल जुड़ा',
              ),
            ),
          ],
        ),

        // परियोजनाएँ
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(
                icon: 'temple',
                title: 'चालू परियोजनाएँ',
                trailing: BadgeC(text: 'जिनमें दान खर्च हो रहा है', tone: 'amber'),
              ),
              for (final p in BaseData.projects) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: C.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    BadgeC(text: p.status, tone: p.progress > 55 ? 'green' : 'amber'),
                    const SizedBox(width: 6),
                    Text(inr(p.spent), style: T.kvRight),
                  ],
                ),
                const SizedBox(height: 6),
                ProgressBarM(value: p.progress),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('प्रगति ${p.progress}%', style: T.muted),
                      Text('लक्ष्य ${inr(p.target)}', style: T.muted),
                    ],
                  ),
                ),
              ],
              Container(height: 1, color: const Color(0x2E5E0F18)),
              const SizedBox(height: 9),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('कुल व्यय', style: _totalStyle),
                  Text(inr(spent), style: _totalStyle),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('शेष राशि', style: _totalStyle),
                  Text(inr(remaining), style: _totalStyle),
                ],
              ),
              const SoftStrip('दान, खर्च, परियोजना और वेतन का पूरा हिसाब एक ही लॉगिन में — पूर्ण पारदर्शिता'),
            ],
          ),
        ),

        // स्टाफ
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(
                icon: 'users',
                title: 'स्टाफ व वेतन भुगतान',
                trailing: BadgeC(text: 'नवंबर 2026', tone: 'amber'),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '${BaseData.staffTotal}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: C.maroon,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'कुल स्टाफ',
                      style: T.muted.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final d in BaseData.depts)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: C.cream2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${d.count}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: C.maroon,
                              ),
                            ),
                            Text(d.name, style: const TextStyle(fontSize: 9, color: C.ink3)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('वेतन भुगतान स्थिति', style: T.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in BaseData.salaryMonths)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: m.paid ? C.green2 : C.amber2,
                        borderRadius: BorderRadius.circular(50),
                        border: m.paid ? null : Border.all(color: const Color(0xFFD9B24C)),
                      ),
                      child: Text(
                        '${m.paid ? '✓' : '⏳'} ${m.month}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: m.paid ? C.green : C.amber,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              const MutedText('अक्टूबर 2026 तक वेतन पूर्ण · नवंबर देय'),
            ],
          ),
        ),

        // लेखा
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(
                icon: 'book',
                title: 'माह-वार लेखा (ऑडिट स्थिति)',
                trailing: BadgeC(text: 'स्वचालित रिकॉर्ड', tone: 'amber'),
              ),
              Row(
                children: const [
                  Expanded(flex: 13, child: Text('माह', style: _thStyle)),
                  Expanded(flex: 10, child: Text('दान', style: _thStyle)),
                  Expanded(flex: 10, child: Text('खर्च', style: _thStyle)),
                  Expanded(flex: 13, child: Text('स्थिति', style: _thStyle)),
                ],
              ),
              const SizedBox(height: 7),
              for (final l in BaseData.lekha) _lekhaRow(l.month, l.daan, l.kharch, l.status, 'green'),
              _lekhaRow('नवंबर 2026', 220000 + funds.online, 140000, 'प्रगति में', 'amber'),
              const SizedBox(height: 9),
              const MutedText('हर माह का दान-खर्च स्वतः दर्ज — मैनुअल रजिस्टर की ज़रूरत नहीं।'),
            ],
          ),
        ),

        // लाइव
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(
                icon: 'trend',
                title: 'रियल-टाइम ऑक्यूपेंसी',
                trailing: BadgeC(text: 'लाइव', tone: 'blue'),
              ),
              KVRow(left: 'धर्मशाला कमरे', right: '$occupied / ${state.rooms.length} भरे'),
              ProgressBarM(value: occupied * 100 ~/ state.rooms.length, color: C.green),
              const SizedBox(height: 6),
              KVRow(left: 'आज की पूजा बुकिंग', right: '${state.pujas.length + 12}'),
              KVRow(
                left: 'कीर्तन स्लॉट भरे',
                right: '${BaseData.kirtan.where((k) => state.kirtanTaken(k) >= BaseData.kirtanCap).length}'
                    ' / ${BaseData.kirtan.length}',
              ),
              KVRow(left: 'आज ऑनलाइन रसीदें', right: '${today.length} · ${inr(todaySum)}'),
              KVRow(left: 'सुरक्षा अलर्ट (कुल)', right: '${state.alerts.length}', divider: false),
              const SizedBox(height: 11),
              BsmButton(
                label: 'AI सुरक्षा डैशबोर्ड खोलें',
                icon: 'shield',
                kind: BtnKind.ghost,
                small: true,
                onPressed: onSecurity,
              ),
            ],
          ),
        ),

        // रसीदें
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardHead(
                icon: 'receipt',
                title: 'ऑनलाइन दान रसीदें',
                trailing: BadgeC(text: '${state.donations.length} रसीदें', tone: 'blue'),
              ),
              if (state.donations.isEmpty)
                const MutedText(
                  'अभी कोई ऑनलाइन दान नहीं — भक्त ऐप से दान करके देखें, यह रिकॉर्ड तुरंत यहाँ दिखेगा।',
                )
              else
                for (final d in state.donations.take(8)) _receiptRow(context, d),
            ],
          ),
        ),
      ],
    );
  }

  static const TextStyle _totalStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: C.maroon,
  );

  static const TextStyle _thStyle = TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    color: C.ink3,
  );

  Widget _lekhaRow(String month, int daan, int kharch, String status, String tone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 13, child: Text(month, style: const TextStyle(fontSize: 11, color: C.ink2))),
          Expanded(flex: 10, child: Text(inr(daan), style: const TextStyle(fontSize: 11, color: C.ink2))),
          Expanded(flex: 10, child: Text(inr(kharch), style: const TextStyle(fontSize: 11, color: C.ink2))),
          Expanded(flex: 13, child: Align(alignment: Alignment.centerLeft, child: BadgeC(text: status, tone: tone))),
        ],
      ),
    );
  }

  Widget _receiptRow(BuildContext context, Donation d) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.receipt,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: C.maroon,
                      ),
                    ),
                    Text(
                      '${d.name} · ${d.cat} · ${d.method} · ${timeLabel(d.ts)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: C.ink3),
                    ),
                  ],
                ),
              ),
              Text(inr(d.amt), style: T.kvRight),
              const SizedBox(width: 8),
              SizedBox(
                width: 74,
                child: BsmButton(
                  label: 'रसीद',
                  kind: BtnKind.ghost,
                  small: true,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: receiptText(d)));
                    if (!context.mounted) return;
                    showToast(context, 'रसीद कॉपी हो गई');
                  },
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0x145E0F18)),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.tone,
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });

  final String tone;
  final String icon;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final Color bg = switch (tone) {
      'gold' => C.gold,
      'dark' => C.maroon2,
      'deep' => C.deep,
      _ => const Color(0xFF14603A),
    };
    final Color fg = tone == 'gold' ? C.onGold : C.creamText;
    final Color subFg = tone == 'gold' ? const Color(0x99000000) : C.creamTextDim;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, size: 13, color: fg),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg),
          ),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 9.5, color: subFg, height: 1.35)),
        ],
      ),
    );
  }
}
