class AppUpdateAssetModel {
  final String name;
  final String downloadUrl;
  final int size;

  const AppUpdateAssetModel({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  factory AppUpdateAssetModel.fromJson(Map<String, dynamic> json) {
    return AppUpdateAssetModel(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

class AppUpdateModel {
  final String tagName;
  final String releaseNotes;
  final DateTime? publishedAt;
  final List<AppUpdateAssetModel> assets;

  const AppUpdateModel({
    required this.tagName,
    this.releaseNotes = '',
    this.publishedAt,
    this.assets = const [],
  });

  factory AppUpdateModel.fromJson(Map<String, dynamic> json) {
    final assetsJson = json['assets'] as List<dynamic>? ?? [];

    return AppUpdateModel(
      tagName: json['tag_name'] as String? ?? '',
      releaseNotes: json['body'] as String? ?? '',
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      assets: assetsJson.whereType<Map<String, dynamic>>().map(AppUpdateAssetModel.fromJson).toList(),
    );
  }

  AppUpdateAssetModel? pickApkAsset() {
    final apks = assets.where((a) => a.name.toLowerCase().endsWith('.apk') && a.downloadUrl.isNotEmpty).toList();

    if (apks.isEmpty) return null;

    for (final abi in ['arm64-v8a', 'armeabi-v7a', 'universal']) {
      for (final apk in apks) {
        if (apk.name.toLowerCase().contains(abi)) return apk;
      }
    }

    return apks.first;
  }
}
