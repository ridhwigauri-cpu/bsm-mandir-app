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

class _TabItem {
  const _TabItem(this.key, this.label, this.icon);

  final String key;
  final String label;
  final String icon;
}

const List<_TabItem> _tabs = [
  _TabItem('home', 'होम', 'home'),
  _TabItem('daan', 'दान', 'heart'),
  _TabItem('darshan', 'दर्शन', 'video'),
  _TabItem('puja', 'पूजा', 'temple'),
  _TabItem('dharamshala', 'धर्मशाला', 'bed'),
  _TabItem('about', 'परिचय', 'info'),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: C.deep,
        border: Border(bottom: BorderSide(color: Color(0x4DE8B54A))),
      ),
      child: Row(
        children: [
          if (showBack)
            _CircleIcon(icon: 'close', onTap: onBack, active: false)
          else
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle),
              child: const Text(
                'ॐ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.maroon),
              ),
            ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: C.creamText,
                  ),
                ),
                Text(
                  'जीर्णोद्धार सेवा फाउंडेशन · v1.0',
                  maxLines: 1,
                  style: TextStyle(fontSize: 10, color: C.creamTextDim),
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
    return Container(
      decoration: const BoxDecoration(
        color: C.paper,
        border: Border(top: BorderSide(color: C.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final t in _tabs)
              Expanded(
                child: InkWell(
                  onTap: () => onSelect(t.key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: current == t.key ? C.amber2 : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AppIcon(
                            t.icon,
                            size: 19,
                            color: current == t.key ? C.maroon2 : const Color(0xFF9A8288),
                          ),
                        ),
                        Text(
                          t.label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: current == t.key ? FontWeight.w700 : FontWeight.w600,
                            color: current == t.key ? C.maroon2 : const Color(0xFF9A8288),
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
    );
  }
}
