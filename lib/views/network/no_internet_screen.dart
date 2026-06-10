import 'package:flutter/material.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({
    super.key,
    required this.onRetry,
    required this.isChecking,
  });

  final VoidCallback onRetry;
  final bool isChecking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131B2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(28),
                      child: Icon(
                        Icons.wifi_off,
                        color: Colors.white,
                        size: 72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'No internet connection',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      height: 34 / 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please connect to the internet. Ride Link will continue automatically when your connection comes back.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFBEC6E0),
                      fontSize: 16,
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: isChecking ? null : onRetry,
                    icon: isChecking
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(isChecking ? 'Checking...' : 'Try Again'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2170E4),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFD8E2FF),
                      disabledForegroundColor: const Color(0xFF45464D),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
