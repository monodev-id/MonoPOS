import '../../../core/common/result.dart';
import '../../models/app_update_model.dart';

abstract class AppUpdateDatasource {
  Future<Result<AppUpdateModel>> getLatestRelease();

  Future<Result<String>> downloadAsset({
    required String url,
    required String fileName,
    void Function(double progress)? onProgress,
  });
}
