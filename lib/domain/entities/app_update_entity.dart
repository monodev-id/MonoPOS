import 'package:equatable/equatable.dart';

enum AppUpdateStatus {
  idle,
  checking,
  available,
  upToDate,
  downloading,
  installing,
  error,
}

class AppUpdateInfo extends Equatable {
  final String currentVersion;
  final String latestVersion;
  final bool isUpdateAvailable;
  final String releaseNotes;
  final DateTime? publishedAt;
  final String apkUrl;
  final String assetName;
  final int assetSize;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.isUpdateAvailable,
    this.releaseNotes = '',
    this.publishedAt,
    this.apkUrl = '',
    this.assetName = '',
    this.assetSize = 0,
  });

  @override
  List<Object?> get props => [
    currentVersion,
    latestVersion,
    isUpdateAvailable,
    releaseNotes,
    publishedAt,
    apkUrl,
    assetName,
    assetSize,
  ];
}

class AppUpdateDownloadParams extends Equatable {
  final String apkUrl;
  final String assetName;
  final void Function(double progress)? onProgress;

  const AppUpdateDownloadParams({
    required this.apkUrl,
    required this.assetName,
    this.onProgress,
  });

  @override
  List<Object?> get props => [apkUrl, assetName];
}
