import 'dart:io';

import 'package:open_filex/open_filex.dart';

class AppInstallerService {
  AppInstallerService._();

  static Future<void> installApk(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw 'File pembaruan tidak ditemukan: $filePath';
    }

    final result = await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');

    if (result.type != ResultType.done) {
      throw result.message.isNotEmpty ? result.message : 'Gagal membuka installer pembaruan';
    }
  }
}
