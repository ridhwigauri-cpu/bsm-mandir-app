import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/three_d.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key, required this.onLogin, required this.onCancel});

  final VoidCallback onLogin;
  final VoidCallback onCancel;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _pin = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    if (_pin.text == '1088') {
      widget.onLogin();
    } else {
      setState(() {
        _error = 'गलत पिन — डेमो पिन 1088 है';
        _pin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: BsmCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [C.gold2, C.goldDeep]),
                    boxShadow: [
                      BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const LogoBadge(size: 72),
                ),
                const SizedBox(height: 12),
                const Text(
                  'एडमिन लॉगिन — ट्रस्ट प्रबंधक',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: C.maroon),
                ),
                const SizedBox(height: 4),
                const MutedText(
                  'दान, खर्च, परियोजना, वेतन व सुरक्षा — सब एक ही लॉगिन में',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: C.maroon,
                    letterSpacing: 8,
                  ),
                  decoration: const InputDecoration(
                    hintText: '••••',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                BsmButton(label: 'लॉगिन करें', kind: BtnKind.dark, onPressed: _submit),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: C.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const MutedText(
                  'डेमो पिन: 1088 · असली ऐप में यह OTP + डिवाइस सत्यापन से होगा',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                BsmButton(
                  label: 'भक्त ऐप पर वापस',
                  kind: BtnKind.ghost,
                  small: true,
                  icon: 'close',
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
