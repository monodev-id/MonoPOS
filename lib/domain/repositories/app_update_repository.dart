import '../../core/common/result.dart';
import '../entities/app_update_entity.dart';

abstract class AppUpdateRepository {
  Future<Result<AppUpdateInfo>> checkForUpdate();

  Future<Result<String>> downloadUpdate(AppUpdateDownloadParams params);
}
