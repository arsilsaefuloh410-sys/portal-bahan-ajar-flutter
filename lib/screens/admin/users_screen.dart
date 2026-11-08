import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';

/// Kelola akun pengguna (mirror admin/users.php): daftar + filter,
/// tambah, edit, aktif/nonaktifkan, reset sandi, dan hapus.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _users = [];
  int _totalSemua = 0, _totalGuru = 0, _totalAdmin = 0, _totalPending = 0;
  String _filter = 'all';
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Api.get('admin/users.php', query: {
        'filter': _filter,
        if (_query.isNotEmpty) 'q': _query,
      }) as Map<String, dynamic>;

      setState(() {
        _users = (data['users'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _totalSemua = (data['total_semua'] as num?)?.toInt() ?? 0;
        _totalGuru = (data['total_guru'] as num?)?.toInt() ?? 0;
        _totalAdmin = (data['total_admin'] as num?)?.toInt() ?? 0;
        _totalPending = (data['total_pending'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Tidak dapat terhubung ke server.';
        _loading = false;
      });
    }
  }

  Future<bool> _aksi(String action, Map<String, dynamic> body, String pesanSukses) async {
    try {
      await Api.post('admin/users.php', {'action': action, ...body});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesanSukses)));
      }
      _load();
      return true;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return false;
    }
  }

  Future<void> _toggle(Map<String, dynamic> u) async {
    final aktif = u['status'] == 'aktif';
    final ok = await _konfirmasi(
      aktif ? 'Nonaktifkan akun ${u['nama']}?' : 'Verifikasi dan aktifkan akun ${u['nama']}?',
    );
    if (ok != true) return;
    await _aksi(
      'toggle_status',
      {'user_id': u['id']},
      aktif ? 'Akun ${u['nama']} dinonaktifkan.' : 'Akun ${u['nama']} diaktifkan.',
    );
  }

  Future<void> _hapus(Map<String, dynamic> u) async {
    final ok = await _konfirmasi('Hapus permanen akun ${u['nama']} dari sistem?');
    if (ok != true) return;
    await _aksi('delete', {'user_id': u['id']}, 'Akun ${u['nama']} dihapus.');
  }

  Future<void> _resetSandi(Map<String, dynamic> u) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Sandi: ${u['nama']}'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: ctrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Kata Sandi Baru',
              hintText: 'Minimal 8 karakter + huruf & angka',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset Sandi')),
        ],
      ),
    );
    if (ok != true) return;
    await _aksi(
      'reset_password',
      {'user_id': u['id'], 'new_password': ctrl.text.trim()},
      'Kata sandi ${u['nama']} berhasil di-reset.',
    );
  }

  Future<void> _form({Map<String, dynamic>? existing}) async {
    final namaCtrl = TextEditingController(text: existing?['nama'] as String? ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] as String? ?? '');
    final passCtrl = TextEditingController();
    String role = existing?['role'] as String? ?? 'guru';
    String status = existing?['status'] as String? ?? 'aktif';
    final isEdit = existing != null;
    final isSelf = existing?['is_self'] == true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(isEdit ? 'Edit Akun: ${existing['nama']}' : 'Buat Akun Baru'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelf)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.ice.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'Anda menyunting akun Anda sendiri. Peran dan status dikunci agar akses tetap aman.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  TextField(
                    controller: namaCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap & Gelar'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Alamat Email'),
                  ),
                  if (!isEdit) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata Sandi Awal',
                        hintText: 'Minimal 8 karakter + huruf & angka',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Peran'),
                    items: const [
                      DropdownMenuItem(value: 'guru', child: Text('Guru (hanya akses materi)')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrator (akses penuh)')),
                    ],
                    onChanged: isSelf
                        ? null
                        : (v) => setDialog(() => role = v ?? 'guru'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status Akun'),
                    items: const [
                      DropdownMenuItem(value: 'aktif', child: Text('Aktif (dapat masuk)')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending / nonaktif')),
                    ],
                    onChanged: isSelf
                        ? null
                        : (v) => setDialog(() => status = v ?? 'aktif'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Simpan Perubahan' : 'Buat Akun'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    if (isEdit) {
      await _aksi(
        'edit',
        {
          'user_id': existing['id'],
          'nama': namaCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'role': role,
          'status': status,
        },
        'Data akun ${namaCtrl.text.trim()} diperbarui.',
      );
    } else {
      await _aksi(
        'add',
        {
          'nama': namaCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'password': passCtrl.text,
          'role': role,
          'status': status,
        },
        'Akun baru berhasil dibuat.',
      );
    }
  }

  Future<bool?> _konfirmasi(String pesan) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Konfirmasi'),
          content: Text(pesan),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Ya, Lanjutkan'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Akun Pengguna')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Akun Baru'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          // Banner pending
          if (_totalPending > 0 && _filter != 'pending')
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_off_outlined, color: Color(0xFFB45309)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Terdapat $_totalPending akun menunggu persetujuan / nonaktif!',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _filter = 'pending');
                      _load();
                    },
                    child: const Text('Tinjau', style: TextStyle(color: Color(0xFFB45309))),
                  ),
                ],
              ),
            ),

          // Pencarian
          TextField(
            textInputAction: TextInputAction.search,
            onSubmitted: (v) {
              setState(() => _query = v.trim());
              _load();
            },
            decoration: const InputDecoration(
              hintText: 'Cari nama atau email...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.subdirectory_arrow_right),
            ),
          ),
          const SizedBox(height: 12),

          // Tab filter
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tab('all', 'Semua ($_totalSemua)'),
              _tab('guru', 'Guru ($_totalGuru)'),
              _tab('admin', 'Admin ($_totalAdmin)'),
              _tab('pending', 'Pending ($_totalPending)'),
            ],
          ),
          const SizedBox(height: 14),

          if (_users.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 44),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.people_outline, size: 44, color: AppColors.textLight),
                  SizedBox(height: 10),
                  Text('Tidak ada akun pada saringan ini.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
                ],
              ),
            )
          else
            ..._users.map((u) => _userTile(u)),
        ],
      ),
    );
  }

  Widget _tab(String value, String label) {
    final active = _filter == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: active,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: active ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w600),
      onSelected: (_) {
        setState(() => _filter = value);
        _load();
      },
    );
  }

  Widget _userTile(Map<String, dynamic> u) {
    final isAdmin = u['role'] == 'admin';
    final isAktif = u['status'] == 'aktif';
    final isSelf = u['is_self'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAktif ? AppColors.surface : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAktif ? AppColors.border : const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isAdmin ? AppColors.primary : const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  isAdmin ? Icons.shield : Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(u['nama'] as String? ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.ice,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text('Akun Anda',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ),
                        ],
                      ],
                    ),
                    Text(u['email'] as String? ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _tag(
                isAdmin ? 'Admin (CRUD Penuh)' : 'Guru (Akses Materi)',
                isAdmin ? AppColors.primary : const Color(0xFF059669),
              ),
              const SizedBox(width: 8),
              _tag(
                isAktif ? 'Aktif' : 'Pending',
                isAktif ? const Color(0xFF059669) : const Color(0xFFD97706),
              ),
              const Spacer(),
              if (!isSelf)
                IconButton(
                  tooltip: isAktif ? 'Nonaktifkan' : 'Aktifkan',
                  onPressed: () => _toggle(u),
                  icon: Icon(
                    isAktif ? Icons.pause_circle_outline : Icons.check_circle_outline,
                    size: 20,
                    color: isAktif ? const Color(0xFFD97706) : const Color(0xFF059669),
                  ),
                ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () => _form(existing: u),
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
              ),
              IconButton(
                tooltip: 'Reset sandi',
                onPressed: () => _resetSandi(u),
                icon: const Icon(Icons.key, size: 20, color: AppColors.textMuted),
              ),
              if (!isSelf)
                IconButton(
                  tooltip: 'Hapus',
                  onPressed: () => _hapus(u),
                  icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
      );
}
