import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'screens/about_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/daan_screen.dart';
import 'screens/darshan_screen.dart';
import 'screens/dharamshala_screen.dart';
import 'screens/home_screen.dart';
import 'screens/puja_screen.dart';
import 'screens/security_screen.dart';
import 'theme/app_colors.dart';
import 'widgets/common.dart';
import 'widgets/three_d.dart';

class _TabItem {
  const _TabItem(this.key, this.label, this.icon);

  final String key;
  final String label;
  final String icon;
}

const List<_TabItem> _tabs = [
  _TabItem('home', 'होम', 'home'),
  _TabItem('daan', 'दान', 'rupee'),
  _TabItem('darshan', 'दर्शन', 'eye'),
  _TabItem('puja', 'पूजा', 'lamp'),
  _TabItem('dharamshala', 'धर्मशाला', 'bed'),
  _TabItem('about', 'परिचय', 'book'),
];

/// ऐप का ढाँचा: हेडर + बॉटम टैब + एडमिन/AI सुरक्षा व्यू
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  String _view = 'app'; // app | adminLogin | admin | security
  String _tab = 'home';
  bool _adminLogged = false;

  void _openAdmin() {
    setState(() => _view = _adminLogged ? 'admin' : 'adminLogin');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      backgroundColor: C.maroon,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              showBack: _view != 'app',
              activeSecurity: _view == 'security',
              activeAdmin: _view == 'admin' || _view == 'adminLogin',
              onBack: () => setState(() => _view = 'app'),
              onSecurity: () => setState(() => _view = _view == 'security' ? 'app' : 'security'),
              onAdmin: _openAdmin,
            ),
            Expanded(child: _body(state)),
            if (_view == 'app') _BottomTabs(current: _tab, onSelect: (t) => setState(() => _tab = t)),
          ],
        ),
      ),
    );
  }

  Widget _body(AppState state) {
    switch (_view) {
      case 'adminLogin':
        return AdminLoginScreen(
          onLogin: () => setState(() {
            _adminLogged = true;
            _view = 'admin';
          }),
          onCancel: () => setState(() => _view = 'app'),
        );
      case 'admin':
        return AdminScreen(
          state: state,
          onSecurity: () => setState(() => _view = 'security'),
          onLogout: () => setState(() {
            _adminLogged = false;
            _view = 'adminLogin';
          }),
        );
      case 'security':
        return SecurityScreen(state: state);
      default:
        return IndexedStack(
          index: _tabs.indexWhere((t) => t.key == _tab),
          children: [
            HomeScreen(state: state, onTab: (t) => setState(() => _tab = t)),
            DaanScreen(state: state),
            const DarshanScreen(),
            PujaScreen(state: state),
            DharamshalaScreen(state: state),
            const AboutScreen(),
          ],
        );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.showBack,
    required this.activeSecurity,
    required this.activeAdmin,
    required this.onBack,
    required this.onSecurity,
    required this.onAdmin,
  });

  final bool showBack;
  final bool activeSecurity;
  final bool activeAdmin;
  final VoidCallback onBack;
  final VoidCallback onSecurity;
  final VoidCallback onAdmin;

  @override
  Widget build(BuildContext context) {
    return ThreeDPanel(
      radius: 0,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      colors: const [C.headerTop, C.headerMid, C.headerBottom],
      borderColor: C.gold,
      child: Row(
        children: [
          if (showBack)
            _CircleIcon(icon: 'close', onTap: onBack, active: false)
          else
            const LogoBadge(size: 40),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'बाबा सिद्धनाथ मंदिर',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: C.creamText,
                    shadows: [Shadow(color: Color(0x88000000), blurRadius: 4)],
                  ),
                ),
                Text(
                  'जीर्णोद्धार सेवा फाउंडेशन · तेलहारा',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5, color: C.gold2, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          _CircleIcon(icon: 'shield', onTap: onSecurity, active: activeSecurity),
          const SizedBox(width: 6),
          _CircleIcon(icon: 'lock', onTap: onAdmin, active: activeAdmin),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap, required this.active});

  final String icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? C.gold : const Color(0x24E8B54A),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Center(
            child: AppIcon(icon, size: 16, color: active ? C.onGold : C.gold2),
          ),
        ),
      ),
    );
  }
}

class _BottomTabs extends StatelessWidget {
  const _BottomTabs({required this.current, required this.onSelect});

  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ThreeDPanel(
      radius: 0,
      padding: EdgeInsets.zero,
      colors: const [C.headerMid, C.headerBottom],
      borderColor: C.gold,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              for (final t in _tabs)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelect(t.key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // उभरा हुआ (3D) आइकन बटन
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              gradient: current == t.key
                                  ? const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [C.gold2, C.gold],
                                    )
                                  : null,
                              color: current == t.key ? null : const Color(0x22FFFFFF),
                              border: Border.all(
                                color: current == t.key
                                    ? C.goldDeep
                                    : const Color(0x33FFFFFF),
                                width: 1,
                              ),
                              boxShadow: current == t.key
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x66000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: AppIcon(
                              t.icon,
                              size: 18,
                              color: current == t.key ? C.deep : C.gold2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            t.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight:
                                  current == t.key ? FontWeight.w800 : FontWeight.w600,
                              color: current == t.key ? C.gold2 : C.creamTextDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
