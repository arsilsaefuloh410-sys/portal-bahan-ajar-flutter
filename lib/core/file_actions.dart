import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';

/// Unduh berkas dari API lalu buka dengan aplikasi eksternal Android.
Future<void> downloadAndOpen(String apiPath, String fileName) async {
  final bytes = await Api.download(apiPath);

  final dir = await getTemporaryDirectory();
  final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final file = File('${dir.path}/$safeName');
  await file.writeAsBytes(bytes, flush: true);

  final result = await OpenFilex.open(file.path);
  if (result.type != ResultType.done) {
    throw ApiException('Berkas tersimpan di ${file.path}, tetapi tidak ada aplikasi untuk membukanya.', 0);
  }
}
