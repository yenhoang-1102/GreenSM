import 'dart:async';

import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;

  Stream<RemoteMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    if (kIsWeb) return;

    CleverTapPlugin().setCleverTapPushClickedPayloadReceivedHandler((payload) {
      if (kDebugMode) debugPrint('CleverTap push opened: $payload');
    });

    if (defaultTargetPlatform == TargetPlatform.android) {
      await CleverTapPlugin.createNotificationChannel(
        'xanh_sm_push',
        'Xanh SM',
        'Thong bao chuyen di va don hang',
        4,
        true,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await CleverTapPlugin.registerForPush();
    }

    await _syncTokenToCleverTap(await _messaging.getToken());
    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen(
      _syncTokenToCleverTap,
      onError: (Object error) {
        if (kDebugMode) debugPrint('FCM token refresh failed: $error');
      },
    );

    await _openedSubscription?.cancel();
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => CleverTapPlugin.pushNotificationClickedEvent(message.data),
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await CleverTapPlugin.pushNotificationClickedEvent(initialMessage.data);
    }
  }

  Future<void> _syncTokenToCleverTap(String? token) async {
    if (token == null ||
        token.isEmpty ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    await CleverTapPlugin.setPushToken(token);
    if (kDebugMode) debugPrint('FCM token synced to CleverTap');
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> subscribeToUserTopic(String userId) {
    return _messaging.subscribeToTopic('user_$userId');
  }

  Future<void> unsubscribeFromUserTopic(String userId) {
    return _messaging.unsubscribeFromTopic('user_$userId');
  }
}
