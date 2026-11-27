import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 3D टेक्सचर — हल्की तिरछी लकीरें (कपड़ा/धातु जैसा एहसास)
class _TexturePainter extends CustomPainter {
  const _TexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 1.2;
    for (double x = -size.height; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
    final p2 = Paint()
      ..color = const Color(0x0D000000)
      ..strokeWidth = 1.2;
    for (double x = -size.height; x < size.width; x += 27) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// उभरी हुई (3D) नारंगी-गोल्ड सतह
class ThreeDPanel extends StatelessWidget {
  const ThreeDPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 18,
    this.colors = const [C.headerTop, C.headerMid, C.headerBottom],
    this.borderColor = C.gold,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final List<Color> colors;
  final Color borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(color: borderColor.withValues(alpha: 0.75), width: 1.2),
        boxShadow: shadow
            ? const [
                BoxShadow(color: C.shadowDeep, blurRadius: 14, offset: Offset(0, 5)),
                BoxShadow(color: Color(0x33FFFFFF), blurRadius: 2, offset: Offset(0, -1)),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: const _TexturePainter()),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// किनारों से पंख जैसा घुलता (feathered) बैनर
class FeatheredBanner extends StatelessWidget {
  const FeatheredBanner({
    super.key,
    required this.image,
    required this.title,
    this.subtitle,
    this.height = 172,
    this.badge,
  });

  final String image;
  final String title;
  final String? subtitle;
  final double height;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x2E4A2400), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ऊपर-नीचे किनारे घुलते हैं (feather)
            ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Colors.black,
                  Colors.black,
                  Color(0xFF000000),
                ],
                stops: [0, 0.18, 0.62, 1],
              ).createShader(rect),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const ColoredBox(
                  color: C.cream2,
                  child: Center(
                    child: Icon(Icons.image_outlined, color: C.ink3, size: 28),
                  ),
                ),
              ),
            ),
            // नीचे का अंधेरा हिस्सा — टेक्स्ट पढ़ने योग्य रहे
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      C.deep.withValues(alpha: 0.35),
                      C.deep.withValues(alpha: 0.88),
                    ],
                    stops: const [0.35, 0.66, 1],
                  ),
                ),
              ),
            ),
            // गोल्ड बॉर्डर
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: C.gold.withValues(alpha: 0.55), width: 1.2),
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: C.deep.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: C.gold.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: C.gold2,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: C.creamText,
                      shadows: [Shadow(color: Color(0x99000000), blurRadius: 6)],
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: C.creamTextDim,
                        height: 1.35,
                        shadows: [Shadow(color: Color(0x99000000), blurRadius: 5)],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// गोल लोगो (सुनहरी रिंग के साथ)
class LogoBadge extends StatelessWidget {
  const LogoBadge({
    super.key,
    this.image = 'assets/images/foundation_logo.jpg',
    this.size = 40,
    this.ring = C.gold,
  });

  final String image;
  final double size;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ring, C.goldDeep],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => ColoredBox(
            color: C.deep,
            child: Icon(Icons.temple_hindu_rounded, color: ring, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}
