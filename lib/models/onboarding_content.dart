import 'package:flutter/material.dart';

class OnboardingStep {
  const OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.badge,
  });

  final String title;
  final String description;
  final IconData icon;
  final String badge;
}

class PricingTier {
  const PricingTier({
    required this.name,
    required this.examples,
    required this.rate,
    required this.badge,
    required this.icon,
  });

  final String name;
  final String examples;
  final String rate;
  final String badge;
  final IconData icon;
}

class SafetyTip {
  const SafetyTip({
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    this.isEmergency = false,
  });

  final String category;
  final String title;
  final String description;
  final IconData icon;
  final bool isEmergency;
}
