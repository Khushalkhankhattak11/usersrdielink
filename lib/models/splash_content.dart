import 'package:flutter/material.dart';

class SplashContent {
  const SplashContent({
    required this.brandLead,
    required this.brandTail,
    required this.tagline,
    required this.status,
    required this.verificationLabel,
    required this.footer,
    required this.logoIcon,
  });

  final String brandLead;
  final String brandTail;
  final String tagline;
  final String status;
  final String verificationLabel;
  final String footer;
  final IconData logoIcon;
}
