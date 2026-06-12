import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/home_content.dart';
import '../services/firebase_backend.dart';

enum AuthDestination {
  resolving,
  onboarding,
  login,
  signup,
  forgotPassword,
  home,
  rideDetails,
}

class AuthFlowViewModel extends ChangeNotifier {
  AuthFlowViewModel({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository() {
    load();
  }

  static const _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const _isLoggedInKey = 'is_logged_in';
  final AuthRepository _authRepository;

  AuthDestination _destination = AuthDestination.resolving;
  RideOption? _selectedRide;

  AuthDestination get destination => _destination;
  RideOption? get selectedRide => _selectedRide;

  Future<void> load() async {
    SharedPreferences? preferences;
    try {
      preferences = await SharedPreferences.getInstance();
      final firebaseUser = await _authRepository.currentUser;
      final isLoggedIn =
          firebaseUser != null ||
          (preferences.getBool(_isLoggedInKey) ?? false);
      final hasSeenOnboarding =
          preferences.getBool(_hasSeenOnboardingKey) ?? false;
      _destination = isLoggedIn
          ? AuthDestination.home
          : hasSeenOnboarding
          ? AuthDestination.login
          : AuthDestination.onboarding;
      notifyListeners();
    } on Object {
      final isLoggedIn = preferences?.getBool(_isLoggedInKey) ?? false;
      final hasSeenOnboarding =
          preferences?.getBool(_hasSeenOnboardingKey) ?? false;
      _destination = isLoggedIn
          ? AuthDestination.home
          : hasSeenOnboarding
          ? AuthDestination.login
          : AuthDestination.onboarding;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    _destination = AuthDestination.login;
    notifyListeners();
    unawaited(_setOnboardingSeen());
  }

  Future<void> openLogin() async {
    _destination = AuthDestination.login;
    notifyListeners();
    unawaited(_setOnboardingSeen());
  }

  Future<void> openSignup() async {
    _destination = AuthDestination.signup;
    notifyListeners();
    unawaited(_setOnboardingSeen());
  }

  Future<void> openForgotPassword() async {
    _destination = AuthDestination.forgotPassword;
    notifyListeners();
    unawaited(_setOnboardingSeen());
  }

  Future<void> recordLogin() async {
    await _setLoggedIn(true);
    _destination = AuthDestination.home;
    notifyListeners();
  }

  Future<void> recordSignup() async {
    await _setLoggedIn(true);
    _destination = AuthDestination.home;
    notifyListeners();
  }

  void openRideDetails(RideOption ride) {
    _selectedRide = ride;
    _destination = AuthDestination.rideDetails;
    notifyListeners();
  }

  void closeRideDetails() {
    _destination = AuthDestination.home;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    await _setLoggedIn(false);
    await _setOnboardingSeen();
    _destination = AuthDestination.login;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    try {
      await _authRepository.deleteCurrentAccount();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_hasSeenOnboardingKey, true);
      await preferences.setBool(_isLoggedInKey, false);
    } on Object {
      // UI-only account deletion should still return the user to login.
    }

    _selectedRide = null;
    _destination = AuthDestination.login;
    notifyListeners();
  }

  Future<void> _setOnboardingSeen() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_hasSeenOnboardingKey, true);
    } on Object {
      // Local persistence should not block navigation while UI-only.
    }
  }

  Future<void> _setLoggedIn(bool value) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_hasSeenOnboardingKey, true);
      await preferences.setBool(_isLoggedInKey, value);
    } on Object {
      // Local persistence should not block navigation while UI-only.
    }
  }
}
