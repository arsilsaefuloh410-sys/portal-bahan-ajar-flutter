import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';

/// Layar masuk — meniru auth/login.php: tab peran, kolom email/sandi,
/// tombol lihat sandi, dan tombol akun demo.
class LoginScreen extends StatefulWidget {
  final void Function() onLoggedIn;

  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'guru';
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Api.post('login.php', {
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text,
        'role': _role,
      }) as Map<String, dynamic>;

      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      await Session.save(token, user);
      if (mounted) widget.onLoggedIn();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Tidak dapat terhubung ke server. Periksa koneksi dan alamat server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo(String email, String password, String role) {
    setState(() {
      _emailCtrl.text = email;
      _passCtrl.text = password;
      _role = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Identitas sekolah
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Portal Bahan Ajar Informatika',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'SMAN 5 Kota Ternate — silakan masuk menggunakan akun Anda.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Tab peran
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.input,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _roleTab('guru', Icons.person_outline, 'Guru'),
                        _roleTab('admin', Icons.shield_outlined, 'Admin'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      hintText: 'Alamat email',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      hintText: 'Kata sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Text(
                          _obscure ? 'SHOW' : 'HIDE',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('atau', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Masuk cepat dengan akun demo',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _fillDemo('guru@sma5.sch.id', 'GuruInformatika2026!', 'guru'),
                          icon: const Icon(Icons.person, size: 18),
                          label: const Text('Guru'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _fillDemo('admin@sma5.sch.id', 'MgmpInformatika2026!', 'admin'),
                          icon: const Icon(Icons.shield, size: 18),
                          label: const Text('Admin'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleTab(String role, IconData icon, String label) {
    final active = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: active ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
