import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'kelas_screen.dart';
import 'search_screen.dart';

/// Katalog utama guru (mirror guru/index.php): kartu 3 jenjang kelas,
/// kotak pencarian, dan kartu tips.
class HomeScreen extends StatefulWidget {
  final void Function() onLoggedOut;
  final bool embedded;

  const HomeScreen({super.key, required this.onLoggedOut, this.embedded = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Kelas>? _kelas;
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
      setState(() => _kelas = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Tidak dapat terhubung ke server.');
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Bahan Ajar'),
        actions: [
          IconButton(
            tooltip: 'Cari materi',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          if (!widget.embedded)
            IconButton(
              tooltip: 'Keluar',
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
        ],
      ),
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
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textLight),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_kelas == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kartu judul + pencarian
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Katalog Bahan Ajar & Modul Siap Tayang',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pilih jenjang kelas untuk menemukan modul PDF, slide PPTX, dan referensi bacaan terstruktur.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  readOnly: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Cari topik modul...',
                    prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ..._kelas!.map((k) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _KelasCard(kelas: k),
              )),

          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.ice.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips Menggunakan Bahan Ajar Ini',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Setiap bab dilengkapi Slide Presentasi (PPT) untuk ditayangkan di kelas, Modul Bacaan (PDF) untuk pegangan mengajar, serta Link Referensi Eksternal untuk memperkaya latihan soal.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.55),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _KelasCard extends StatelessWidget {
  final Kelas kelas;
  const _KelasCard({required this.kelas});

  Color get _headerColor {
    switch (kelas.tingkat) {
      case 11:
        return const Color(0xFF64A4CE);
      case 12:
        return const Color(0xFF8DBEDC);
      default:
        return const Color(0xFF4893C6);
    }
  }

  IconData get _icon {
    switch (kelas.tingkat) {
      case 11:
        return Icons.account_tree_outlined;
      case 12:
        return Icons.memory;
      default:
        return Icons.laptop_mac;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => KelasScreen(tingkat: kelas.tingkat)),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header gradien
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_headerColor, _headerColor.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -6,
                    top: -18,
                    child: Text(
                      '${kelas.tingkat}',
                      style: TextStyle(
                        fontSize: 88,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_icon, color: Colors.white, size: 26),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Fase ${kelas.tingkat == 10 ? 'E' : 'F'} SMA',
                              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        kelas.namaKelas,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kurikulum Merdeka Informatika',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Isi
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    kelas.deskripsi.isNotEmpty
                        ? kelas.deskripsi
                        : 'Materi bahan ajar yang terstruktur dan siap digunakan.',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.55),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.ice.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _stat(kelas.totalTopik.toString(), 'Bab Topik', AppColors.textMain),
                        _divider(),
                        _stat(kelas.totalFile.toString(), 'Berkas', AppColors.orange),
                        _divider(),
                        _stat(kelas.totalReferensi.toString(), 'Link Web', AppColors.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text(
                            'Masuk ke kelas',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
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
    );
  }

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      );

  Widget _divider() => Container(width: 1, height: 30, color: AppColors.border);
}
