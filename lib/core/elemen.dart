import 'package:flutter/material.dart';

/// 8 elemen Kurikulum Merdeka Informatika — disalin dari
/// get_elemen_list() di includes/functions.php (data statis).
class Elemen {
  final String kode;
  final String nama;
  final Color warna;
  final Color bg;
  final IconData icon;

  const Elemen({
    required this.kode,
    required this.nama,
    required this.warna,
    required this.bg,
    required this.icon,
  });

  static const list = <Elemen>[
    Elemen(kode: 'BK', nama: 'Berpikir Komputasional', warna: Color(0xFF4338CA), bg: Color(0x1F4338CA), icon: Icons.memory),
    Elemen(kode: 'TIK', nama: 'Teknologi Informasi & Komunikasi', warna: Color(0xFF0284C7), bg: Color(0x1F0284C7), icon: Icons.laptop_mac),
    Elemen(kode: 'SK', nama: 'Sistem Komputer', warna: Color(0xFF0D9488), bg: Color(0x1F0D9488), icon: Icons.developer_board),
    Elemen(kode: 'JKI', nama: 'Jaringan Komputer & Internet', warna: Color(0xFF16A34A), bg: Color(0x1F16A34A), icon: Icons.wifi),
    Elemen(kode: 'AD', nama: 'Analisis Data', warna: Color(0xFFD97706), bg: Color(0x1FD97706), icon: Icons.bar_chart),
    Elemen(kode: 'AP', nama: 'Algoritma & Pemrograman', warna: Color(0xFF7C3AED), bg: Color(0x1F7C3AED), icon: Icons.code),
    Elemen(kode: 'DSI', nama: 'Dampak Sosial Informatika', warna: Color(0xFFDB2777), bg: Color(0x1FDB2777), icon: Icons.people),
    Elemen(kode: 'PLB', nama: 'Praktik Lintas Bidang', warna: Color(0xFF059669), bg: Color(0x1F059669), icon: Icons.extension),
  ];

  static Elemen info(String kode) {
    final k = kode.trim().toUpperCase();
    for (final e in list) {
      if (e.kode == k) return e;
    }
    return const Elemen(
      kode: 'UMUM',
      nama: 'Informatika Umum',
      warna: Color(0xFF64748B),
      bg: Color(0x1F64748B),
      icon: Icons.bookmark,
    );
  }
}
