import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsService {
  CrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  Future<void> setUserId(String userId) {
    return _crashlytics.setUserIdentifier(userId);
  }

  Future<void> log(String message) {
    return _crashlytics.log(message);
  }

  Future<void> recordError(Object error, StackTrace stackTrace) {
    return _crashlytics.recordError(error, stackTrace);
  }
}
