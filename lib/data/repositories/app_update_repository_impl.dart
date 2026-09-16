import 'package:package_info_plus/package_info_plus.dart';

import '../../core/common/result.dart';
import '../../core/utilities/app_version.dart';
import '../../domain/entities/app_update_entity.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../datasources/interfaces/app_update_datasource.dart';

class AppUpdateRepositoryImpl extends AppUpdateRepository {
  AppUpdateRepositoryImpl({required this.appUpdateDatasource});

  final AppUpdateDatasource appUpdateDatasource;

  @override
  Future<Result<AppUpdateInfo>> checkForUpdate() async {
    try {
      final release = await appUpdateDatasource.getLatestRelease();
      if (release.isFailure) return Result.failure(error: release.error!);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final model = release.data!;
      final latestVersion = AppVersion.normalize(model.tagName);

      if (latestVersion.isEmpty) {
        return Result.failure(error: 'Tag versi release GitHub tidak valid');
      }

      final apk = model.pickApkAsset();

      return Result.success(
        data: AppUpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          isUpdateAvailable: apk != null && AppVersion.isNewer(latestVersion, currentVersion),
          releaseNotes: model.releaseNotes,
          publishedAt: model.publishedAt,
          apkUrl: apk?.downloadUrl ?? '',
          assetName: apk?.name ?? '',
          assetSize: apk?.size ?? 0,
        ),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<String>> downloadUpdate(AppUpdateDownloadParams params) async {
    try {
      if (params.apkUrl.isEmpty) return Result.failure(error: 'URL unduhan APK tidak tersedia');

      return appUpdateDatasource.downloadAsset(
        url: params.apkUrl,
        fileName: params.assetName.isNotEmpty ? params.assetName : 'monopos-update.apk',
        onProgress: params.onProgress,
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
