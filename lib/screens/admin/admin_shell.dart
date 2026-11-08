import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../home_screen.dart';
import 'topik_manage_screen.dart';
import 'users_screen.dart';

/// Shell panel admin: tab Kelola Topik, Kelola Akun, dan pratinjau Katalog guru.
class AdminShell extends StatefulWidget {
  final void Function() onLoggedOut;

  const AdminShell({super.key, required this.onLoggedOut});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  Future<void> _logout() async {
    try {
      await Api.post('logout.php', {});
    } catch (_) {
      // token mungkin sudah kedaluwarsa — tetap bersihkan sesi lokal
    }
    await Session.clear();
    if (mounted) widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TopikManageScreen(),
      const UsersScreen(),
      HomeScreen(onLoggedOut: widget.onLoggedOut, embedded: true),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _navItem(0, Icons.topic_outlined, Icons.topic, 'Topik'),
                _navItem(1, Icons.people_outline, Icons.people, 'Akun'),
                _navItem(2, Icons.menu_book_outlined, Icons.menu_book, 'Katalog'),
                const Spacer(),
                IconButton(
                  tooltip: 'Keluar',
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: AppColors.textMuted, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, IconData activeIcon, String label) {
    final active = _index == i;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = i),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? activeIcon : icon, size: 22, color: active ? AppColors.primary : AppColors.textMuted),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
