import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/core/utilities/app_version.dart';

void main() {
  group('AppVersion.normalize', () {
    test('strips leading v', () {
      expect(AppVersion.normalize('v1.2.3'), '1.2.3');
    });

    test('strips build metadata and prerelease suffix', () {
      expect(AppVersion.normalize('1.2.3+5'), '1.2.3');
      expect(AppVersion.normalize('v1.2.3-beta'), '1.2.3');
    });

    test('leaves plain version untouched', () {
      expect(AppVersion.normalize('1.0.0'), '1.0.0');
    });
  });

  group('AppVersion.compare', () {
    test('returns 0 for equal versions', () {
      expect(AppVersion.compare('1.2.3', '1.2.3'), 0);
      expect(AppVersion.compare('v1.2.3', '1.2.3'), 0);
    });

    test('compares patch, minor, major', () {
      expect(AppVersion.compare('1.2.4', '1.2.3'), greaterThan(0));
      expect(AppVersion.compare('1.3.0', '1.2.9'), greaterThan(0));
      expect(AppVersion.compare('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('handles different segment lengths', () {
      expect(AppVersion.compare('1.2', '1.2.0'), 0);
      expect(AppVersion.compare('1.2.1', '1.2'), greaterThan(0));
    });

    test('returns negative when older', () {
      expect(AppVersion.compare('1.0.0', '1.0.1'), lessThan(0));
    });
  });

  group('AppVersion.isNewer', () {
    test('detects newer tag with v prefix', () {
      expect(AppVersion.isNewer('v1.0.1', '1.0.0'), isTrue);
    });

    test('returns false for same or older', () {
      expect(AppVersion.isNewer('1.0.0', '1.0.0'), isFalse);
      expect(AppVersion.isNewer('1.0.0', '2.0.0'), isFalse);
    });
  });
}
