import 'package:flutter/material.dart';

import 'splash_screen.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.next});

  final Widget next;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _showSplash ? const SplashScreen() : widget.next,
    );
  }
}
