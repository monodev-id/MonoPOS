import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/services/update/app_installer_service.dart';
import '../../../core/utilities/console_logger.dart';
import '../../../domain/entities/app_update_entity.dart';
import '../../../domain/usecases/app_update_usecases.dart';
import '../../../domain/usecases/params/no_param.dart';
import 'app_update_state.dart';

final appUpdateNotifierProvider = NotifierProvider<AppUpdateNotifier, AppUpdateState>(
  AppUpdateNotifier.new,
);

class AppUpdateNotifier extends Notifier<AppUpdateState> {
  var _disposed = false;

  @override
  AppUpdateState build() {
    ref.onDispose(() => _disposed = true);

    return const AppUpdateState();
  }

  Future<void> checkForUpdate() async {
    if (state.isBusy) return;

    state = state.copyWith(status: AppUpdateStatus.checking);

    final repo = ref.read(appUpdateRepositoryProvider);
    final result = await CheckAppUpdateUsecase(repo).call(NoParam());

    if (_disposed) return;

    result.when(
      success: (success) {
        final info = success.data;

        state = state.copyWith(
          status: info.isUpdateAvailable ? AppUpdateStatus.available : AppUpdateStatus.upToDate,
          info: info,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          status: AppUpdateStatus.error,
          error: failure.error.toString(),
        );
      },
    );
  }

  Future<void> downloadAndInstall() async {
    final info = state.info;

    if (state.isBusy || info == null || !info.isUpdateAvailable) return;

    if (!Platform.isAndroid) {
      state = state.copyWith(
        status: AppUpdateStatus.error,
        error: 'Instalasi otomatis hanya tersedia di Android',
      );
      return;
    }

    state = state.copyWith(status: AppUpdateStatus.downloading, progress: 0);

    final repo = ref.read(appUpdateRepositoryProvider);
    final result = await DownloadUpdateUsecase(repo).call(
      AppUpdateDownloadParams(
        apkUrl: info.apkUrl,
        assetName: info.assetName,
        onProgress: (progress) {
          if (_disposed) return;
          state = state.copyWith(progress: progress);
        },
      ),
    );

    if (_disposed) return;

    await result.when(
      success: (success) async {
        state = state.copyWith(status: AppUpdateStatus.installing, progress: 1);

        cl(success.data, title: 'AppUpdate downloaded', message: info.latestVersion);

        try {
          if (Platform.isAndroid) {
            final installStatus = await Permission.requestInstallPackages.status;

            cl(installStatus.toString(), title: 'AppUpdate install permission status');

            if (!installStatus.isGranted) {
              final requested = await Permission.requestInstallPackages.request();

              cl(requested.toString(), title: 'AppUpdate install permission requested');

              if (!requested.isGranted) {
                if (_disposed) return;
                state = state.copyWith(
                  status: AppUpdateStatus.error,
                  error: requested.isPermanentlyDenied
                      ? 'Izin "Install aplikasi tak dikenal" ditolak. Aktifkan di Setelan > Aplikasi > Mono POS.'
                      : 'Izin install ditolak. Ketuk Unduh & Install untuk coba lagi.',
                );

                if (requested.isPermanentlyDenied) await openAppSettings();

                return;
              }
            }
          }

          await AppInstallerService.installApk(success.data);

          cl('installer intent terkirim', title: 'AppUpdate install dispatched');

          if (_disposed) return;
        } catch (e) {
          ce(e, title: 'AppUpdate install gagal');

          if (_disposed) return;
          state = state.copyWith(status: AppUpdateStatus.error, error: e.toString());
        }
      },
      failure: (failure) async {
        state = state.copyWith(status: AppUpdateStatus.error, error: failure.error.toString());
      },
    );
  }
}
