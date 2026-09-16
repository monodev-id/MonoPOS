import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/data/models/app_update_model.dart';

void main() {
  Map<String, dynamic> releaseJson() {
    return {
      'tag_name': 'v1.2.0',
      'body': '## Perubahan\n- Tambah fitur X\n- Perbaiki bug Y',
      'published_at': '2026-09-01T10:00:00Z',
      'assets': [
        {
          'name': 'monopos-arm64-v8a.apk',
          'browser_download_url': 'https://github.com/monodev-id/MonoPOS/releases/download/v1.2.0/monopos-arm64.apk',
          'size': 12345,
        },
        {
          'name': 'monopos-armeabi-v7a.apk',
          'browser_download_url': 'https://github.com/monodev-id/MonoPOS/releases/download/v1.2.0/monopos-v7a.apk',
          'size': 12000,
        },
        {
          'name': 'checksums.txt',
          'browser_download_url': 'https://example.com/checksums.txt',
          'size': 100,
        },
      ],
    };
  }

  group('AppUpdateModel.fromJson', () {
    test('parses tag, notes, date and assets', () {
      final model = AppUpdateModel.fromJson(releaseJson());

      expect(model.tagName, 'v1.2.0');
      expect(model.releaseNotes, contains('Tambah fitur X'));
      expect(model.publishedAt?.year, 2026);
      expect(model.assets, hasLength(3));
    });

    test('defaults body to empty when missing', () {
      final json = releaseJson()..remove('body');

      expect(AppUpdateModel.fromJson(json).releaseNotes, isEmpty);
    });
  });

  group('AppUpdateModel.pickApkAsset', () {
    test('prefers arm64 apk', () {
      final apk = AppUpdateModel.fromJson(releaseJson()).pickApkAsset();

      expect(apk?.name, 'monopos-arm64-v8a.apk');
    });

    test('returns null when no apk asset', () {
      final json = releaseJson()..['assets'] = [];

      expect(AppUpdateModel.fromJson(json).pickApkAsset(), isNull);
    });

    test('falls back to first apk when no abi match', () {
      final json = releaseJson()
        ..['assets'] = [
          {
            'name': 'monopos.apk',
            'browser_download_url': 'https://example.com/monopos.apk',
            'size': 1,
          },
        ];

      expect(AppUpdateModel.fromJson(json).pickApkAsset()?.name, 'monopos.apk');
    });
  });
}
