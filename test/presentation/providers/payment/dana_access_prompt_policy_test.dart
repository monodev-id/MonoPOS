import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/presentation/providers/payment/dana_access_prompt_policy.dart';

void main() {
  final now = DateTime(2026, 10, 30, 12);

  group('shouldPromptDanaAccess', () {
    bool decide({
      bool isAndroid = true,
      bool listenerEnabled = true,
      bool listenerStarted = true,
      bool permissionGranted = false,
      bool alreadyPromptedThisSession = false,
      DateTime? snoozedUntil,
    }) {
      return shouldPromptDanaAccess(
        isAndroid: isAndroid,
        listenerEnabled: listenerEnabled,
        listenerStarted: listenerStarted,
        permissionGranted: permissionGranted,
        alreadyPromptedThisSession: alreadyPromptedThisSession,
        now: now,
        snoozedUntil: snoozedUntil,
      );
    }

    test('menampilkan prompt saat izin belum ada di Android', () {
      expect(decide(), isTrue);
    });

    test('tidak menampilkan prompt bila izin sudah diberikan', () {
      expect(decide(permissionGranted: true), isFalse);
    });

    test('tidak menampilkan prompt dua kali dalam satu sesi', () {
      expect(decide(alreadyPromptedThisSession: true), isFalse);
    });

    test('menghormati masa snooze "Nanti"', () {
      expect(decide(snoozedUntil: now.add(const Duration(hours: 1))), isFalse);
      expect(
        decide(snoozedUntil: now.subtract(const Duration(hours: 1))),
        isTrue,
      );
    });

    test('tidak menampilkan prompt bila listener mati atau belum siap', () {
      expect(decide(listenerEnabled: false), isFalse);
      expect(decide(listenerStarted: false), isFalse);
    });

    test('tidak menampilkan prompt di platform selain Android', () {
      expect(decide(isAndroid: false), isFalse);
    });
  });

  group('shouldPromptDanaRebind', () {
    test('menyarankan rebind saat izin ada tetapi service belum connect', () {
      expect(
        shouldPromptDanaRebind(
          listenerEnabled: true,
          permissionGranted: true,
          serviceConnected: false,
        ),
        isTrue,
      );
    });

    test(
      'tidak menyarankan rebind saat sudah terhubung atau listener mati',
      () {
        expect(
          shouldPromptDanaRebind(
            listenerEnabled: true,
            permissionGranted: true,
            serviceConnected: true,
          ),
          isFalse,
        );
        expect(
          shouldPromptDanaRebind(
            listenerEnabled: false,
            permissionGranted: true,
            serviceConnected: false,
          ),
          isFalse,
        );
      },
    );
  });
}
