import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/elemen.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import 'topik_detail_manage_screen.dart';

/// Kelola daftar topik/bab (mirror admin/topik.php): saringan kelas,
/// tambah, edit, hapus, dan pintu ke pengelolaan berkas + referensi.
class TopikManageScreen extends StatefulWidget {
  const TopikManageScreen({super.key});

  @override
  State<TopikManageScreen> createState() => _TopikManageScreenState();
}

class _TopikManageScreenState extends State<TopikManageScreen> {
  List<Kelas> _kelas = [];
  List<Topik> _topik = [];
  int _filterKelasId = 0;
  int _defaultUrutan = 1;
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
      final data = await Api.get('admin/topik.php', query: {
        if (_filterKelasId > 0) 'kelas_id': '$_filterKelasId',
      }) as Map<String, dynamic>;

      setState(() {
        _kelas = (data['kelas'] as List)
            .map((e) => Kelas.fromJson(e as Map<String, dynamic>))
            .toList();
        _topik = (data['topik'] as List)
            .map((e) => Topik.fromJson(e as Map<String, dynamic>))
            .toList();
        _defaultUrutan = (data['default_urutan'] as num?)?.toInt() ?? 1;
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

  Future<void> _simpan({
    int? id,
    required int kelasId,
    required String judul,
    required String elemen,
    required String deskripsi,
    required int urutan,
  }) async {
    try {
      await Api.post('admin/topik.php', {
        'action': id == null ? 'add' : 'edit',
        'id': ?id,
        'kelas_id': kelasId,
        'judul_topik': judul,
        'elemen': elemen,
        'deskripsi': deskripsi,
        'urutan': urutan,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(id == null ? 'Topik berhasil ditambahkan.' : 'Perubahan topik disimpan.')),
        );
      }
      _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _hapus(Topik topik) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Topik?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus bab "${topik.judulTopik}"?\n\n'
          'Seluruh berkas bahan ajar dan referensi di dalamnya akan ikut terhapus.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await Api.post('admin/topik.php', {'action': 'delete', 'id': topik.id});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topik beserta berkas dan referensinya dihapus.')),
        );
      }
      _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _form({Topik? existing}) {
    if (_kelas.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => _TopikFormDialog(
        kelas: _kelas,
        existing: existing,
        defaultUrutan: _defaultUrutan,
        filterKelasId: _filterKelasId,
        onSave: (params) => _simpan(
          id: existing?.id,
          kelasId: params.kelasId,
          judul: params.judul,
          elemen: params.elemen,
          deskripsi: params.deskripsi,
          urutan: params.urutan,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Topik & Materi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _kelas.isEmpty ? null : () => _form(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Bab'),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          // Saringan kelas
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saring Jenjang:',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip(0, 'Semua Kelas'),
                    ..._kelas.map((k) => _filterChip(k.id, k.namaKelas)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Menampilkan ${_topik.length} topik',
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_topik.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 44),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.folder_open, size: 44, color: AppColors.textLight),
                  SizedBox(height: 10),
                  Text('Belum ada topik pada filter ini.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
                ],
              ),
            )
          else
            ..._topik.map((t) => _topikTile(t)),
        ],
      ),
    );
  }

  Widget _filterChip(int id, String label) {
    final active = _filterKelasId == id;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: active,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: active ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w600),
      onSelected: (_) {
        setState(() => _filterKelasId = id);
        _load();
      },
    );
  }

  Widget _topikTile(Topik t) {
    final info = Elemen.info(t.elemen);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: AppColors.input, borderRadius: BorderRadius.circular(6)),
                child: Text('Bab ${t.urutan}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMain)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: info.bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: info.warna.withValues(alpha: 0.3)),
                ),
                child: Text(info.kode,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: info.warna)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(t.namaKelas,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.judulTopik,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textMain)),
          const SizedBox(height: 4),
          Text(
            t.deskripsi.isNotEmpty ? t.deskripsi : 'Tanpa deskripsi',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.45),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _countBadge(Icons.file_copy_outlined, '${t.totalFile} Berkas', AppColors.orange),
              const SizedBox(width: 8),
              _countBadge(Icons.link, '${t.totalReferensi} Link', AppColors.primary),
              const Spacer(),
              _actionBtn(Icons.folder_open, 'Kelola Materi', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TopikDetailManageScreen(topik: t)),
                ).then((_) => _load());
              }, filled: true),
              const SizedBox(width: 6),
              _actionBtn(Icons.edit_outlined, 'Edit', () => _form(existing: t)),
              const SizedBox(width: 6),
              _actionBtn(Icons.delete_outline, 'Hapus', () => _hapus(t), danger: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countBadge(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.ice.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMain)),
          ],
        ),
      );

  Widget _actionBtn(IconData icon, String tooltip, VoidCallback onTap, {bool filled = false, bool danger = false}) {
    final color = danger ? const Color(0xFFDC2626) : AppColors.primary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: filled ? null : Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, size: 17, color: filled ? Colors.white : color),
        ),
      ),
    );
  }
}

class _TopikParams {
  final int kelasId;
  final String judul;
  final String elemen;
  final String deskripsi;
  final int urutan;
  const _TopikParams({
    required this.kelasId,
    required this.judul,
    required this.elemen,
    required this.deskripsi,
    required this.urutan,
  });
}

class _TopikFormDialog extends StatefulWidget {
  final List<Kelas> kelas;
  final Topik? existing;
  final int defaultUrutan;
  final int filterKelasId;
  final void Function(_TopikParams params) onSave;

  const _TopikFormDialog({
    required this.kelas,
    required this.existing,
    required this.defaultUrutan,
    required this.filterKelasId,
    required this.onSave,
  });

  @override
  State<_TopikFormDialog> createState() => _TopikFormDialogState();
}

class _TopikFormDialogState extends State<_TopikFormDialog> {
  late final TextEditingController _judul;
  late final TextEditingController _deskripsi;
  late final TextEditingController _urutan;
  late int _kelasId;
  late String _elemen;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _judul = TextEditingController(text: ex?.judulTopik ?? '');
    _deskripsi = TextEditingController(text: ex?.deskripsi ?? '');
    _urutan = TextEditingController(text: '${ex?.urutan ?? widget.defaultUrutan}');
    _kelasId = ex?.kelasId ??
        (widget.filterKelasId > 0
            ? widget.filterKelasId
            : widget.kelas.first.id);
    _elemen = ex?.elemen ?? Elemen.list.first.kode;
  }

  @override
  void dispose() {
    _judul.dispose();
    _deskripsi.dispose();
    _urutan.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_judul.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi judul topik.')),
      );
      return;
    }
    setState(() => _saving = true);
    widget.onSave(_TopikParams(
      kelasId: _kelasId,
      judul: _judul.text.trim(),
      elemen: _elemen,
      deskripsi: _deskripsi.text.trim(),
      urutan: int.tryParse(_urutan.text) ?? 1,
    ));
    // Beri waktu request selesai sebelum menutup dialog
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Bab / Topik' : 'Tambah Bab / Topik Baru'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _judul,
                decoration: const InputDecoration(labelText: 'Judul Topik / Bab', hintText: 'Contoh: Berpikir Komputasional'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _kelasId,
                decoration: const InputDecoration(labelText: 'Jenjang Kelas'),
                items: widget.kelas
                    .map((k) => DropdownMenuItem(value: k.id, child: Text(k.namaKelas)))
                    .toList(),
                onChanged: (v) => setState(() => _kelasId = v ?? _kelasId),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _elemen,
                decoration: const InputDecoration(labelText: 'Elemen Kurikulum'),
                items: Elemen.list
                    .map((e) => DropdownMenuItem(value: e.kode, child: Text('${e.kode} — ${e.nama}')))
                    .toList(),
                onChanged: (v) => setState(() => _elemen = v ?? _elemen),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urutan,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nomor Urut Bab'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _deskripsi,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi / Penjelasan Konsep',
                  hintText: 'Tuliskan penjelasan materi dengan bahasa sederhana...',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Simpan Perubahan' : 'Simpan'),
        ),
      ],
    );
  }
}
