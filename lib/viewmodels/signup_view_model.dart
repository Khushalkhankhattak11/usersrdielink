import 'package:flutter/material.dart';

import '../models/signup_content.dart';
import '../services/firebase_backend.dart';

enum SignupStatus { idle, submitting, success }

class SignupViewModel extends ChangeNotifier {
  SignupViewModel({AuthRepository? authRepository})
    : content = const SignupContent(
        brandName: 'Ride Link',
        heroBody:
            'Connecting Pakistan through dependable, efficient, and sophisticated intercity travel.',
        driverBadge: 'VERIFIED DRIVERS',
        fareBadge: 'FIXED FARES',
        heading: 'Create Account',
        description: 'Join the community of reliable intercity travelers.',
        fullNameLabel: 'Full Name',
        fullNamePlaceholder: 'Ahmed Khan',
        emailLabel: 'Email Address',
        emailPlaceholder: 'ahmed.khan@example.com',
        phoneLabel: 'Phone Number',
        phonePlaceholder: '03001234567',
        passwordLabel: 'Password',
        passwordPlaceholder: 'Password',
        termsPrefix: 'I agree to the',
        termsLabel: 'Terms of Service',
        privacyLabel: 'Privacy Policy',
        submitLabel: 'Create Account',
        submittingLabel: 'Creating account...',
        successLabel: 'Account Created!',
        loginPrompt: 'Already have an account?',
        loginLabel: 'Login',
      ),
      _authRepository = authRepository ?? AuthRepository();

  final SignupContent content;
  final AuthRepository _authRepository;

  SignupStatus _status = SignupStatus.idle;
  bool _isPasswordVisible = false;
  bool _acceptedTerms = false;
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  String? _errorMessage;

  SignupStatus get status => _status;
  bool get isSubmitting => _status == SignupStatus.submitting;
  bool get isSuccess => _status == SignupStatus.success;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get acceptedTerms => _acceptedTerms;
  String? get errorMessage => _errorMessage;

  String get actionLabel {
    return switch (_status) {
      SignupStatus.idle => content.submitLabel,
      SignupStatus.submitting => content.submittingLabel,
      SignupStatus.success => content.successLabel,
    };
  }

  void updateFullName(String value) {
    _fullName = value.trim();
    _errorMessage = null;
  }

  void updateEmail(String value) {
    _email = value.trim();
    _errorMessage = null;
  }

  void updatePhone(String value) {
    _phone = value.trim();
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

  void setAcceptedTerms(bool? value) {
    _acceptedTerms = value ?? false;
    notifyListeners();
  }

  String? validateRequired(String? value, String fieldName) {
    if ((value ?? '').trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
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

  String? validatePhone(String? value) {
    final text = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) {
      return 'Phone number is required';
    }
    if (text.length != 11) {
      return 'Phone number must be exactly 11 digits';
    }
    if (!_isSupportedNetwork(text)) {
      return 'Use a Jazz, Zong, Ufone, or Telenor number';
    }
    return null;
  }

  String? validateTerms() {
    return _acceptedTerms ? null : 'Please accept the terms to continue';
  }

  String? validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Password is required';
    }
    if (text.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> submit() async {
    if (isSubmitting) {
      return;
    }

    _status = SignupStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authRepository.signUp(
        fullName: _fullName,
        email: _email,
        phone: _phone,
        password: _password,
      );
      if (credential != null || !FirebaseBackend.isInitialized) {
        _status = SignupStatus.success;
      } else {
        _status = SignupStatus.idle;
      }
    } on Object catch (error) {
      _errorMessage = _friendlyAuthMessage(error);
      _status = SignupStatus.idle;
    }
    notifyListeners();
  }

  String _friendlyAuthMessage(Object error) {
    final text = error.toString();
    if (text.contains('email-already-in-use')) {
      return 'This email is already registered';
    }
    if (text.contains('weak-password')) {
      return 'Password is too weak';
    }
    if (text.contains('invalid-email')) {
      return 'Enter a valid email address';
    }
    if (text.contains('network-request-failed')) {
      return 'Network error. Please try again.';
    }
    return 'Unable to create account. Please try again.';
  }

  bool _isSupportedNetwork(String phone) {
    return RegExp(r'^(030[0-9]|031[0-9]|033[0-7]|034[0-9])').hasMatch(phone);
  }
}
