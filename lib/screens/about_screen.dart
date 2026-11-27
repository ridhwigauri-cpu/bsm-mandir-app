import 'package:flutter/material.dart';

import '../data/foundation_info.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_footer.dart';
import '../widgets/common.dart';
import '../widgets/donation_qr_card.dart';

/// "परिचय" टैब — फाउंडेशन का इतिहास, संस्थापक, परिसर और मूल दस्तावेज़
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BsmScreen(
      children: [
        // ── हीरो ──
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Image.asset(
                'assets/images/mandir.jpg',
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  height: 210,
                  color: C.cream2,
                  alignment: Alignment.center,
                  child: const AppIcon('camera', size: 26, color: C.ink3),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        C.maroon.withValues(alpha: 0.55),
                        C.maroon.withValues(alpha: 0.92),
                      ],
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
                    const Text(
                      'हमारी कहानी',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: C.creamText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'सेवा-भाव से जन्मी संस्था — ${FoundationInfo.sevaSince} से आज तक',
                      style: const TextStyle(fontSize: 11.5, color: C.creamTextDim, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── मुख्य आँकड़े ──
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'temple', title: 'एक नज़र में'),
              Row(
                children: [
                  for (var i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _FactBox(
                        label: FoundationInfo.facts[i].$1,
                        value: FoundationInfo.facts[i].$2,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 2; i < 4; i++) ...[
                    if (i > 2) const SizedBox(width: 8),
                    Expanded(
                      child: _FactBox(
                        label: FoundationInfo.facts[i].$1,
                        value: FoundationInfo.facts[i].$2,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              MutedText(
                '${FoundationInfo.name} · ${FoundationInfo.place}',
                color: C.maroon,
                size: 11,
              ),
            ],
          ),
        ),

        // ── इतिहास ──
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'clock', title: 'सेवा-इतिहास (क्रमवार)'),
              for (var i = 0; i < FoundationInfo.timeline.length; i++)
                _TimelineTile(
                  event: FoundationInfo.timeline[i],
                  isLast: i == FoundationInfo.timeline.length - 1,
                ),
            ],
          ),
        ),

        // ── संस्थापक एवं उत्तराधिकारी ──
        for (final p in FoundationInfo.people) _PersonCard(person: p),

        // ── सहयोगी जन ──
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'users', title: 'जिनका योगदान स्मरणीय है'),
              for (final c in FoundationInfo.contributors)
                KVRow(left: c.$1, right: c.$2, divider: c != FoundationInfo.contributors.last),
              const SizedBox(height: 8),
              const MutedText(
                'इन सभी के सहयोग एवं आशीर्वाद से ही मंदिर की सेवा निरंतर चल रही है। '
                'संस्था इन्हें सदैव कृतज्ञतापूर्वक स्मरण करती है।',
              ),
            ],
          ),
        ),

        // ── परिसर ──
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'camera', title: 'मंदिर परिसर'),
              for (final c in FoundationInfo.campus) ...[
                _ImageWithCaption(path: c.$1, title: c.$2, caption: c.$3),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),

        // ── पंजीयन एवं प्रमाण ──
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'shield', title: 'पंजीयन एवं प्रमाण'),
              const MutedText(
                'संस्था भारत सरकार (MCA) के अंतर्गत Section 8 कंपनी के रूप में पंजीकृत है — '
                'नीचे दिए प्रमाण-पत्र टैप करके पूरे आकार में पढ़े जा सकते हैं।',
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < FoundationInfo.registration.length; i++)
                KVRow(
                  left: FoundationInfo.registration[i].$1,
                  right: FoundationInfo.registration[i].$2,
                  divider: i != FoundationInfo.registration.length - 1,
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: C.green2,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0x331E7A46)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppIcon('check', size: 14, color: C.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        FoundationInfo.verifyNote,
                        style: const TextStyle(fontSize: 10, color: C.green, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _DocGrid(
                docs: FoundationInfo.registrationDocs,
                onTap: (doc) => _openDoc(context, doc),
              ),
            ],
          ),
        ),

        // ── दान (QR / बैंक) ──
        const DonationQrCard(),

        // ── आम सूचना ──
        BsmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHead(icon: 'file', title: 'मूल दस्तावेज़ — आम सूचना'),
              const MutedText(
                'दिनांक ${FoundationInfo.noticeDate} को जारी आम सूचना के दोनों पृष्ठ — '
                'टैप करके पूरा पढ़ें।',
              ),
              const SizedBox(height: 10),
              _DocGrid(
                docs: FoundationInfo.notices,
                onTap: (doc) => _openDoc(context, doc),
              ),
            ],
          ),
        ),

        // ── फुटर (लोगो) ──
        const BrandFooter(),
      ],
    );
  }

  void _openDoc(BuildContext context, RegDoc doc) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.cream,
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      doc.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: C.maroon,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: C.maroon),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.asset(
                  doc.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) =>
                      const Center(child: Text('दस्तावेज़ नहीं खुल सका')),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/* ---------------- छोटे हिस्से ---------------- */

class _FactBox extends StatelessWidget {
  const _FactBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: C.cream2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9.5, color: C.ink3)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: C.maroon,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event, required this.isLast});

  final TimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // टाइमलाइन लाइन + बिंदु
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: event.highlight ? C.gold : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: event.highlight ? C.goldDeep : C.maroon3, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: const Color(0x335E0F18)),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: event.highlight ? C.gold : C.amber2,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          event.year,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: event.highlight ? C.onGold : C.amber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: C.maroon,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.body,
                    style: const TextStyle(fontSize: 11.5, color: C.ink2, height: 1.55),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person});

  final PersonInfo person;

  @override
  Widget build(BuildContext context) {
    return BsmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHead(icon: 'users', title: person.role),
          if (person.images.length == 2)
            Row(
              children: [
                for (var i = 0; i < person.images.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _Portrait(path: person.images[i], height: 190),
                  ),
                ],
              ],
            )
          else
            _Portrait(path: person.images.first, height: 230),
          const SizedBox(height: 10),
          Text(
            person.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: C.maroon,
            ),
          ),
          Text(person.sub, style: const TextStyle(fontSize: 10.5, color: C.ink3)),
          const SizedBox(height: 6),
          Text(
            person.body,
            style: const TextStyle(fontSize: 11.5, color: C.ink2, height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _Portrait extends StatelessWidget {
  const _Portrait({required this.path, required this.height});

  final String path;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        path,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stack) => Container(
          height: height,
          width: double.infinity,
          color: C.cream2,
          alignment: Alignment.center,
          child: const AppIcon('camera', size: 22, color: C.ink3),
        ),
      ),
    );
  }
}

class _ImageWithCaption extends StatelessWidget {
  const _ImageWithCaption({
    required this.path,
    required this.title,
    required this.caption,
  });

  final String path;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            path,
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              height: 170,
              color: C.cream2,
              alignment: Alignment.center,
              child: const AppIcon('camera', size: 22, color: C.ink3),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: C.maroon,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(child: MutedText(caption)),
          ],
        ),
      ],
    );
  }
}

class _DocGrid extends StatelessWidget {
  const _DocGrid({required this.docs, required this.onTap});

  final List<RegDoc> docs;
  final void Function(RegDoc) onTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < docs.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _DocTile(doc: docs[i], onTap: () => onTap(docs[i]))),
            const SizedBox(width: 8),
            Expanded(
              child: i + 1 < docs.length
                  ? _DocTile(doc: docs[i + 1], onTap: () => onTap(docs[i + 1]))
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < docs.length) rows.add(const SizedBox(height: 8));
    }
    return Column(children: rows);
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.doc, required this.onTap});

  final RegDoc doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      color: C.cream2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  doc.image,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stack) => Container(
                    height: 150,
                    color: C.cream2,
                    alignment: Alignment.center,
                    child: const AppIcon('file', size: 22, color: C.ink3),
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xB35E0F18),
                      shape: BoxShape.circle,
                    ),
                    child: const AppIcon('search', size: 11, color: C.creamText),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: C.maroon,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    doc.sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 8.5, color: C.ink3, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
