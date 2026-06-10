import 'package:flutter/material.dart';

import '../models/login_content.dart';
import '../services/firebase_backend.dart';

enum LoginStatus { idle, submitting, success }

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({AuthRepository? authRepository})
    : content = const LoginContent(
        brandName: 'Ride Link',
        subtitle: 'Premium Intercity Rides',
        heading: 'Welcome Back',
        description: 'Please enter your details to continue',
        emailLabel: 'Email Address',
        emailPlaceholder: 'name@example.com',
        passwordLabel: 'Password',
        passwordPlaceholder: 'Password',
        forgotPasswordLabel: 'Forgot Password?',
        submitLabel: 'Log In',
        submittingLabel: 'Authenticating...',
        successLabel: 'Success!',
        dividerLabel: 'OR CONTINUE WITH',
        googleLabel: 'Google',
        appleLabel: 'Apple',
        signUpPrompt: "Don't have an account?",
        signUpLabel: 'Sign Up',
        panelHeading: 'Your safety is our priority.',
        panelBody:
            "Experience the next generation of intercity travel in Pakistan with Ride Link's verified fleet and fixed-fare policy.",
      ),
      _authRepository = authRepository ?? AuthRepository();

  final LoginContent content;
  final AuthRepository _authRepository;

  LoginStatus _status = LoginStatus.idle;
  bool _isPasswordVisible = false;
  String _email = '';
  String _password = '';
  String? _errorMessage;

  LoginStatus get status => _status;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isSubmitting => _status == LoginStatus.submitting;
  bool get isSuccess => _status == LoginStatus.success;
  String? get errorMessage => _errorMessage;

  String get actionLabel {
    return switch (_status) {
      LoginStatus.idle => content.submitLabel,
      LoginStatus.submitting => content.submittingLabel,
      LoginStatus.success => content.successLabel,
    };
  }

  void updateEmail(String value) {
    _email = value.trim();
    _errorMessage = null;
  }

  void updatePassword(String value) {
    _password = value;
    _errorMessage = null;
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
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

  String? validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  Future<void> submit() async {
    if (isSubmitting) {
      return;
    }

    _status = LoginStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authRepository.signIn(
        email: _email,
        password: _password,
      );
      if (credential != null || !FirebaseBackend.isInitialized) {
        _status = LoginStatus.success;
      } else {
        _status = LoginStatus.idle;
      }
    } on Object catch (error) {
      _errorMessage = _friendlyAuthMessage(error);
      _status = LoginStatus.idle;
    }
    notifyListeners();
  }

  String _friendlyAuthMessage(Object error) {
    final text = error.toString();
    if (text.contains('user-not-found') || text.contains('wrong-password')) {
      return 'Invalid email or password';
    }
    if (text.contains('invalid-email')) {
      return 'Enter a valid email address';
    }
    if (text.contains('network-request-failed')) {
      return 'Network error. Please try again.';
    }
    return 'Unable to log in. Please try again.';
  }
}
