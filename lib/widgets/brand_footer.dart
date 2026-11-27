import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'common.dart';

/// दोनों लोगो के साथ फुटर — होम स्क्रीन और परिचय टैब, दोनों में
class BrandFooter extends StatelessWidget {
  const BrandFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: C.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _LogoBlock(
                  path: 'assets/images/foundation_logo.jpg',
                  label: 'संचालक',
                  name: 'बाबा सिद्धनाथ मंदिर\nजीर्णोद्धार सेवा फाउंडेशन',
                ),
              ),
              Container(width: 1, height: 54, color: C.line),
              Expanded(
                child: _LogoBlock(
                  path: 'assets/images/partner_logo.jpg',
                  label: 'तकनीकी सहयोग',
                  name: 'RGT Memorial\nFoundation',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const MutedText(
            'पंजीकृत धर्मार्थ न्यास · पंजीयन दिनांक 25 जून 2026 · ग्राम/पोस्ट — तेलहारा',
            textAlign: TextAlign.center,
            size: 9.5,
          ),
        ],
      ),
    );
  }
}

class _LogoBlock extends StatelessWidget {
  const _LogoBlock({required this.path, required this.label, required this.name});

  final String path;
  final String label;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            path,
            height: 58,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => const SizedBox(height: 58),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 9, color: C.ink3)),
        const SizedBox(height: 1),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: C.maroon,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
