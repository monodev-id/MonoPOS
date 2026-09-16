import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/services/update/app_installer_service.dart';
import '../../../domain/entities/app_update_entity.dart';
import '../../../domain/usecases/app_update_usecases.dart';
import '../../../domain/usecases/params/no_param.dart';
import 'app_update_state.dart';

final appUpdateNotifierProvider = NotifierProvider.autoDispose<AppUpdateNotifier, AppUpdateState>(
  AppUpdateNotifier.new,
);

class AppUpdateNotifier extends AutoDisposeNotifier<AppUpdateState> {
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
        state = state.copyWith(status: AppUpdateStatus.installing);

        try {
          await AppInstallerService.installApk(success.data);

          if (_disposed) return;
          state = state.copyWith(status: AppUpdateStatus.available);
        } catch (e) {
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
