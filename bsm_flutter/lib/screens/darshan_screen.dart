import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class _AartiItem {
  const _AartiItem(this.time, this.name, this.status, this.tone);

  final String time;
  final String name;
  final String status;
  final String tone;
}

const List<_AartiItem> _schedule = [
  _AartiItem('06:30', 'मंगला आरती', 'पूर्ण', 'green'),
  _AartiItem('12:00', 'भोग आरती', 'पूर्ण', 'green'),
  _AartiItem('19:00', 'संध्या आरती', 'अगला', 'amber'),
  _AartiItem('20:30', 'श्रृंगार दर्शन', 'लाइव', 'blue'),
];

class DarshanScreen extends StatefulWidget {
  const DarshanScreen({super.key});

  @override
  State<DarshanScreen> createState() => _DarshanScreenState();
}

class _DarshanScreenState extends State<DarshanScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  int _viewers = 1284;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
    _tickViewers();
  }

  Future<void> _tickViewers() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      setState(() => _viewers = 1284 + DateTime.now().millisecondsSinceEpoch % 40);
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BsmScreen(
      children: [
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 230,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _glow,
                    builder: (context, _) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [Color(0xFF5B1020), Color(0xFF2A0A10)],
                                radius: 0.9,
                              ),
                            ),
                          ),
                          Center(
                            child: Transform.scale(
                              scale: 0.95 + _glow.value * 0.12,
                              child: Container(
                                width: 190,
                                height: 190,
                                decoration: const BoxDecoration(
                                  color: Color(0x33FFCD78),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const Center(
                            child: Text(
                              'ॐ',
                              style: TextStyle(
                                fontSize: 62,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF7DFA6),
                              ),
                            ),
                          ),
                          // स्कैन लाइन
                          Positioned(
                            top: _glow.value * 210,
                            left: 0,
                            right: 0,
                            child: Container(height: 2, color: const Color(0x8CE8B54A)),
                          ),
                          const Positioned(top: 9, left: 9, child: _LiveTag()),
                          Positioned(top: 9, right: 9, child: _ViewerTag(count: _viewers)),
                          const Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: ColoredBox(
                              color: Color(0x73000000),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Text(
                                  'HD कैमरा 02 · स्ट्रीम सर्वर से 24x7 प्रसारण',
                                  style: TextStyle(fontSize: 9.5, color: C.creamTextDim),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: BsmButton(
                      label: '24x7 लाइव देखें',
                      icon: 'play',
                      kind: BtnKind.dark,
                      small: true,
                      onPressed: () => showToast(context, 'स्ट्रीम सर्वर से HD फ़ीड जुड़ रही है…'),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: BsmButton(
                      label: 'आरती अलर्ट',
                      icon: 'bell',
                      kind: BtnKind.ghost,
                      small: true,
                      onPressed: () => showToast(context, 'आरती का रिमाइंडर सेट हो गया'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              const MutedText(
                'डेमो स्क्रीन — लाइव में मंदिर का असली HD कैमरा फ़ीड दिखेगा',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'temple', title: 'आरती व श्रृंगार समय'),
              for (final a in _schedule)
                Container(
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
                ),
            ],
          ),
        ),
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'info', title: 'कैसे काम करता है'),
              const KVRow(left: 'ऐप में लाइव दर्शन खोलें', right: 'श्रद्धालु'),
              const KVRow(left: 'गर्भगृह के HD CCTV कैमरे', right: 'स्रोत'),
              const KVRow(left: 'स्ट्रीम सर्वर से 24/7 प्रसारण', right: 'बैकएंड'),
              const KVRow(
                left: 'आरती/श्रृंगार पर ऑटो नोटिफिकेशन',
                right: 'स्वचालित',
                divider: false,
              ),
              const SizedBox(height: 8),
              const MutedText(
                'प्रोडक्शन में यहाँ HLS स्ट्रीम (video_player / better_player) जुड़ेगा — m3u8 फ़ीड।',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveTag extends StatelessWidget {
  const _LiveTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x88000000),
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Row(
        children: [
          _Dot(),
          SizedBox(width: 5),
          Text(
            'LIVE · गर्भगृह',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFFFFD9DC)),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(color: Color(0xFFFF5A64), shape: BoxShape.circle),
    );
  }
}

class _ViewerTag extends StatelessWidget {
  const _ViewerTag({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x88000000),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          const AppIcon('eye', size: 11, color: C.creamText),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: C.creamText,
            ),
          ),
        ],
      ),
    );
  }
}
