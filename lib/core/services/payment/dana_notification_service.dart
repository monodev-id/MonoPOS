import 'dart:async';

import 'package:flutter/services.dart';

/// Event notifikasi dari aplikasi DANA yang ditangkap service Android.
class DanaNotificationEvent {
  final String key;
  final String packageName;
  final String title;
  final String body;
  final int postedAt;
  final int capturedAt;

  const DanaNotificationEvent({
    required this.key,
    required this.packageName,
    required this.title,
    required this.body,
    required this.postedAt,
    required this.capturedAt,
  });

  factory DanaNotificationEvent.fromMap(Map<dynamic, dynamic> map) {
    return DanaNotificationEvent(
      key: (map['key'] as String?) ?? '',
      packageName: (map['packageName'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      postedAt: (map['postedAt'] as num?)?.toInt() ?? 0,
      capturedAt: (map['capturedAt'] as num?)?.toInt() ?? 0,
    );
  }

  DateTime get postedAtDate => DateTime.fromMillisecondsSinceEpoch(postedAt);
}

/// Jembatan MethodChannel/EventChannel ke `DanaNotificationListenerService`.
class DanaNotificationService {
  static const MethodChannel _method = MethodChannel('com.monodev.monopos/dana_listener');
  static const EventChannel _events = EventChannel('com.monodev.monopos/dana_listener/events');

  Stream<DanaNotificationEvent>? _eventStream;

  Stream<DanaNotificationEvent> get events {
    return _eventStream ??= _events.receiveBroadcastStream().map((event) {
      if (event is Map) return DanaNotificationEvent.fromMap(event);
      throw StateError('Payload notifikasi tidak dikenali: $event');
    });
  }

  Future<bool> hasPermission() async {
    try {
      return await _method.invokeMethod<bool>('hasPermission') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> isConnected() async {
    try {
      return await _method.invokeMethod<bool>('isConnected') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> openPermissionSettings() async {
    try {
      await _method.invokeMethod<void>('openPermissionSettings');
    } on PlatformException {
      // Diabaikan: perangkat mungkin tidak punya activity pengaturan tersebut.
    } on MissingPluginException {
      // Platform selain Android.
    }
  }

  /// Buka halaman Info Aplikasi (tempat menu "Allow restricted settings").
  Future<void> openAppDetails() async {
    try {
      await _method.invokeMethod<void>('openAppDetails');
    } on PlatformException {
      // Diabaikan.
    } on MissingPluginException {
      // Platform selain Android.
    }
  }

  Future<List<DanaNotificationEvent>> getPendingEvents() async {
    try {
      final raw = await _method.invokeMethod<List<dynamic>>('getPendingEvents');
      if (raw == null) return const [];
      return raw.whereType<Map>().map(DanaNotificationEvent.fromMap).where((event) => event.key.isNotEmpty).toList();
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  Future<void> ackEvents(List<String> keys) async {
    if (keys.isEmpty) return;
    try {
      await _method.invokeMethod<void>('ackEvents', {'keys': keys});
    } on PlatformException {
      // Diabaikan: event akan dicoba lagi pada drain berikutnya.
    } on MissingPluginException {
      // Platform selain Android.
    }
  }

  Future<void> setAllowedPackages(List<String> packages) async {
    try {
      await _method.invokeMethod<void>('setAllowedPackages', {'packages': packages});
    } on PlatformException {
      // Diabaikan.
    } on MissingPluginException {
      // Platform selain Android.
    }
  }

  Future<void> requestRebind() async {
    try {
      await _method.invokeMethod<void>('rebindService');
    } on PlatformException {
      // Diabaikan.
    } on MissingPluginException {
      // Platform selain Android.
    }
  }
}
