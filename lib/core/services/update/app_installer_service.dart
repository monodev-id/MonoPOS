import 'dart:io';

import 'package:open_filex/open_filex.dart';

import '../../utilities/console_logger.dart';

class AppInstallerService {
  AppInstallerService._();

  static Future<void> installApk(String filePath) async {
    cl(filePath, title: 'AppUpdate install mulai');

    final file = File(filePath);

    if (!await file.exists()) {
      ce(filePath, title: 'AppUpdate install gagal: file hilang');
      throw 'File pembaruan tidak ditemukan: $filePath';
    }

    final length = await file.length();
    cl(length, title: 'AppUpdate install file size', message: filePath);

    if (length <= 0) {
      throw 'File pembaruan kosong ($length B). Unduh ulang.';
    }

    final header = await file.openRead(0, 4).first;
    if (header.length < 4 || header[0] != 0x50 || header[1] != 0x4B) {
      ce(header, title: 'AppUpdate install gagal: bukan ZIP/APK', message: filePath);
      throw 'File unduhan bukan APK valid. Unduh ulang.';
    }

    final result = await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');

    cl(result.type.toString(), title: 'AppUpdate OpenFilex result', message: result.message);

    if (result.type != ResultType.done) {
      ce(result.message, title: 'AppUpdate install gagal', state: result.type.toString());
      throw result.message.isNotEmpty ? result.message : 'Gagal membuka installer pembaruan';
    }
  }
}
