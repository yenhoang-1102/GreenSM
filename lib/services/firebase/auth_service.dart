import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      unawaited(
        credential.user
                ?.updateDisplayName(displayName.trim())
                .timeout(const Duration(seconds: 5))
                .catchError((error) {
              if (kDebugMode) {
                debugPrint('Khong cap nhat duoc ten user ngay: $error');
              }
            }) ??
            Future<void>.value(),
      );
    }
    return credential;
  }

  Future<UserCredential> continueAsGuest() {
    return _auth.signInAnonymously();
  }

  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
    );
  }

  Future<ConfirmationResult> sendPhoneOtpForWeb({
    required String phoneNumber,
  }) {
    return _auth.signInWithPhoneNumber(phoneNumber.trim());
  }

  Future<UserCredential> loginWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> loginWithWebSmsCode({
    required ConfirmationResult confirmationResult,
    required String smsCode,
  }) {
    return confirmationResult.confirm(smsCode.trim());
  }

  Future<void> logout() => _auth.signOut();
}
