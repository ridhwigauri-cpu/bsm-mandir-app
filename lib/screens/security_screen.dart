import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/base_data.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../services/security_api.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

class _Detection {
  const _Detection({required this.conf, required this.label, required this.alert});

  final int conf;
  final String label;
  final bool alert;
}

class _Pipe {
  const _Pipe(this.title, this.desc);

  final String title;
  final String desc;
}

const List<_Pipe> _pipeline = [
  _Pipe(
    'सभी CCTV कैमरों की लाइव फ़ीड',
    'परिसर व मार्ग की फ़ीड 24 घंटे AI Vision Analytics Engine से स्कैन होती है।',
  ),
  _Pipe(
    'खतरे की पहचान (YOLOv8)',
    'अनधिकृत प्रवेश, संदिग्ध हरकत, चोरी प्रयास या भीड़ उग्रता — 0.5 सेकंड में।',
  ),
  _Pipe(
    'ऑटो फोटो व 10-सेकंड वीडियो',
    'घटना डिटेक्ट होते ही HD फोटो और वीडियो क्लिप स्वतः सुरक्षित।',
  ),
  _Pipe(
    'तत्काल दोहरा अलर्ट',
    'एडमिन डैशबोर्ड पर पैनिक सायरन + फोटो पॉप-अप, और थाना पोर्टल पर लोकेशन सहित SMS/E-mail।',
  ),
];

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _walk;
  final Map<int, _Detection> _dets = {};
  final Map<int, Timer> _timers = {};
  Timer? _scanTimer;
  SecurityAlert? _popup;

  @override
  void initState() {
    super.initState();
    _walk = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _startScanLoop();
  }

  void _startScanLoop() {
    _scanTimer = Timer.periodic(const Duration(seconds: 9), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final i = math.Random().nextInt(BaseData.cams.length);
      if (_dets[i]?.alert == true) return;
      final conf = 88 + math.Random().nextInt(10);
      final kind = ['व्यक्ति', 'भीड़', 'वाहन'][math.Random().nextInt(3)];
      setState(() {
        _dets[i] = _Detection(conf: conf, label: '$kind $conf%', alert: false);
      });
      _timers[i]?.cancel();
      _timers[i] = Timer(const Duration(milliseconds: 2300), () {
        if (!mounted) return;
        if (_dets[i]?.alert == true) return;
        setState(() => _dets.remove(i));
      });
    });
  }

  Future<void> _trigger([int? index]) async {
    final i = index ?? math.Random().nextInt(BaseData.cams.length);
    final cam = BaseData.cams[i];

    // AI सर्विस जुड़ी हो तो असली डिटेक्शन, वरना सिमुलेशन
    final apiResult = await SecurityApi.detect(camId: cam.id);
    if (!mounted) return;

    final label = apiResult?.label ?? 'अनधिकृत प्रवेश';
    final conf = apiResult?.confidence ?? (92 + math.Random().nextInt(7));

    setState(() {
      _dets[i] = _Detection(conf: conf, label: '$label $conf%', alert: true);
    });

    final alert = SecurityAlert(
      id: newId('EVD'),
      camId: cam.id,
      cam: cam.name,
      label: label,
      conf: conf,
      ts: DateTime.now(),
      location: '${cam.name}, बाबा सिद्धनाथ मंदिर परिसर',
    );
    widget.state.addAlert(alert);
    setState(() => _popup = alert);

    _timers[i]?.cancel();
    _timers[i] = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      setState(() => _dets.remove(i));
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    for (final t in _timers.values) {
      t.cancel();
    }
    _walk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final popup = _popup;

    return Stack(
      children: [
        BsmScreen(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '24/7 AI CCTV सुरक्षा व थाना अलर्ट',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: C.creamText,
                  ),
                ),
                const SizedBox(height: 2),
                const MutedText(
                  'AI Security Pipeline · YOLOv8 Vision Analytics · 0.5 सेकंड पहचान',
                  color: C.creamTextDim,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _PillTag(
                      text: 'इंजन सक्रिय',
                      dot: const Color(0xFF5BE58F),
                      bg: const Color(0x441E7A46),
                      fg: const Color(0xFFC9F2D8),
                    ),
                    const SizedBox(width: 8),
                    _PillTag(
                      text: '${BaseData.cams.length} कैमरा लाइव',
                      dot: const Color(0xFFFF5A64),
                      bg: const Color(0x44C0272D),
                      fg: const Color(0xFFFFD9DC),
                    ),
                  ],
                ),
              ],
            ),
            // कैमरा ग्रिड (2 कॉलम)
            Column(
              children: [
                for (var row = 0; row < BaseData.cams.length; row += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        Expanded(
                          child: _CamTile(
                            cam: BaseData.cams[row],
                            index: row,
                            animation: _walk,
                            detection: _dets[row],
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: row + 1 < BaseData.cams.length
                              ? _CamTile(
                                  cam: BaseData.cams[row + 1],
                                  index: row + 1,
                                  animation: _walk,
                                  detection: _dets[row + 1],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: BsmButton(
                    label: 'घटना सिमुलेट करें',
                    icon: 'alert',
                    kind: BtnKind.dark,
                    small: true,
                    onPressed: () => _trigger(),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: BsmButton(
                    label: 'सभी कैमरा ऑनलाइन',
                    kind: BtnKind.ghost,
                    small: true,
                    onPressed: () {
                      setState(_dets.clear);
                      showToast(context, 'सभी कैमरे ऑनलाइन · AI इंजन सक्रिय');
                    },
                  ),
                ),
              ],
            ),
            const SectionTitle(tag: 'प्रक्रिया', title: 'AI सुरक्षा पाइपलाइन'),
            for (var i = 0; i < _pipeline.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: C.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: C.onGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pipeline[i].title,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: C.maroon,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _pipeline[i].desc,
                            style: const TextStyle(fontSize: 11, color: C.ink3, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SectionTitle(tag: 'साक्ष्य', title: 'डिजिटल साक्ष्य डिगर'),
            BsmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.alerts.isEmpty)
                    const MutedText(
                      'अभी कोई घटना दर्ज नहीं — सभी कैमरे सामान्य स्कैनिंग में हैं। '
                      '"घटना सिमुलेट करें" दबाकर पाइपलाइन देखें।',
                    )
                  else
                    for (final a in state.alerts.take(6)) _evidenceRow(a),
                ],
              ),
            ),
            const SectionTitle(tag: 'अलर्ट', title: 'थाना पोर्टल अलर्ट लॉग'),
            BsmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.alerts.isEmpty)
                    const MutedText('थाना पोर्टल अलर्ट लॉग खाली है।')
                  else
                    for (final a in state.alerts.take(5))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: C.green2,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const AppIcon('check', size: 10, color: C.green),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'मगध थाना · ${a.cam}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: C.maroon,
                                    ),
                                  ),
                                  Text(
                                    'SMS भेजा गया · E-mail भेजा गया · लोकेशन सहित · ${timeLabel(a.ts)}',
                                    style: const TextStyle(fontSize: 10, color: C.ink3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
        if (popup != null) _AlertDialog(alert: popup, onClose: () => setState(() => _popup = null)),
      ],
    );
  }

  Widget _evidenceRow(SecurityAlert a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: C.cream2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0x145E0F18)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF12232B),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0x66FF4D57)),
            ),
            child: const AppIcon('camera', size: 15, color: Color(0xFFFF8A90)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${a.label} · कैमरा ${a.camId} (${a.cam})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: C.maroon,
                  ),
                ),
                Text(
                  'HD फोटो + 10 सेकंड क्लिप · ${a.conf}% · ${timeLabel(a.ts)}',
                  style: const TextStyle(fontSize: 10, color: C.ink2),
                ),
                Text(
                  'साक्ष्य सुरक्षित · ${a.id}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: C.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertDialog extends StatelessWidget {
  const _AlertDialog({required this.alert, required this.onClose});

  final SecurityAlert alert;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x99140407),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: C.maroon2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF4D57)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppIcon('alert', size: 16, color: Color(0xFFFFD9DC)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'सुरक्षा अलर्ट — ${alert.cam}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFD9DC),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${alert.label} · विश्वास ${alert.conf}% · 0.5 सेकंड में पहचान\n'
                    'स्थान: ${alert.location}\n'
                    'HD फोटो + 10 सेकंड वीडियो क्लिप सुरक्षित\n'
                    'थाना पोर्टल पर SMS व E-mail भेजा गया',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xE6FFF3DC),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: BsmButton(
                          label: 'ठीक है',
                          kind: BtnKind.dark,
                          small: true,
                          onPressed: onClose,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BsmButton(
                          label: 'बंद करें',
                          kind: BtnKind.ghost,
                          small: true,
                          onPressed: onClose,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({required this.text, required this.dot, required this.bg, required this.fg});

  final String text;
  final Color dot;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

class _CamTile extends StatelessWidget {
  const _CamTile({
    required this.cam,
    required this.index,
    required this.animation,
    this.detection,
  });

  final Cam cam;
  final int index;
  final Animation<double> animation;
  final _Detection? detection;

  @override
  Widget build(BuildContext context) {
    final alert = detection?.alert == true;

    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alert ? const Color(0xFFFF4D57) : const Color(0x38E8B54A),
          width: alert ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            // हर कैमरा अलग चाल से चलता है
            final offset = (index * 0.17) % 1.0;

            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final progress = (animation.value + offset) % 1.0;
                final personLeft = progress * (width - 20);
                return Stack(
                  children: [
                    // मंदिर का दृश्य
                    Positioned(
                      top: height * 0.1,
                      left: width * 0.33,
                      child: Container(
                        width: width * 0.34,
                        height: height * 0.62,
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFCE82),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
                          border: Border.all(color: const Color(0x38E8B54A)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: height * 0.36,
                      child: const ColoredBox(color: Color(0x0DFFFFFF)),
                    ),
                    // चलता व्यक्ति
                    Positioned(
                      left: personLeft,
                      top: height * 0.42,
                      child: Column(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFD3B4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 1),
                            width: 14,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF93A2AC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Row(
                              children: [
                                Container(width: 5, height: 9, color: const Color(0xFF5D6B74)),
                                const SizedBox(width: 4),
                                Container(width: 5, height: 9, color: const Color(0xFF5D6B74)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // डिटेक्शन बॉक्स
                    if (detection != null)
                      Positioned(
                        left: personLeft - 8,
                        top: height * 0.34,
                        child: Container(
                          width: 30,
                          height: 62,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: alert ? const Color(0xFFFF4D57) : C.gold,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: -13,
                                left: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: alert ? const Color(0xFFFF4D57) : C.gold,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(3),
                                      topRight: Radius.circular(3),
                                    ),
                                  ),
                                  child: Text(
                                    detection!.label,
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w700,
                                      color: alert ? Colors.white : const Color(0xFF3A2208),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // टैग
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x73000000),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5A64),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'REC · कैमरा ${cam.id}',
                              style: const TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEAF7EE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // फुटर
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        color: const Color(0x8C000000),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cam.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 7.5,
                                  color: Color(0xCCEAF7EE),
                                ),
                              ),
                            ),
                            const Text(
                              'YOLOv8',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8FE3B0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}