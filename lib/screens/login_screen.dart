import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/firebase/analytics_service.dart';
import '../services/firebase/auth_service.dart';
import '../services/firebase/database_service.dart';
import '../services/firebase/event_tracking_service.dart';
import '../services/firebase/firebase_bootstrap.dart';
import 'home_screen.dart';

enum LoginMethod { email, phone }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  final _analyticsService = AnalyticsService();
  final _eventTrackingService = EventTrackingService();

  LoginMethod _method = LoginMethod.email;
  bool _isRegister = false;
  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;
  ConfirmationResult? _webConfirmationResult;
  int? _resendToken;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isLoading = true);

    try {
      if (!FirebaseBootstrap.isReady) {
        _showMessage('Firebase chua san sang');
        return;
      }

      if (kDebugMode) {
        debugPrint(_isRegister
            ? 'Dang tao tai khoan Firebase Auth...'
            : 'Dang dang nhap Firebase Auth...');
      }
      final credential = _isRegister
          ? await _authService
              .register(
                email: _emailController.text,
                password: _passwordController.text,
                displayName: _nameController.text,
              )
              .timeout(const Duration(seconds: 20))
          : await _authService
              .login(
                email: _emailController.text,
                password: _passwordController.text,
              )
              .timeout(const Duration(seconds: 20));
      if (kDebugMode) {
        debugPrint('Firebase Auth thanh cong: ${credential.user?.uid}');
      }

      final user = credential.user;
      if (user == null) {
        throw Exception('Khong tim thay tai khoan vua xac thuc.');
      }

      if (_isRegister) {
        await _saveSignedInUser(user, method: 'register_email');

        try {
          await FirebaseAuth.instance.currentUser
              ?.sendEmailVerification()
              .timeout(const Duration(seconds: 20));
        } finally {
          await _authService.logout();
        }

        if (!mounted) return;
        setState(() {
          _isRegister = false;
          _passwordController.clear();
        });
        await _showEmailVerificationDialog(isNewAccount: true);
        return;
      }

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null) {
        throw Exception('Khong the tai lai trang thai xac minh email.');
      }
      if (!refreshedUser.emailVerified) {
        try {
          await refreshedUser
              .sendEmailVerification()
              .timeout(const Duration(seconds: 20));
        } finally {
          await _authService.logout();
        }

        if (!mounted) return;
        _passwordController.clear();
        await _showEmailVerificationDialog(isNewAccount: false);
        return;
      }

      _saveSignedInUserInBackground(
        refreshedUser,
        method: 'email',
      );

      if (!mounted) return;
      _goHome();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      _showMessage('Vui long nhap so dien thoai');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (!FirebaseBootstrap.isReady) {
        _showMessage('Firebase chua san sang');
        return;
      }

      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('Dang gui OTP tren Web...');
        }
        final confirmationResult = await _authService
            .sendPhoneOtpForWeb(
              phoneNumber: _normalizePhoneNumber(_phoneController.text),
            )
            .timeout(const Duration(seconds: 30));
        if (!mounted) return;
        setState(() {
          _webConfirmationResult = confirmationResult;
          _otpSent = true;
        });
        _showMessage('Da gui ma OTP');
        return;
      }

      if (kDebugMode) {
        debugPrint('Dang gui OTP tren Android/iOS...');
      }
      await _authService.sendPhoneOtp(
        phoneNumber: _normalizePhoneNumber(_phoneController.text),
        forceResendingToken: _resendToken,
        verificationCompleted: (credential) async {
          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          _saveSignedInUserInBackground(
            userCredential.user,
            method: 'phone_auto',
          );
          if (mounted) _goHome();
        },
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showError(error);
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _otpSent = true;
            _isLoading = false;
          });
          _showMessage('Da gui ma OTP');
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted && !_otpSent) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!kIsWeb && _verificationId == null) {
      _showMessage('Vui long gui OTP truoc');
      return;
    }
    if (kIsWeb && _webConfirmationResult == null) {
      _showMessage('Vui long gui OTP truoc');
      return;
    }
    if (_otpController.text.trim().length < 6) {
      _showMessage('Ma OTP gom 6 chu so');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (!FirebaseBootstrap.isReady) {
        _showMessage('Firebase chua san sang');
        return;
      }

      final credential = kIsWeb
          ? await _authService
              .loginWithWebSmsCode(
                confirmationResult: _webConfirmationResult!,
                smsCode: _otpController.text,
              )
              .timeout(const Duration(seconds: 20))
          : await _authService
              .loginWithSmsCode(
                verificationId: _verificationId!,
                smsCode: _otpController.text,
              )
              .timeout(const Duration(seconds: 20));
      _saveSignedInUserInBackground(credential.user, method: 'phone_otp');

      if (!mounted) return;
      _goHome();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    try {
      if (!FirebaseBootstrap.isReady) {
        _showMessage('Firebase chua san sang');
        return;
      }

      final credential = await _authService.continueAsGuest().timeout(
            const Duration(seconds: 20),
          );
      _saveSignedInUserInBackground(credential.user, method: 'anonymous');

      if (!mounted) return;
      _goHome();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveSignedInUserInBackground(User? user, {required String method}) {
    unawaited(_saveSignedInUser(user, method: method));
  }

  Future<void> _saveSignedInUser(User? user, {required String method}) async {
    if (user == null || !FirebaseBootstrap.isReady) return;

    try {
      if (kDebugMode) {
        debugPrint('Dang luu user profile vao Firestore users/${user.uid}');
      }
      await _databaseService
          .upsertUser(
            userId: user.uid,
            data: {
              'name': _profileName(user),
              'phone':
                  user.phoneNumber ?? _normalizePhoneNumber(_phoneController.text),
              'email': user.email ?? _emailController.text.trim(),
              'displayName': _profileName(user),
              'lastLoginAt': DateTime.now().toIso8601String(),
              'loginMethod': method,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (kDebugMode) {
        debugPrint('Da luu user profile vao Firestore users/${user.uid}');
      }
      await _analyticsService.logLogin(method).timeout(
            const Duration(seconds: 5),
          );
      await _eventTrackingService.trackLogin(method: method);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Khong luu duoc user profile ngay lap tuc: $error');
      }
    }
  }

  String _profileName(User user) {
    final typedName = _nameController.text.trim();
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }
    if (typedName.isNotEmpty) return typedName;
    if (user.email != null && user.email!.trim().isNotEmpty) {
      return user.email!.trim();
    }
    if (user.phoneNumber != null && user.phoneNumber!.trim().isNotEmpty) {
      return user.phoneNumber!.trim();
    }
    return 'Khach hang';
  }

  String _normalizePhoneNumber(String value) {
    final phone = value.trim().replaceAll(' ', '');
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0')) return '+84${phone.substring(1)}';
    return phone;
  }

  void _goHome() {
    Navigator.pushReplacementNamed(context, HomeScreen.routeName);
  }

  void _showError(Object error) {
    if (!mounted) return;
    _showMessage(_cleanErrorMessage(error));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showEmailVerificationDialog({
    required bool isNewAccount,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.mark_email_unread_rounded,
          color: Color(0xFF00B8C4),
          size: 42,
        ),
        title: Text(
          isNewAccount ? 'Kiem tra email cua ban' : 'Email chua duoc xac minh',
        ),
        content: Text(
          'Xanh SM da gui lien ket xac minh den ${_emailController.text.trim()}. '
          'Hay mo email, bam vao lien ket xac minh, sau do quay lai dang nhap. '
          'Neu chua thay email, hay kiem tra thu muc Spam.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Da hieu'),
          ),
        ],
      ),
    );
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();
    if (error is TimeoutException) {
      return 'Firebase Auth khong phan hoi sau 20 giay. Kiem tra ket noi mang, Authorized domains va Firebase config.';
    }
    if (message.contains('configuration-not-found')) {
      return 'Firebase Authentication chua duoc bat dung cach. Hay bat Email/Password hoac Phone trong Firebase Console.';
    }
    if (message.contains('operation-not-allowed')) {
      return 'Phone Auth chua gui OTP duoc. Kiem tra SMS region policy da allow Viet Nam, project da bat Billing, va app dang dung dung Firebase project.';
    }
    if (message.contains('unauthorized-domain')) {
      return 'Domain dang chay app chua duoc them vao Authorized domains. Neu URL la 127.0.0.1 thi them ca 127.0.0.1.';
    }
    if (message.contains('too-many-requests')) {
      return 'Ban da yeu cau gui email qua nhieu lan. Vui long doi mot luc roi thu lai.';
    }

    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('FirebaseException: ', '')
        .replaceFirst('[firebase_auth/', '[');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 44),
            const Center(child: _XanhSmLogo()),
            const SizedBox(height: 24),
            Text(
              _isRegister ? 'Dang ky' : 'Dang nhap',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _method == LoginMethod.email
                  ? 'Dang nhap bang email hoac tao tai khoan moi.'
                  : 'Nhap so dien thoai de nhan ma OTP.',
              style: textTheme.bodyLarge?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SegmentedButton<LoginMethod>(
              segments: const [
                ButtonSegment(
                  value: LoginMethod.email,
                  icon: Icon(Icons.mail_rounded),
                  label: Text('Email'),
                ),
                ButtonSegment(
                  value: LoginMethod.phone,
                  icon: Icon(Icons.sms_rounded),
                  label: Text('OTP'),
                ),
              ],
              selected: {_method},
              onSelectionChanged: _isLoading
                  ? null
                  : (selection) {
                      setState(() {
                        _method = selection.first;
                        _otpSent = false;
                        _verificationId = null;
                        _webConfirmationResult = null;
                        _otpController.clear();
                      });
                    },
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: _method == LoginMethod.email
                  ? _EmailLoginForm(
                      emailController: _emailController,
                      nameController: _nameController,
                      passwordController: _passwordController,
                      isRegister: _isRegister,
                      onSubmit: _submitEmail,
                    )
                  : _PhoneOtpForm(
                      phoneController: _phoneController,
                      otpController: _otpController,
                      otpSent: _otpSent,
                      onSendOtp: _sendOtp,
                      onVerifyOtp: _verifyOtp,
                    ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading
                  ? null
                  : _method == LoginMethod.email
                      ? _submitEmail
                      : _otpSent
                          ? _verifyOtp
                          : _sendOtp,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(_primaryButtonText),
            ),
            const SizedBox(height: 14),
            if (_method == LoginMethod.phone && _otpSent)
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: const Text('Gui lai OTP'),
                ),
              ),
            if (_method == LoginMethod.email)
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _isRegister = !_isRegister),
                  child: Text(
                    _isRegister
                        ? 'Da co tai khoan? Dang nhap'
                        : 'Chua co tai khoan? Dang ky',
                  ),
                ),
              ),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _continueAsGuest,
                child: const Text('Tiep tuc voi tai khoan khach'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _primaryButtonText {
    if (_method == LoginMethod.phone) {
      return _otpSent ? 'Xac thuc OTP' : 'Gui ma OTP';
    }
    return _isRegister ? 'Tao tai khoan' : 'Dang nhap';
  }
}

class _XanhSmLogo extends StatelessWidget {
  const _XanhSmLogo();

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF00B8C4);

    return Semantics(
      label: 'Xanh SM',
      image: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3300AAB7),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.energy_savings_leaf_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'XANH SM',
            style: TextStyle(
              color: brandColor,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailLoginForm extends StatelessWidget {
  const _EmailLoginForm({
    required this.emailController,
    required this.nameController,
    required this.passwordController,
    required this.isRegister,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final bool isRegister;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isRegister) ...[
          TextFormField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Ho ten',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_rounded),
          ),
          validator: (value) {
            if (value == null || !value.contains('@')) {
              return 'Vui long nhap email hop le';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          obscureText: true,
          onFieldSubmitted: (_) => onSubmit(),
          decoration: const InputDecoration(
            labelText: 'Mat khau',
            prefixIcon: Icon(Icons.lock_rounded),
          ),
          validator: (value) {
            if (value == null || value.length < 6) {
              return 'Mat khau can it nhat 6 ky tu';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _PhoneOtpForm extends StatelessWidget {
  const _PhoneOtpForm({
    required this.phoneController,
    required this.otpController,
    required this.otpSent,
    required this.onSendOtp,
    required this.onVerifyOtp,
  });

  final TextEditingController phoneController;
  final TextEditingController otpController;
  final bool otpSent;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          enabled: !otpSent,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSendOtp(),
          decoration: const InputDecoration(
            labelText: 'So dien thoai',
            hintText: 'VD: 0901234567 hoac +84901234567',
            prefixIcon: Icon(Icons.phone_rounded),
          ),
        ),
        if (otpSent) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onVerifyOtp(),
            decoration: const InputDecoration(
              labelText: 'Ma OTP',
              prefixIcon: Icon(Icons.password_rounded),
            ),
          ),
        ],
      ],
    );
  }
}
