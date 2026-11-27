import 'package:flutter/material.dart';

import '../services/announcement_service.dart';
import '../theme/app_colors.dart';
import '../widgets/three_d.dart';

/// ऐप खुलते ही दिखने वाली स्क्रीन — फाउंडेशन का लोगो + "जय बाबा सिद्धनाथ"
/// (साथ में आवाज़ भी — `AnnouncementService.welcome()`)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();

    // आवाज़: "जय बाबा सिद्धनाथ"
    AnnouncementService.welcome();

    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [C.headerTop, C.maroon, C.deep],
        ),
      ),
      child: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1).animate(fade),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [C.gold2, C.goldDeep]),
                    boxShadow: [
                      BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
                    ],
                  ),
                  child: const LogoBadge(size: 104),
                ),
                const SizedBox(height: 18),
                const Text(
                  'जय बाबा सिद्धनाथ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: C.creamText,
                    letterSpacing: 0.6,
                    shadows: [Shadow(color: Color(0x99000000), blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'बाबा सिद्धनाथ मंदिर',
                  style: TextStyle(fontSize: 13, color: C.gold2, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                const Text(
                  'जीर्णोद्धार सेवा फाउंडेशन · तेलहारा',
                  style: TextStyle(fontSize: 10, color: C.creamTextDim),
                ),
                const SizedBox(height: 26),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: C.gold2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
