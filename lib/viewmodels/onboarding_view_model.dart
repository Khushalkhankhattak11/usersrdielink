import 'package:flutter/material.dart';

import '../models/onboarding_content.dart';

class OnboardingViewModel extends ChangeNotifier {
  final List<OnboardingStep> steps = const [
    OnboardingStep(
      title: 'Find a Ride',
      description:
          "Search your route and date. Browse verified departures across Pakistan's major cities.",
      icon: Icons.search,
      badge: '1',
    ),
    OnboardingStep(
      title: 'Book Your Seat',
      description:
          'Select your preferred vehicle tier. From Economy to Business, choose the comfort that suits your travel style.',
      icon: Icons.directions_car,
      badge: '2',
    ),
    OnboardingStep(
      title: 'Enjoy the Journey',
      description:
          'Real-time tracking and fixed pricing. Pay exactly what you see with no hidden fees.',
      icon: Icons.map_outlined,
      badge: '3',
    ),
  ];

  final List<PricingTier> pricingTiers = const [
    PricingTier(
      name: 'Premium',
      examples: 'Fortuner, Revo',
      rate: 'Rs. 85 / KM',
      badge: 'Luxury & Power',
      icon: Icons.directions_car_filled,
    ),
    PricingTier(
      name: 'Standard',
      examples: 'Corolla, Civic',
      rate: 'Rs. 45 / KM',
      badge: 'Most Popular',
      icon: Icons.directions_car_outlined,
    ),
    PricingTier(
      name: 'Economy',
      examples: 'Mehran, WagonR',
      rate: 'Rs. 30 / KM',
      badge: 'Best Value',
      icon: Icons.airport_shuttle_outlined,
    ),
  ];

  final List<SafetyTip> safetyTips = const [
    SafetyTip(
      category: 'Visibility',
      title: 'Share your live trip status',
      description:
          'Keep your loved ones informed with real-time location and ETA sharing.',
      icon: Icons.share_location,
    ),
    SafetyTip(
      category: 'Verification',
      title: 'Check vehicle details before boarding',
      description:
          "Verify plate, vehicle model, and driver's identity before entering.",
      icon: Icons.fact_check_outlined,
    ),
    SafetyTip(
      category: 'Quick Response',
      title: 'Use SOS for emergencies',
      description:
          'The SOS button alerts our 24/7 security team and emergency services.',
      icon: Icons.emergency_outlined,
      isEmergency: true,
    ),
    SafetyTip(
      category: 'Trust',
      title: 'All drivers are background checked',
      description:
          'Every driver goes through multi-step criminal and professional checks.',
      icon: Icons.verified_user_outlined,
    ),
  ];

  int _pageIndex = 0;

  int get pageIndex => _pageIndex;
  bool get isLastPage => _pageIndex == 2;

  void setPage(int index) {
    _pageIndex = index;
    notifyListeners();
  }
}
