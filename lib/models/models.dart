/// Model data hasil REST API — satu berkas untuk semua model kecil.
library;

class User {
  final int id;
  final String nama;
  final String email;
  final String role;

  const User({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: (j['id'] as num?)?.toInt() ?? 0,
        nama: j['nama'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? 'guru',
      );
}

class Kelas {
  final int id;
  final String namaKelas;
  final int tingkat;
  final String deskripsi;
  final int totalTopik;
  final int totalFile;
  final int totalReferensi;

  const Kelas({
    required this.id,
    required this.namaKelas,
    required this.tingkat,
    required this.deskripsi,
    required this.totalTopik,
    required this.totalFile,
    required this.totalReferensi,
  });

  factory Kelas.fromJson(Map<String, dynamic> j) => Kelas(
        id: (j['id'] as num?)?.toInt() ?? 0,
        namaKelas: j['nama_kelas'] as String? ?? '',
        tingkat: (j['tingkat'] as num?)?.toInt() ?? 0,
        deskripsi: j['deskripsi'] as String? ?? '',
        totalTopik: (j['total_topik'] as num?)?.toInt() ?? 0,
        totalFile: (j['total_file'] as num?)?.toInt() ?? 0,
        totalReferensi: (j['total_referensi'] as num?)?.toInt() ?? 0,
      );
}

class Topik {
  final int id;
  final int kelasId;
  final String namaKelas;
  final int tingkat;
  final String judulTopik;
  final String elemen;
  final String deskripsi;
  final int urutan;
  final String createdAt;
  final String namaPembuat;
  final int totalFile;
  final int totalReferensi;

  const Topik({
    required this.id,
    required this.kelasId,
    required this.namaKelas,
    required this.tingkat,
    required this.judulTopik,
    required this.elemen,
    required this.deskripsi,
    required this.urutan,
    required this.createdAt,
    required this.namaPembuat,
    required this.totalFile,
    required this.totalReferensi,
  });

  factory Topik.fromJson(Map<String, dynamic> j) => Topik(
        id: (j['id'] as num?)?.toInt() ?? 0,
        kelasId: (j['kelas_id'] as num?)?.toInt() ?? 0,
        namaKelas: j['nama_kelas'] as String? ?? '',
        tingkat: (j['tingkat'] as num?)?.toInt() ?? 0,
        judulTopik: j['judul_topik'] as String? ?? '',
        elemen: j['elemen'] as String? ?? 'BK',
        deskripsi: j['deskripsi'] as String? ?? '',
        urutan: (j['urutan'] as num?)?.toInt() ?? 0,
        createdAt: j['created_at'] as String? ?? '',
        namaPembuat: j['nama_pembuat'] as String? ?? '',
        totalFile: (j['total_file'] as num?)?.toInt() ?? 0,
        totalReferensi: (j['total_referensi'] as num?)?.toInt() ?? 0,
      );
}

class FileMateri {
  final int id;
  final String namaFile;
  final String tipeFile;
  final int ukuranFile;
  final int downloadCount;
  final String uploadedAt;

  const FileMateri({
    required this.id,
    required this.namaFile,
    required this.tipeFile,
    required this.ukuranFile,
    required this.downloadCount,
    required this.uploadedAt,
  });

  bool get isPdf => tipeFile.toLowerCase() == 'pdf';

  factory FileMateri.fromJson(Map<String, dynamic> j) => FileMateri(
        id: (j['id'] as num?)?.toInt() ?? 0,
        namaFile: j['nama_file'] as String? ?? '',
        tipeFile: j['tipe_file'] as String? ?? '',
        ukuranFile: (j['ukuran_file'] as num?)?.toInt() ?? 0,
        downloadCount: (j['download_count'] as num?)?.toInt() ?? 0,
        uploadedAt: j['uploaded_at'] as String? ?? '',
      );
}

class Referensi {
  final int id;
  final String judulLink;
  final String url;

  const Referensi({
    required this.id,
    required this.judulLink,
    required this.url,
  });

  factory Referensi.fromJson(Map<String, dynamic> j) => Referensi(
        id: (j['id'] as num?)?.toInt() ?? 0,
        judulLink: j['judul_link'] as String? ?? '',
        url: j['url'] as String? ?? '',
      );
}

class BabLain {
  final int id;
  final String judulTopik;
  final int urutan;

  const BabLain({
    required this.id,
    required this.judulTopik,
    required this.urutan,
  });

  factory BabLain.fromJson(Map<String, dynamic> j) => BabLain(
        id: (j['id'] as num?)?.toInt() ?? 0,
        judulTopik: j['judul_topik'] as String? ?? '',
        urutan: (j['urutan'] as num?)?.toInt() ?? 0,
      );
}

class TopikDetail {
  final Topik topik;
  final List<FileMateri> files;
  final List<Referensi> referensi;
  final List<BabLain> babLain;

  const TopikDetail({
    required this.topik,
    required this.files,
    required this.referensi,
    required this.babLain,
  });

  factory TopikDetail.fromJson(Map<String, dynamic> j) => TopikDetail(
        topik: Topik.fromJson(j['topik'] as Map<String, dynamic>? ?? {}),
        files: (j['files'] as List? ?? [])
            .map((e) => FileMateri.fromJson(e as Map<String, dynamic>))
            .toList(),
        referensi: (j['referensi'] as List? ?? [])
            .map((e) => Referensi.fromJson(e as Map<String, dynamic>))
            .toList(),
        babLain: (j['bab_lain'] as List? ?? [])
            .map((e) => BabLain.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
