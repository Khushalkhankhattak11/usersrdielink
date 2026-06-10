import 'package:flutter/material.dart';

import '../models/forgot_password_content.dart';
import '../services/firebase_backend.dart';

enum ForgotPasswordStatus { idle, sending, sent }

class ForgotPasswordViewModel extends ChangeNotifier {
  ForgotPasswordViewModel({AuthRepository? authRepository})
    : content = const ForgotPasswordContent(
        brandName: 'Ride Link',
        badgeLabel: 'Security Hub',
        heading: 'Reset Password',
        description:
            "Enter your email to receive a recovery code. We'll help you get back to your journey in no time.",
        emailLabel: 'Email Address',
        emailPlaceholder: 'ahmed.khan@example.com',
        submitLabel: 'Send Code',
        submittingLabel: 'Sending...',
        successLabel: 'Code Sent',
        dividerLabel: 'Or',
        backToLoginLabel: 'Back to Login',
        note:
            "If you don't receive an email within 2 minutes, please check your spam folder or contact",
        supportLabel: 'Ride Link Support',
        footer: '© 2024 RIDE LINK PAKISTAN',
      ),
      _authRepository = authRepository ?? AuthRepository();

  final ForgotPasswordContent content;
  final AuthRepository _authRepository;

  ForgotPasswordStatus _status = ForgotPasswordStatus.idle;
  String _email = '';
  String? _errorMessage;

  ForgotPasswordStatus get status => _status;
  bool get isSending => _status == ForgotPasswordStatus.sending;
  bool get isSent => _status == ForgotPasswordStatus.sent;
  String? get errorMessage => _errorMessage;

  String get actionLabel {
    return switch (_status) {
      ForgotPasswordStatus.idle => content.submitLabel,
      ForgotPasswordStatus.sending => content.submittingLabel,
      ForgotPasswordStatus.sent => content.successLabel,
    };
  }

  void updateEmail(String value) {
    _email = value.trim();
    _errorMessage = null;
  }

  String? validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Email is required';
    }
    if (!text.contains('@') || !text.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> sendCode() async {
    if (isSending) {
      return;
    }

    _status = ForgotPasswordStatus.sending;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.sendPasswordResetEmail(_email);
      _status = ForgotPasswordStatus.sent;
    } on Object catch (error) {
      _errorMessage = _friendlyAuthMessage(error);
      _status = ForgotPasswordStatus.idle;
    }
    notifyListeners();
  }

  String _friendlyAuthMessage(Object error) {
    final text = error.toString();
    if (text.contains('user-not-found')) {
      return 'No account found with this email';
    }
    if (text.contains('invalid-email')) {
      return 'Enter a valid email address';
    }
    if (text.contains('network-request-failed')) {
      return 'Network error. Please try again.';
    }
    return 'Unable to send reset email. Please try again.';
  }
}
