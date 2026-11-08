import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/elemen.dart';
import '../core/file_actions.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'kelas_screen.dart';

/// Detail satu topik (mirror guru/topik.php): ringkasan materi,
/// daftar berkas (unduh), tautan referensi, dan bab lain di kelas sama.
class TopikScreen extends StatefulWidget {
  final int topikId;

  const TopikScreen({super.key, required this.topikId});

  @override
  State<TopikScreen> createState() => _TopikScreenState();
}

class _TopikScreenState extends State<TopikScreen> {
  TopikDetail? _detail;
  String? _error;
  int? _downloadingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _detail = null;
    });
    try {
      final data = await Api.get('topik.php', query: {'id': '${widget.topikId}'})
          as Map<String, dynamic>;
      setState(() => _detail = TopikDetail.fromJson(data));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Tidak dapat terhubung ke server.');
    }
  }

  Future<void> _unduh(FileMateri file) async {
    setState(() => _downloadingId = file.id);
    try {
      await downloadAndOpen('unduh.php?id=${file.id}', file.namaFile);
      // Muat ulang agar jumlah unduhan ikut bertambah
      _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunduh atau membuka berkas.')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  Future<void> _bukaTautan(String url) async {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan tersebut.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      appBar: AppBar(title: Text(detail?.topik.judulTopik ?? 'Detail Bab')),
      body: _buildBody(detail),
    );
  }

  Widget _buildBody(TopikDetail? detail) {
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

    if (detail == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final topik = detail.topik;
    final info = Elemen.info(topik.elemen);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header topik
          Container(
            padding: const EdgeInsets.all(16),
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
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                      child: Text(topik.namaKelas,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.ice.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('Bab ${topik.urutan}',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: info.bg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: info.warna.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(info.icon, size: 13, color: info.warna),
                          const SizedBox(width: 5),
                          Text('${info.kode} - ${info.nama}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: info.warna)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  topik.judulTopik,
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ditambahkan pada ${_formatTanggal(topik.createdAt)}'
                  '${topik.namaPembuat.isNotEmpty ? ' • Oleh ${topik.namaPembuat}' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ringkasan materi
          _sectionCard(
            icon: Icons.notes,
            iconColor: AppColors.primary,
            title: 'Ringkasan Materi & Panduan Pembelajaran',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topik.deskripsi.isNotEmpty ? topik.deskripsi : 'Belum ada penjelasan detail untuk topik ini.',
                  style: const TextStyle(fontSize: 14.5, height: 1.65, color: AppColors.textMain),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.ice.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb, size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tips Mengajar di Kelas:',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                            SizedBox(height: 4),
                            Text(
                              'Mulai pembelajaran dengan mengaitkannya ke contoh sederhana sehari-hari, kemudian gunakan slide presentasi di bawah sebagai media visual interaktif di kelas.',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Berkas
          _sectionCard(
            icon: Icons.cloud_download_outlined,
            iconColor: AppColors.orange,
            title: 'Berkas Bahan Ajar Siap Pakai',
            badge: '${detail.files.length} Berkas',
            child: detail.files.isEmpty
                ? const _EmptyBox('Belum ada berkas modul atau slide yang diunggah untuk bab ini.')
                : Column(
                    children: detail.files.map((f) => _fileTile(f)).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // Referensi
          _sectionCard(
            icon: Icons.language,
            iconColor: AppColors.primary,
            title: 'Tautan Referensi & Sumber Belajar',
            badge: '${detail.referensi.length} Tautan',
            child: detail.referensi.isEmpty
                ? const _EmptyBox('Belum ada link referensi yang ditautkan untuk topik ini.')
                : Column(
                    children: detail.referensi
                        .map((r) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.link, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.judulLink,
                                            style: const TextStyle(
                                                fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                        const SizedBox(height: 2),
                                        Text(r.url,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11.5, color: AppColors.textLight)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () => _bukaTautan(r.url),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text('Buka', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // Bab lain
          if (detail.babLain.isNotEmpty)
            _sectionCard(
              icon: Icons.menu_book_outlined,
              iconColor: AppColors.primary,
              title: 'Bab Lain di ${topik.namaKelas}',
              child: Column(
                children: detail.babLain
                    .map((b) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Text('Bab ${b.urutan}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          title: Text(b.judulTopik,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => TopikScreen(topikId: b.id)),
                          ),
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 8),

          // Tombol kembali
          OutlinedButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => KelasScreen(tingkat: topik.tingkat)),
            ),
            icon: const Icon(Icons.arrow_back),
            label: Text('Kembali ke Daftar Bab ${topik.namaKelas}'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
    String? badge,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ice.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(badge,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _fileTile(FileMateri file) {
    final isPdf = file.isPdf;
    final color = isPdf ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final downloading = _downloadingId == file.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isPdf ? Icons.picture_as_pdf : Icons.slideshow, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.namaFile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                const SizedBox(height: 4),
                Text(
                  '${isPdf ? 'Dokumen PDF' : 'Slide Presentasi'} • ${formatBytes(file.ukuranFile)} • ${file.downloadCount}x diunduh',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          downloading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
                )
              : ElevatedButton.icon(
                  onPressed: () => _unduh(file),
                  icon: const Icon(Icons.download, size: 17),
                  label: const Text('Unduh'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
        ],
      ),
    );
  }

  String _formatTanggal(String raw) {
    if (raw.isEmpty) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${bulan[date.month - 1]} ${date.year}';
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.ice.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
      ),
    );
  }
}
