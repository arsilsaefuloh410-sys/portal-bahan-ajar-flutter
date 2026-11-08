import 'package:flutter_test/flutter_test.dart';

import 'package:portal_bahan_ajar_sma5/core/api_client.dart';
import 'package:portal_bahan_ajar_sma5/core/elemen.dart';
import 'package:portal_bahan_ajar_sma5/models/models.dart';

void main() {
  test('formatBytes identik dengan format_bytes() PHP', () {
    expect(formatBytes(0), '0.0 B');
    expect(formatBytes(18846287), '18.0 MB');
    expect(formatBytes(1024), '1.0 KB');
  });

  test('Elemen.info mengembalikan fallback untuk kode tak dikenal', () {
    expect(Elemen.info('BK').nama, 'Berpikir Komputasional');
    expect(Elemen.info('tidak-ada').kode, 'UMUM');
  });

  test('Topik.fromJson menangani data minimal', () {
    final t = Topik.fromJson(const {'judul_topik': 'Algoritma', 'kelas_id': 2});
    expect(t.judulTopik, 'Algoritma');
    expect(t.kelasId, 2);
    expect(t.elemen, 'BK');
  });
}
