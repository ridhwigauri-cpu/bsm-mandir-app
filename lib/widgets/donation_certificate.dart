import 'package:flutter/material.dart';

import '../data/foundation_info.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';

/// दान रसीद — "दान प्रशस्ति पत्र" शैली में
/// ₹5,000 से अधिक → विशेष प्रशस्ति पत्र, वरना सामान्य दान रसीद (वही डिज़ाइन)
class DonationCertificate extends StatelessWidget {
  const DonationCertificate({super.key, required this.donation});

  final Donation donation;

  bool get isCommendation => donation.amt > 5000;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8B54A), Color(0xFFB9862A), Color(0xFFE8B54A)],
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFFFFF9EE),
          border: Border.all(color: const Color(0xCCB9862A), width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── CIN · लोगो · PAN ──
            Row(
              children: [
                Expanded(child: _Chip('CIN : ${FoundationInfo.cin}')),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/foundation_logo.jpg',
                      width: 66,
                      height: 66,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const SizedBox(
                        width: 66,
                        height: 66,
                      ),
                    ),
                  ),
                ),
                Expanded(child: _Chip('PAN : ${FoundationInfo.pan}', alignEnd: true)),
              ],
            ),
            const SizedBox(height: 10),

            // ── मंदिर फ़ोटो + शीर्षक ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: C.goldDeep, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/mandir.jpg',
                      width: 92,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        width: 92,
                        height: 68,
                        color: C.cream2,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 44,
                  height: 1,
                  color: C.goldDeep,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    'ॐ',
                    style: TextStyle(fontSize: 15, color: C.goldDeep, height: 1),
                  ),
                ),
                Container(width: 44, height: 1, color: C.goldDeep),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2A6B),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                isCommendation ? 'दान प्रशस्ति पत्र' : 'दान रसीद',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFF3DC),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isCommendation ? 'Certificate of Commendation' : 'Donation Receipt',
              style: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB01B2E),
              ),
            ),
            const SizedBox(height: 10),

            // ── मुख्य पाठ ──
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 11, height: 1.65, color: C.ink),
                children: [
                  TextSpan(
                    text: isCommendation
                        ? 'यह विशेष प्रशस्ति पत्र आदरणीय '
                        : 'यह रसीद आदरणीय ',
                  ),
                  TextSpan(
                    text: donation.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: C.maroon),
                  ),
                  TextSpan(
                    text: isCommendation
                        ? ' को श्री बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन की ओर से '
                            'आपके बहुमूल्य एवं पुनीत योगदान के लिए अत्यंत आभार प्रकट करने हेतु '
                            'प्रदान किया जाता है। आपके उदार सहयोग ने मंदिर के पुनर्निर्माण और '
                            'सौंदर्यकरण कार्यों को गति प्रदान की है।'
                        : ' को श्री बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन की ओर से '
                            'प्राप्त दान राशि के लिए प्रदान की जाती है। आपके सहयोग हेतु '
                            'हार्दिक आभार — बाबा सिद्धनाथ आपका कल्याण करें।',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isCommendation
                  ? '(यह विशेष प्रशस्ति पत्र ₹5,000/- से अधिक की दान राशि के लिए है)'
                  : '(यह रसीद 80G कर छूट हेतु मान्य है)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB01B2E),
              ),
            ),
            const SizedBox(height: 12),

            // ── राशि + प्रमाण ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CERTIFICATE NUMBER',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: C.ink2,
                        ),
                      ),
                      Text(
                        donation.receipt,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: C.maroon,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'DATE',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: C.ink2,
                        ),
                      ),
                      Text(
                        dateLabel(dateKey(donation.ts)),
                        style: const TextStyle(fontSize: 10.5, color: C.ink),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2A6B),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'सहयोग राशि',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFF3DC),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: C.goldDeep, width: 1.4),
                      ),
                      child: Text(
                        inr(donation.amt),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: C.maroon,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                _Seal(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amountWords(donation.amt),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, color: C.ink2, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: const Color(0x33B9862A)),
            const SizedBox(height: 6),
            const Text(
              'बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन · श्री बजरंगबली धर्मशाला, तेलहाड़ा का अंग\n'
              'Section 8 कंपनी · पंजीयन 25 जून 2026 · तेलहारा (नालंदा), बिहार',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8, color: C.ink3, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.alignEnd = false});

  final String text;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: C.maroon,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFE9B8),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

/// नीला मुहर — CIN + हस्ताक्षर
class _Seal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF3F6FF),
        border: Border.all(color: const Color(0xFF1B2A6B), width: 1.6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'ॐ',
            style: TextStyle(fontSize: 13, color: Color(0xFF1B2A6B), height: 1),
          ),
          const Text(
            'बाबा सिद्धनाथ मंदिर',
            style: TextStyle(
              fontSize: 6,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B2A6B),
            ),
          ),
          const Text(
            'जीर्णोद्धार सेवा फाउंडेशन',
            style: TextStyle(fontSize: 5.5, color: Color(0xFF1B2A6B)),
          ),
          const SizedBox(height: 2),
          Container(width: 40, height: 0.8, color: const Color(0xFF1B2A6B)),
          const SizedBox(height: 2),
          const Text(
            'CIN: U94910BR2026NPL085916',
            style: TextStyle(fontSize: 4.6, color: Color(0xFF1B2A6B)),
          ),
          const SizedBox(height: 1),
          const Text(
            'Auth. Signatory',
            style: TextStyle(
              fontSize: 5.4,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B2A6B),
            ),
          ),
        ],
      ),
    );
  }
}
