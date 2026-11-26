import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_state.dart';
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
        home: const RootShell(),
      ),
    );
  }
}
