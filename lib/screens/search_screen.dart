import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/elemen.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'topik_screen.dart';

/// Halaman pencarian materi (mirror guru/search.php): kata kunci +
/// filter tingkat kelas dan elemen kurikulum.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<Topik> _hasil = [];
  bool _searched = false;
  bool _loading = false;
  String? _error;
  String _filterTingkat = '';
  String _filterElemen = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty && _filterTingkat.isEmpty && _filterElemen.isEmpty) {
      setState(() {
        _hasil = [];
        _searched = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });

    try {
      final data = await Api.get('search.php', query: {
        if (q.isNotEmpty) 'q': q,
        if (_filterTingkat.isNotEmpty) 'tingkat': _filterTingkat,
        if (_filterElemen.isNotEmpty) 'elemen': _filterElemen,
      }) as Map<String, dynamic>;
      setState(() {
        _hasil = (data['hasil'] as List)
            .map((e) => Topik.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Tidak dapat terhubung ke server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    _ctrl.clear();
    setState(() {
      _filterTingkat = '';
      _filterElemen = '';
      _hasil = [];
      _searched = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Bahan Ajar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bar pencarian
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
                  controller: _ctrl,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: const InputDecoration(
                    hintText: 'Cari judul topik atau materi...',
                    prefixIcon: Icon(Icons.search, color: AppColors.primary),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _filterTingkat.isEmpty ? null : _filterTingkat,
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true, hintText: 'Semua Kelas'),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Semua Kelas')),
                          DropdownMenuItem(value: '10', child: Text('Kelas 10')),
                          DropdownMenuItem(value: '11', child: Text('Kelas 11')),
                          DropdownMenuItem(value: '12', child: Text('Kelas 12')),
                        ],
                        onChanged: (v) {
                          setState(() => _filterTingkat = v ?? '');
                          _search();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _filterElemen.isEmpty ? null : _filterElemen,
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true, hintText: 'Semua Elemen'),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Semua Elemen')),
                          ...Elemen.list.map((e) => DropdownMenuItem(
                                value: e.kode,
                                child: Text('${e.kode} — ${e.nama}', overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) {
                          setState(() => _filterElemen = v ?? '');
                          _search();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Reset pencarian',
                      onPressed: _reset,
                      icon: const Icon(Icons.restart_alt, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _loading ? null : _search, child: const Text('Cari')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_error != null)
            Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_searched && _hasil.isEmpty && _error == null)
            _empty('Tidak ada hasil', 'Coba kata kunci lain atau hapus filter.')
          else if (!_searched && _error == null)
            _empty('Mulai mencari', 'Ketik kata kunci, misalnya "algoritma" atau "jaringan".')
          else
            ..._hasil.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HasilCard(topik: t),
                )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _empty(String title, String subtitle) => Container(
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              title == 'Tidak ada hasil' ? Icons.sentiment_dissatisfied : Icons.search,
              size: 40,
              color: AppColors.accent,
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
        ),
      );
}

class _HasilCard extends StatelessWidget {
  final Topik topik;
  const _HasilCard({required this.topik});

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
              children: [
                _chip(topik.namaKelas, AppColors.primary, Colors.white),
                _chip(info.nama, info.bg, info.warna),
                _chip('Bab ${topik.urutan}', AppColors.ice.withValues(alpha: 0.6), AppColors.primary),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              topik.judulTopik,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              topik.deskripsi.length > 140
                  ? '${topik.deskripsi.substring(0, 140)}…'
                  : topik.deskripsi,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.file_present, size: 15, color: AppColors.orange),
                const SizedBox(width: 4),
                Text('${topik.totalFile} berkas', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                const SizedBox(width: 14),
                const Icon(Icons.link, size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('${topik.totalReferensi} referensi', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                const Spacer(),
                const Text('Buka ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
        ),
      );
}
