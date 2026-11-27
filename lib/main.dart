import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_state.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const BsmApp());

/// बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन — डिजिटल प्रबंधन एवं AI सुरक्षा ऐप
class BsmApp extends StatefulWidget {
  const BsmApp({super.key});

  @override
  State<BsmApp> createState() => _BsmAppState();
}

class _BsmAppState extends State<BsmApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'बाबा सिद्धनाथ मंदिर',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const _SplashGate(),
      ),
    );
  }
}

/// ऐप खुलते ही स्प्लैश (लोगो + "जय बाबा सिद्धनाथ" + आवाज़), फिर मुख्य स्क्रीन
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (!_done) {
      return SplashScreen(onDone: () => setState(() => _done = true));
    }
    return const RootShell();
  }
}
