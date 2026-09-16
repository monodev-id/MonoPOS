import '../../core/common/result.dart';
import '../../core/usecase/usecase.dart';
import '../entities/app_update_entity.dart';
import '../repositories/app_update_repository.dart';
import 'params/no_param.dart';

class CheckAppUpdateUsecase extends Usecase<Result, NoParam> {
  CheckAppUpdateUsecase(this._appUpdateRepository);

  final AppUpdateRepository _appUpdateRepository;

  @override
  Future<Result<AppUpdateInfo>> call(NoParam params) => _appUpdateRepository.checkForUpdate();
}

class DownloadUpdateUsecase extends Usecase<Result, AppUpdateDownloadParams> {
  DownloadUpdateUsecase(this._appUpdateRepository);

  final AppUpdateRepository _appUpdateRepository;

  @override
  Future<Result<String>> call(AppUpdateDownloadParams params) => _appUpdateRepository.downloadUpdate(params);
}
