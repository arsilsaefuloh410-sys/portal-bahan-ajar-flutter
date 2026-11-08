import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/elemen.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'topik_screen.dart';

/// Daftar bab/topik dalam satu jenjang kelas (mirror guru/kelas.php):
/// pencarian cepat + filter elemen kurikulum.
class KelasScreen extends StatefulWidget {
  final int tingkat;

  const KelasScreen({super.key, required this.tingkat});

  @override
  State<KelasScreen> createState() => _KelasScreenState();
}

class _KelasScreenState extends State<KelasScreen> {
  Kelas? _kelas;
  List<Topik> _semuaTopik = [];
  List<Topik> _topikTampil = [];
  String _filterElemen = 'ALL';
  String _query = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _kelas = null;
    });
    try {
      final data = await Api.get('kelas.php') as Map<String, dynamic>;
      final list = (data['kelas'] as List)
          .map((e) => Kelas.fromJson(e as Map<String, dynamic>))
          .toList();
      final kelas = list.where((k) => k.tingkat == widget.tingkat).firstOrNull;
      if (kelas == null) {
        setState(() => _error = 'Kelas tidak ditemukan.');
        return;
      }

      final topikData = await Api.get('topik.php', query: {'kelas_id': '${kelas.id}'})
          as Map<String, dynamic>;
      final topik = (topikData['topik'] as List)
          .map((e) => Topik.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _kelas = kelas;
        _semuaTopik = topik;
        _applyFilter();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Tidak dapat terhubung ke server.');
    }
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    _topikTampil = _semuaTopik.where((t) {
      final cocokElemen = _filterElemen == 'ALL' || t.elemen == _filterElemen;
      final cocokQuery = q.isEmpty ||
          t.judulTopik.toLowerCase().contains(q) ||
          t.deskripsi.toLowerCase().contains(q);
      return cocokElemen && cocokQuery;
    }).toList();
  }

  void _setFilter(String elemen) {
    setState(() {
      _filterElemen = elemen;
      _applyFilter();
    });
  }

  void _setQuery(String value) {
    setState(() {
      _query = value;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_kelas?.namaKelas ?? 'Daftar Bab')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
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

    if (_kelas == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final kelas = _kelas!;
    final headerColor = switch (kelas.tingkat) {
      11 => const Color(0xFF64A4CE),
      12 => const Color(0xFF8DBEDC),
      _ => const Color(0xFF4893C6),
    };

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header kelas
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [headerColor, headerColor.withValues(alpha: 0.78)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 0,
                  top: -14,
                  child: Text(
                    '${kelas.tingkat}',
                    style: TextStyle(
                      fontSize: 76,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Informatika Fase ${kelas.tingkat == 10 ? 'E' : 'F'} SMA',
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      kelas.namaKelas,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kelas.deskripsi.isNotEmpty
                          ? kelas.deskripsi
                          : 'Kumpulan materi pembelajaran dan alat bantu mengajar.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 12.5, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        '${_semuaTopik.length} Bab Materi',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Toolbar pencarian + pindah kelas
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: _setQuery,
                  decoration: const InputDecoration(
                    hintText: 'Ketik kata kunci untuk menyaring bab...',
                    prefixIcon: Icon(Icons.filter_alt_outlined, color: AppColors.textLight),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Pindah kelas:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const Spacer(),
                    for (final t in [10, 11, 12])
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text('Kls $t', style: const TextStyle(fontSize: 12)),
                          selected: t == widget.tingkat,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: t == widget.tingkat ? Colors.white : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) {
                            if (t != widget.tingkat) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => KelasScreen(tingkat: t)),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filter elemen
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
                const Row(
                  children: [
                    Icon(Icons.label_outline, size: 16, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Text('Elemen:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _elemenChip('ALL', 'Semua', null),
                    ...Elemen.list.map((e) => _elemenChip(e.kode, e.kode, e)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_topikTampil.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.ice.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              ),
              child: const Column(
                children: [
                  Icon(Icons.search_off, size: 40, color: AppColors.textLight),
                  SizedBox(height: 10),
                  Text(
                    'Bab materi tidak ditemukan',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Coba gunakan kata kunci atau elemen lain.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else
            ..._topikTampil.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TopikCard(topik: t, namaKelas: kelas.namaKelas),
                )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _elemenChip(String kode, String label, Elemen? info) {
    final active = _filterElemen == kode;
    final color = info?.warna ?? AppColors.primary;
    return GestureDetector(
      onTap: () => _setFilter(kode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : (info?.bg ?? AppColors.ice.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppColors.primary : color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (info != null) ...[
              Icon(info.icon, size: 13, color: active ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : (info?.warna ?? AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopikCard extends StatelessWidget {
  final Topik topik;
  final String namaKelas;
  const _TopikCard({required this.topik, required this.namaKelas});

  @override
  Widget build(BuildContext context) {
    final info = Elemen.info(topik.elemen);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TopikScreen(topikId: topik.id)),
      ),
      child: Container(
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
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ice.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Bab ${topik.urutan}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: info.bg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: info.warna.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(info.icon, size: 13, color: info.warna),
                      const SizedBox(width: 4),
                      Text(
                        info.kode,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: info.warna),
                      ),
                    ],
                  ),
                ),
                Text('• $namaKelas', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              topik.judulTopik,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              topik.deskripsi.isNotEmpty ? topik.deskripsi : 'Deskripsi topik belum ditambahkan.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _badge(Icons.file_download_outlined, '${topik.totalFile} Berkas', AppColors.orange),
                const SizedBox(width: 8),
                _badge(Icons.link, '${topik.totalReferensi} Link', AppColors.primary),
                const Spacer(),
                const Icon(Icons.arrow_forward, size: 20, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.ice.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(text, style: const TextStyle(fontSize: 11.5, color: AppColors.textMain, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
