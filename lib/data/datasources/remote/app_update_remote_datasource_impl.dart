import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/common/result.dart';
import '../../models/app_update_model.dart';
import '../interfaces/app_update_datasource.dart';

class AppUpdateRemoteDatasourceImpl implements AppUpdateDatasource {
  AppUpdateRemoteDatasourceImpl({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _owner = 'monodev-id';
  static const _repo = 'MonoPOS';

  Uri get _latestReleaseUri => Uri.https('api.github.com', '/repos/$_owner/$_repo/releases/latest');

  Map<String, String> get _headers => {'Accept': 'application/vnd.github+json'};

  @override
  Future<Result<AppUpdateModel>> getLatestRelease() async {
    try {
      final response = await _client.get(_latestReleaseUri, headers: _headers);

      final parsed = Result<AppUpdateModel>.fromHttpResponse(
        response: response,
        parser: (json) {
          if (json == null) throw 'Respons release GitHub kosong';
          return AppUpdateModel.fromJson(json);
        },
      );

      return parsed;
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<String>> downloadAsset({
    required String url,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(_headers);

      final streamed = await _client.send(request);

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        return Result.failure(error: 'Gagal mengunduh pembaruan (HTTP ${streamed.statusCode})');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      final sink = file.openWrite();

      final total = streamed.contentLength ?? 0;
      var received = 0;

      await for (final chunk in streamed.stream) {
        sink.add(chunk);
        received += chunk.length;

        if (total > 0) onProgress?.call(received / total);
      }

      await sink.close();

      return Result.success(data: file.path);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
