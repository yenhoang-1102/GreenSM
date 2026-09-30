import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../firebase_options.dart';
import 'notification_service.dart';

class FirebaseBootstrap {
  static bool isReady = false;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final useEmulator =
          dotenv.env['USE_FIREBASE_EMULATOR']?.toLowerCase() == 'true';
      final firestore = FirebaseFirestore.instance;

      if (useEmulator) {
        final configuredHost =
            dotenv.env['FIREBASE_EMULATOR_HOST']?.trim() ?? '';
        final emulatorHost = configuredHost.isNotEmpty
            ? configuredHost
            : defaultTargetPlatform == TargetPlatform.android
                ? '10.0.2.2'
                : '127.0.0.1';

        await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
        firestore.settings = const Settings(
          persistenceEnabled: false,
          webExperimentalAutoDetectLongPolling: true,
        );
        firestore.useFirestoreEmulator(emulatorHost, 8081);

        if (kDebugMode) {
          debugPrint(
            'Firebase Emulator dang hoat dong: '
            'Auth $emulatorHost:9099, Firestore $emulatorHost:8081',
          );
        }
      } else {
        firestore.settings = const Settings(
          persistenceEnabled: true,
          webExperimentalAutoDetectLongPolling: true,
        );
      }
      isReady = true;

      if (useEmulator) return;

      if (!kIsWeb) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      await _tryInitializeNotifications();
    } catch (error, stackTrace) {
      isReady = false;
      if (kDebugMode) {
        debugPrint('Firebase chua duoc cau hinh: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  static Future<void> _tryInitializeNotifications() async {
    try {
      await NotificationService().initialize();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Firebase Messaging chua san sang: $error');
      }
    }
  }
}
