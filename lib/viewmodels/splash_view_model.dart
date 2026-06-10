import 'package:flutter/material.dart';

import '../models/splash_content.dart';

class SplashViewModel extends ChangeNotifier {
  SplashViewModel()
    : _content = const SplashContent(
        brandLead: 'Ride',
        brandTail: 'Link',
        tagline: 'Premium Mobility',
        status: 'Securing your journey...',
        verificationLabel: 'Verified Service',
        footer: 'Ride Link Enterprise © 2024',
        logoIcon: Icons.directions_car,
      );

  final SplashContent _content;

  SplashContent get content => _content;

  Duration get introDuration => const Duration(milliseconds: 1200);
  Duration get loadingDuration => const Duration(seconds: 2);
  Duration get pulseDuration => const Duration(seconds: 4);
}
