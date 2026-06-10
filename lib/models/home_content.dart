import 'package:flutter/material.dart';

class QuickRoute {
  const QuickRoute({required this.label});

  final String label;
}

class RideOption {
  const RideOption({
    this.id,
    required this.driverName,
    required this.ratingLabel,
    required this.vehicle,
    required this.vehicleDetails,
    required this.tier,
    required this.fare,
    required this.from,
    required this.to,
    required this.pickupTime,
    required this.dropoffTime,
    required this.seatsLeft,
    required this.accentColor,
    required this.badgeColor,
    required this.badgeTextColor,
    this.isLowSeat = false,
    this.bookedSeats = const [],
  });

  final String? id;
  final String driverName;
  final String ratingLabel;
  final String vehicle;
  final String vehicleDetails;
  final String tier;
  final String fare;
  final String from;
  final String to;
  final String pickupTime;
  final String dropoffTime;
  final String seatsLeft;
  final Color accentColor;
  final Color badgeColor;
  final Color badgeTextColor;
  final bool isLowSeat;
  final List<String> bookedSeats;

  int get availableSeatCount {
    final match = RegExp(r'\d+').firstMatch(seatsLeft);
    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }
}
