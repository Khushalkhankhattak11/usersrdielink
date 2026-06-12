import 'package:flutter/material.dart';

import '../models/home_content.dart';
import '../services/firebase_backend.dart';

enum BookingStatus { idle, processing, confirmed }

class SeatOption {
  const SeatOption({
    required this.id,
    required this.label,
    required this.location,
  });

  final String id;
  final String label;
  final String location;

  Map<String, String> toMap() => {
    'id': id,
    'label': label,
    'location': location,
  };
}

class RideDetailsViewModel extends ChangeNotifier {
  RideDetailsViewModel({RideRepository? rideRepository})
    : _rideRepository = rideRepository ?? RideRepository();

  static const List<SeatOption> _allSeatOptions = [
    SeatOption(id: 'front_seat', label: 'Front Seat', location: 'front seat'),
    SeatOption(
      id: 'back_left_door',
      label: 'Back Left Door',
      location: 'back seat left door',
    ),
    SeatOption(
      id: 'back_middle',
      label: 'Back Middle',
      location: 'back seat middle',
    ),
    SeatOption(
      id: 'back_right_door',
      label: 'Back Right Door',
      location: 'back seat right door',
    ),
  ];

  final RideRepository _rideRepository;

  final Set<String> _bookedSeats = {};
  final Set<String> _selectedSeats = {};
  List<SeatOption> _seatOptions = const [];
  String? _configuredRideId;
  int _seatFare = 1100;
  bool _isFullCarBooking = false;
  BookingStatus _status = BookingStatus.idle;
  String? _errorMessage;

  List<String> get seatIds => _seatOptions.map((seat) => seat.id).toList();
  List<SeatOption> get seatOptions => List.unmodifiable(_seatOptions);
  int get selectedSeatCount => _selectedSeats.length;
  int get remainingSeatCount =>
      _seatOptions.where((seat) => !isSeatBooked(seat.id)).length;
  bool get isProcessing => _status == BookingStatus.processing;
  bool get isConfirmed => _status == BookingStatus.confirmed;
  bool get isFullCarBooking => _isFullCarBooking;
  bool get isRideFull => remainingSeatCount == 0;
  String? get errorMessage => _errorMessage;
  bool get canConfirm =>
      _selectedSeats.isNotEmpty && !isProcessing && !isConfirmed;
  int get baseFare =>
      _seatFare * (selectedSeatCount == 0 ? 1 : selectedSeatCount);
  int get totalFare => baseFare;

  String get actionLabel {
    if (isRideFull && _selectedSeats.isEmpty && !isConfirmed) return 'Full';
    return switch (_status) {
      BookingStatus.idle => 'Confirm Booking',
      BookingStatus.processing => 'Processing...',
      BookingStatus.confirmed => 'Booking Confirmed!',
    };
  }

  bool isSeatSelected(String seatId) => _selectedSeats.contains(seatId);
  bool isSeatBooked(String seatId) => _bookedSeats.contains(seatId);
  bool isSeatAvailable(String seatId) => !isSeatBooked(seatId) && !isProcessing;

  String seatLabel(String seatId) =>
      _seatOption(seatId)?.label ?? 'Passenger seat';

  String seatLocation(String seatId) =>
      _seatOption(seatId)?.location ?? 'passenger seat';

  void configureForRide(RideOption ride) {
    final rideId = RideRepository.rideIdFor(ride);
    if (_configuredRideId == rideId) return;

    _configuredRideId = rideId;
    _bookedSeats
      ..clear()
      ..addAll(ride.bookedSeats);
    _selectedSeats.clear();
    _isFullCarBooking = false;
    _seatFare = _fareAmount(ride.fare);
    _seatOptions = _buildSeatOptions(
      availableSeats: ride.availableSeatCount,
      bookedSeats: _bookedSeats,
    );
    _status = BookingStatus.idle;
    _errorMessage = null;
  }

  void toggleSeat(String seatId) {
    if (!isSeatAvailable(seatId)) return;

    if (_selectedSeats.contains(seatId)) {
      _selectedSeats.remove(seatId);
    } else {
      _selectedSeats.add(seatId);
    }
    _isFullCarBooking = false;
    _errorMessage = null;
    if (_status == BookingStatus.confirmed) _status = BookingStatus.idle;
    notifyListeners();
  }

  void bookFullCarForFamily() {
    if (_bookedSeats.isNotEmpty || remainingSeatCount == 0 || isProcessing) {
      _errorMessage = _bookedSeats.isNotEmpty
          ? 'Full car booking is only available before any seat is booked.'
          : null;
      notifyListeners();
      return;
    }

    _selectedSeats
      ..clear()
      ..addAll(_seatOptions.map((seat) => seat.id));
    _isFullCarBooking = true;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> confirmBooking(RideOption ride) async {
    if (!canConfirm) return;

    final seatsToBook = _selectedSeats.toList();
    final details = seatsToBook
        .map((seatId) => _seatOption(seatId)!.toMap())
        .toList(growable: false);
    _status = BookingStatus.processing;
    _errorMessage = null;
    notifyListeners();

    try {
      await _rideRepository.createBooking(
        ride: ride,
        seats: seatsToBook,
        seatDetails: details,
        seatFare: _seatFare,
        totalFare: totalFare,
        isFullCarBooking: _isFullCarBooking,
      );
      _bookedSeats.addAll(seatsToBook);
      _selectedSeats.clear();
      _isFullCarBooking = false;
      _status = BookingStatus.confirmed;
    } on Object catch (error) {
      _errorMessage = error.toString().contains('seat-unavailable')
          ? 'One or more selected seats are already booked.'
          : error.toString().contains('ride-full')
          ? 'No seats are available.'
          : 'Unable to confirm booking. Please try again.';
      _status = BookingStatus.idle;
    }
    notifyListeners();
  }

  SeatOption? _seatOption(String seatId) {
    for (final seat in _seatOptions) {
      if (seat.id == seatId) return seat;
    }
    return null;
  }

  static List<SeatOption> _buildSeatOptions({
    required int availableSeats,
    required Set<String> bookedSeats,
  }) {
    final totalSeats = (availableSeats + bookedSeats.length).clamp(0, 4);
    final knownBookedSeats = _allSeatOptions.where(
      (seat) => bookedSeats.contains(seat.id),
    );
    final visibleSeats = _allSeatOptions.take(totalSeats);
    return {...knownBookedSeats, ...visibleSeats}.toList();
  }

  static int _fareAmount(String fare) {
    final digits = fare.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 1100;
  }
}
