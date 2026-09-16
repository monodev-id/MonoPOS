import '../../../domain/entities/app_update_entity.dart';

class AppUpdateState {
  final AppUpdateStatus status;
  final AppUpdateInfo? info;
  final double progress;
  final String? error;

  const AppUpdateState({
    this.status = AppUpdateStatus.idle,
    this.info,
    this.progress = 0,
    this.error,
  });

  bool get isBusy =>
      status == AppUpdateStatus.checking ||
      status == AppUpdateStatus.downloading ||
      status == AppUpdateStatus.installing;

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    AppUpdateInfo? info,
    double? progress,
    String? error,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      info: info ?? this.info,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}
