import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/donation_info.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// दान के लिए QR + UPI + बैंक विवरण कार्ड
/// (दान स्क्रीन और परिचय टैब — दोनों में इस्तेमाल होता है)
class DonationQrCard extends StatelessWidget {
  const DonationQrCard({super.key, this.showBank = true});

  /// बैंक विवरण (NEFT/IMPS) भी दिखाएँ या नहीं
  final bool showBank;

  @override
  Widget build(BuildContext context) {
    return BsmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHead(icon: 'rupee', title: 'QR से सीधे दान करें'),
          const MutedText(
            'नीचे दिया QR किसी भी UPI ऐप से स्कैन करें — राशि सीधे फाउंडेशन के '
            'आधिकारिक खाते में जाती है।',
          ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: () => _zoomQr(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: C.line),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    DonationInfo.qrImage,
                    width: 210,
                    height: 300,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => Container(
                      width: 210,
                      height: 300,
                      color: C.cream2,
                      alignment: Alignment.center,
                      child: const AppIcon('camera', size: 24, color: C.ink3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: MutedText('टैप करके बड़ा करें · PNB · Scan & Pay', size: 9.5),
          ),
          const SizedBox(height: 10),
          _CopyRow(
            label: 'UPI ID',
            value: DonationInfo.upiId,
            mono: true,
          ),
          const SizedBox(height: 6),
          Center(
            child: MutedText(DonationInfo.apps, size: 9.5, textAlign: TextAlign.center),
          ),
          if (showBank) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0x225E0F18)),
            const SizedBox(height: 10),
            const Row(
              children: [
                AppIcon('bank', size: 14, color: C.goldDeep),
                SizedBox(width: 6),
                Text(
                  'सीधे बैंक खाते में (NEFT / IMPS)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: C.maroon,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _CopyRow(label: 'खाता संख्या', value: DonationInfo.accountNo, mono: true),
            _CopyRow(label: 'IFSC', value: DonationInfo.ifsc, mono: true),
            KVRow(left: 'बैंक', right: DonationInfo.bankName),
            KVRow(
              left: 'खाता नाम',
              right: DonationInfo.accountName,
              divider: false,
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: C.amber2,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIcon('info', size: 13, color: C.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'भुगतान के बाद 80G रसीद के लिए UTR/संदर्भ संख्या के साथ फाउंडेशन '
                    'कार्यालय से संपर्क करें — रसीद इसी ऐप से भी जारी होगी।',
                    style: const TextStyle(fontSize: 10, color: C.amber, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _zoomQr(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'स्कैन करके दान करें',
                      style: TextStyle(
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
                maxScale: 5,
                child: Image.asset(
                  DonationInfo.qrImage,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) =>
                      const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('QR चित्र नहीं खुल सका'),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Text(
                'UPI ID: ${DonationInfo.upiId}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.ink2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// मान + कॉपी बटन वाली पंक्ति
class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9.5, color: C.ink3)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: C.maroon,
                    letterSpacing: mono ? 0.4 : 0,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) showToast(context, '$label कॉपी हो गया');
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  const AppIcon('copy', size: 14, color: C.goldDeep),
                  const SizedBox(width: 3),
                  Text(
                    'कॉपी',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: C.goldDeep,
                    ),
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
