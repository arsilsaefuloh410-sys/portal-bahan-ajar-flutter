import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.load();
  runApp(const PortalApp());
}

class PortalApp extends StatefulWidget {
  const PortalApp({super.key});

  @override
  State<PortalApp> createState() => _PortalAppState();
}

class _PortalAppState extends State<PortalApp> {
  late bool _loggedIn;

  @override
  void initState() {
    super.initState();
    _loggedIn = Session.isLoggedIn;
  }

  void _refresh() => setState(() => _loggedIn = Session.isLoggedIn);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portal Bahan Ajar Informatika',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: !_loggedIn
          ? LoginScreen(onLoggedIn: _refresh)
          : (Session.isAdmin
              ? AdminShell(onLoggedOut: _refresh)
              : HomeScreen(onLoggedOut: _refresh)),
    );
  }
}
