import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/connectivity_view_model.dart';
import 'no_internet_screen.dart';

class NetworkGate extends StatelessWidget {
  const NetworkGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityViewModel>();

    if (!connectivity.isOnline) {
      return NoInternetScreen(
        isChecking: connectivity.isChecking,
        onRetry: connectivity.refresh,
      );
    }

    return child;
  }
}
