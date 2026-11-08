import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/api_client.dart';
import '../../core/file_actions.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

/// Pengelolaan berkas & referensi per topik (mirror admin/topik_detail.php):
/// unggah/hapus berkas PPT/PDF dan tambah/hapus tautan referensi.
class TopikDetailManageScreen extends StatefulWidget {
  final Topik topik;

  const TopikDetailManageScreen({super.key, required this.topik});

  @override
  State<TopikDetailManageScreen> createState() => _TopikDetailManageScreenState();
}

class _TopikDetailManageScreenState extends State<TopikDetailManageScreen> {
  List<FileMateri> _files = [];
  List<Referensi> _refs = [];
  bool _loading = true;
  bool _uploading = false;
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
      final data = await Api.get('topik.php', query: {'id': '${widget.topik.id}'})
          as Map<String, dynamic>;
      final detail = TopikDetail.fromJson(data);
      setState(() {
        _files = detail.files;
        _refs = detail.referensi;
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

  Future<void> _unggah() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'ppt', 'pptx'],
    );
    if (picked.isEmpty) return;
    final file = picked.first;
    final path = file.path;
    if (path == null) return;

    setState(() => _uploading = true);
    try {
      final fileName = file.name;
      await Api.postMultipart(
        'admin/berkas.php',
        fields: {'action': 'upload_file', 'topik_id': '${widget.topik.id}'},
        fileField: 'file_berkas',
        filePath: path,
        fileName: fileName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Berkas "$fileName" berhasil diunggah.')));
      }
      _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Gagal mengunggah berkas.')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _hapusBerkas(FileMateri file) async {
    final ok = await _confirm('Hapus berkas "${file.namaFile}"?');
    if (ok != true) return;
    try {
      await Api.post('admin/berkas.php', {
        'action': 'delete_file',
        'topik_id': widget.topik.id,
        'file_id': file.id,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berkas dihapus.')));
      }
      _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _tambahReferensi() async {
    final judulCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Tautan Referensi'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: judulCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul tautan',
                  hintText: 'Misal: Buku Panduan Kemdikbud',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Alamat URL',
                  hintText: 'https://contoh-link-belajar.com',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tambah')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await Api.post('admin/referensi.php', {
        'action': 'add',
        'topik_id': widget.topik.id,
        'judul_link': judulCtrl.text.trim(),
        'url': urlCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Tautan referensi ditambahkan.')));
      }
      _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _hapusReferensi(Referensi ref) async {
    final ok = await _confirm('Hapus tautan "${ref.judulLink}"?');
    if (ok != true) return;
    try {
      await Api.post('admin/referensi.php', {
        'action': 'delete',
        'topik_id': widget.topik.id,
        'ref_id': ref.id,
      });
      _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<bool?> _confirm(String message) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Konfirmasi'),
          content: Text(message),
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

  Future<void> _unduh(FileMateri file) async {
    try {
      await downloadAndOpen('unduh.php?id=${file.id}', file.namaFile);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Gagal mengunduh atau membuka berkas.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.topik;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kelola Materi'),
            Text(
              '${t.namaKelas} • Bab ${t.urutan}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Info topik
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.judulTopik,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                            const SizedBox(height: 6),
                            Text(
                              t.deskripsi.isNotEmpty ? t.deskripsi : 'Belum ada deskripsi topik.',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Berkas
                      _panel(
                        title: 'Berkas Bahan Ajar',
                        count: '${_files.length} Berkas',
                        icon: Icons.file_upload_outlined,
                        iconColor: const Color(0xFFDC2626),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _uploading ? null : _unggah,
                                icon: _uploading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.folder_open),
                                label: Text(_uploading ? 'Mengunggah...' : 'Pilih & Unggah Berkas'),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Format PDF / PPT / PPTX • Maks. 20 MB per file',
                              style: TextStyle(fontSize: 11, color: AppColors.textLight),
                            ),
                            const SizedBox(height: 12),
                            if (_files.isEmpty)
                              const _Kosong('Belum ada berkas untuk bab ini.')
                            else
                              ..._files.map((f) => _fileRow(f)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Referensi
                      _panel(
                        title: 'Tautan Referensi Eksternal',
                        count: '${_refs.length} Tautan',
                        icon: Icons.link,
                        iconColor: AppColors.primary,
                        child: Column(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _tambahReferensi,
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Tautan'),
                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                            ),
                            const SizedBox(height: 12),
                            if (_refs.isEmpty)
                              const _Kosong('Belum ada tautan pada bab ini.')
                            else
                              ..._refs.map((r) => _refRow(r)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _panel({
    required String title,
    required String count,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child:
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(count,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: iconColor)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _fileRow(FileMateri f) {
    final isPdf = f.isPdf;
    final color = isPdf ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(isPdf ? Icons.picture_as_pdf : Icons.slideshow, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.namaFile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text('${formatBytes(f.ukuranFile)} • ${f.downloadCount}x diunduh',
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Unduh',
            onPressed: () => _unduh(f),
            icon: const Icon(Icons.download, size: 19, color: AppColors.primary),
          ),
          IconButton(
            tooltip: 'Hapus',
            onPressed: () => _hapusBerkas(f),
            icon: const Icon(Icons.delete_outline, size: 19, color: Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }

  Widget _refRow(Referensi r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.judulLink,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(r.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus',
            onPressed: () => _hapusReferensi(r),
            icon: const Icon(Icons.delete_outline, size: 19, color: Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }
}

class _Kosong extends StatelessWidget {
  final String text;
  const _Kosong(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.ice.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text,
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
    );
  }
}
