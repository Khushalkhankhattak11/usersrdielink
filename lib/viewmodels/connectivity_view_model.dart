import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

typedef InternetChecker = Future<bool> Function();

class ConnectivityViewModel extends ChangeNotifier {
  ConnectivityViewModel({
    InternetChecker? internetChecker,
    bool enabled = true,
    Duration checkInterval = const Duration(seconds: 5),
  }) : _internetChecker = internetChecker ?? _defaultInternetChecker,
       _enabled = enabled {
    if (_enabled) {
      refresh();
      _timer = Timer.periodic(checkInterval, (_) => refresh());
    }
  }

  final InternetChecker _internetChecker;
  final bool _enabled;
  Timer? _timer;
  bool _isOnline = true;
  bool _isChecking = false;

  bool get isOnline => !_enabled || _isOnline;
  bool get isChecking => _isChecking;

  Future<void> refresh() async {
    if (!_enabled || _isChecking) {
      return;
    }

    _isChecking = true;
    notifyListeners();

    final hasInternet = await _internetChecker();
    if (_isOnline != hasInternet) {
      _isOnline = hasInternet;
    }
    _isChecking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static Future<bool> _defaultInternetChecker() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on Object {
      return false;
    }
  }
}
