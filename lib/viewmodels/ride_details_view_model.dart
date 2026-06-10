import 'package:flutter/material.dart';

import '../models/home_content.dart';
import '../services/firebase_backend.dart';

enum BookingStatus { idle, processing, confirmed }

class RideDetailsViewModel extends ChangeNotifier {
  RideDetailsViewModel({RideRepository? rideRepository})
    : _rideRepository = rideRepository ?? RideRepository();

  final RideRepository _rideRepository;

  final Set<String> _bookedSeats = {};
  final Set<String> _selectedSeats = {};
  List<String> _seatIds = const [];
  String? _configuredRideId;
  int _seatFare = 1100;
  BookingStatus _status = BookingStatus.idle;
  String? _errorMessage;

  List<String> get seatIds => List.unmodifiable(_seatIds);
  int get selectedSeatCount => _selectedSeats.length;
  int get remainingSeatCount =>
      _seatIds.where((seatId) => !isSeatBooked(seatId)).length;
  bool get isProcessing => _status == BookingStatus.processing;
  bool get isConfirmed => _status == BookingStatus.confirmed;
  String? get errorMessage => _errorMessage;
  bool get canConfirm =>
      _selectedSeats.isNotEmpty && !isProcessing && !isConfirmed;
  int get baseFare =>
      _seatFare * (selectedSeatCount == 0 ? 1 : selectedSeatCount);
  int get serviceFee => 100;
  int get totalFare => baseFare + serviceFee;

  String get actionLabel {
    return switch (_status) {
      BookingStatus.idle => 'Confirm Booking',
      BookingStatus.processing => 'Processing...',
      BookingStatus.confirmed => 'Booking Confirmed!',
    };
  }

  bool isSeatSelected(String seatId) => _selectedSeats.contains(seatId);
  bool isSeatBooked(String seatId) => _bookedSeats.contains(seatId);
  bool isSeatAvailable(String seatId) => !isSeatBooked(seatId) && !isProcessing;

  String seatLabel(String seatId) {
    final index = _seatIds.indexOf(seatId);
    return index == -1 ? 'Passenger seat' : 'Passenger seat ${index + 1}';
  }

  void configureForRide(RideOption ride) {
    final rideId = RideRepository.rideIdFor(ride);
    if (_configuredRideId == rideId) {
      return;
    }

    _configuredRideId = rideId;
    _bookedSeats
      ..clear()
      ..addAll(ride.bookedSeats);
    _selectedSeats.clear();
    _seatFare = _fareAmount(ride.fare);
    _seatIds = _buildSeatIds(
      availableSeats: ride.availableSeatCount,
      bookedSeats: _bookedSeats,
    );
    _status = BookingStatus.idle;
    _errorMessage = null;
  }

  void toggleSeat(String seatId) {
    if (!isSeatAvailable(seatId)) {
      return;
    }

    if (_selectedSeats.contains(seatId)) {
      _selectedSeats.remove(seatId);
    } else {
      _selectedSeats.add(seatId);
    }
    _errorMessage = null;
    if (_status == BookingStatus.confirmed) {
      _status = BookingStatus.idle;
    }
    notifyListeners();
  }

  Future<void> confirmBooking(RideOption ride) async {
    if (!canConfirm) {
      return;
    }

    final seatsToBook = _selectedSeats.toList();
    _status = BookingStatus.processing;
    _errorMessage = null;
    notifyListeners();

    try {
      await _rideRepository.createBooking(
        ride: ride,
        seats: seatsToBook,
        totalFare: totalFare,
      );
      _bookedSeats.addAll(seatsToBook);
      _selectedSeats.clear();
      _status = BookingStatus.confirmed;
    } on Object catch (error) {
      _errorMessage = error.toString().contains('seat-unavailable')
          ? 'One or more selected seats are already booked.'
          : 'Unable to confirm booking. Please try again.';
      _status = BookingStatus.idle;
    }
    notifyListeners();
  }

  static List<String> _buildSeatIds({
    required int availableSeats,
    required Set<String> bookedSeats,
  }) {
    final totalSeats = availableSeats + bookedSeats.length;
    final generatedSeats = List<String>.generate(
      totalSeats,
      (index) => 'passenger_${index + 1}',
    );
    return {...bookedSeats, ...generatedSeats}.take(totalSeats).toList();
  }

  static int _fareAmount(String fare) {
    final digits = fare.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 1100;
  }
}
