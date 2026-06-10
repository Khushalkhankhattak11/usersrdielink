import 'package:flutter/material.dart';

import '../models/home_content.dart';
import '../services/firebase_backend.dart';

enum HomeTab { home, myRides, wallet, profile }

enum MyRidesTab { upcoming, past }

enum RideTier { economy, standard, premium }

class UpcomingRide {
  const UpcomingRide({
    required this.status,
    required this.departureTime,
    required this.seat,
    required this.origin,
    required this.destination,
    required this.driverName,
    required this.vehicle,
    required this.plateNumber,
    required this.tier,
  });

  final String status;
  final String departureTime;
  final String seat;
  final String origin;
  final String destination;
  final String driverName;
  final String vehicle;
  final String plateNumber;
  final RideTier tier;
}

class RideHistoryItem {
  const RideHistoryItem({
    required this.tier,
    required this.date,
    required this.from,
    required this.to,
    required this.fare,
    required this.status,
  });

  final RideTier tier;
  final String date;
  final String from;
  final String to;
  final String fare;
  final String status;
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.joined,
    required this.phone,
    required this.ridesTaken,
    required this.averageRating,
  });

  final String name;
  final String joined;
  final String phone;
  final String ridesTaken;
  final String averageRating;
}

class PastRide {
  const PastRide({
    required this.origin,
    required this.destination,
    required this.fare,
    required this.date,
    required this.vehicle,
    required this.accentColor,
  });

  final String origin;
  final String destination;
  final String fare;
  final String date;
  final String vehicle;
  final Color accentColor;
}

enum WalletTransactionType { deposit, deduction }

class WalletTransaction {
  const WalletTransaction({
    required this.title,
    required this.time,
    required this.points,
    required this.type,
  });

  final String title;
  final String time;
  final int points;
  final WalletTransactionType type;
}

class WalletReward {
  const WalletReward({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isHighlighted,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isHighlighted;
}

enum ProfileActionKind {
  savedRoutes,
  settings,
  help,
  privacyPolicy,
  deleteAccount,
}

class ProfileActionItem {
  const ProfileActionItem({
    required this.kind,
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final ProfileActionKind kind;
  final IconData icon;
  final String label;
  final bool isDestructive;
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({RideRepository? rideRepository})
    : _rideRepository = rideRepository ?? RideRepository() {
    loadRides();
  }

  static const detectedLocation = 'Islamabad G-11 Markaz';
  final RideRepository _rideRepository;

  final List<QuickRoute> quickRoutes = const [
    QuickRoute(label: 'Karak'),
    QuickRoute(label: 'Islamabad'),
    QuickRoute(label: 'Lahore'),
  ];

  final List<RideOption> _allRides = const [
    RideOption(
      driverName: 'Ahmed Khan',
      ratingLabel: '4.8 (120 rides)',
      vehicle: 'Suzuki WagonR',
      vehicleDetails: 'Suzuki WagonR • White • LEA-4521',
      tier: 'Economy',
      fare: 'Rs. 900',
      from: 'Islamabad G-11 Markaz',
      to: 'Karak Main Bazar',
      pickupTime: '09:00 AM',
      dropoffTime: '01:30 PM',
      seatsLeft: '2 Seats Left',
      accentColor: Color(0xFF22C55E),
      badgeColor: Color(0xFFDCFCE7),
      badgeTextColor: Color(0xFF166534),
      isLowSeat: true,
    ),
    RideOption(
      driverName: 'Zubair Malik',
      ratingLabel: '4.9 (450 rides)',
      vehicle: 'Honda Civic',
      vehicleDetails: 'Honda Civic • Silver • ICT-8892',
      tier: 'Premium',
      fare: 'Rs. 1,800',
      from: 'Daewoo Terminal, Islamabad',
      to: 'Karak Toll Plaza',
      pickupTime: '10:30 AM',
      dropoffTime: '02:45 PM',
      seatsLeft: '4 Seats Left',
      accentColor: Color(0xFF8B5CF6),
      badgeColor: Color(0xFFF5F3FF),
      badgeTextColor: Color(0xFF5B21B6),
    ),
    RideOption(
      driverName: 'Captain Haider',
      ratingLabel: '5.0 (Elite Partner)',
      vehicle: 'Toyota Fortuner',
      vehicleDetails: 'Toyota Fortuner • Black • RIP-7788',
      tier: 'Luxury',
      fare: 'Rs. 3,500',
      from: 'Islamabad International Airport',
      to: 'Karak Civil Hospital Road',
      pickupTime: '02:00 PM',
      dropoffTime: '06:15 PM',
      seatsLeft: '3 Seats Left',
      accentColor: Color(0xFFEF4444),
      badgeColor: Color(0xFFFEE2E2),
      badgeTextColor: Color(0xFF991B1B),
    ),
  ];

  static const List<UpcomingRide> _fallbackUpcomingRides = [
    UpcomingRide(
      status: 'Confirmed',
      departureTime: 'Today, 04:30 PM',
      seat: '4A',
      origin: 'Islamabad G-11 Markaz',
      destination: 'Karak Terminal',
      driverName: 'Ahmed Ali',
      vehicle: 'Toyota Corolla 2020 • White',
      plateNumber: 'LEP-420',
      tier: RideTier.standard,
    ),
  ];

  static const List<RideHistoryItem> _fallbackRideHistory = [
    RideHistoryItem(
      tier: RideTier.premium,
      date: 'Oct 12, 2023',
      from: 'Lahore',
      to: 'Islamabad',
      fare: 'Rs. 3,500',
      status: 'Completed',
    ),
    RideHistoryItem(
      tier: RideTier.economy,
      date: 'Sep 28, 2023',
      from: 'Peshawar',
      to: 'Abbottabad',
      fare: 'Rs. 1,200',
      status: 'Completed',
    ),
    RideHistoryItem(
      tier: RideTier.standard,
      date: 'Sep 15, 2023',
      from: 'Multan',
      to: 'Lahore',
      fare: 'Rs. 2,100',
      status: 'Completed',
    ),
  ];

  final UserProfile profile = const UserProfile(
    name: 'Ahmed Hassan',
    joined: 'Joined March 2023',
    phone: '+92 300 1234567',
    ridesTaken: '12',
    averageRating: '4.9',
  );

  final List<PastRide> pastRides = const [
    PastRide(
      origin: 'Lahore (DHA Ph 5)',
      destination: 'Islamabad (Blue Area)',
      fare: 'PKR 3,200',
      date: 'Oct 12, 2023',
      vehicle: 'Honda Civic • White',
      accentColor: Color(0xFF3B82F6),
    ),
    PastRide(
      origin: 'Rawalpindi (Saddar)',
      destination: 'Peshawar (University Rd)',
      fare: 'PKR 1,800',
      date: 'Sep 28, 2023',
      vehicle: 'Toyota Corolla • Silver',
      accentColor: Color(0xFFCBD5E1),
    ),
  ];

  final int walletBalance = 2500;
  final String pendingWalletApprovals = '1 Top-up screenshot uploaded';

  final List<WalletTransaction> walletTransactions = const [
    WalletTransaction(
      title: 'Lahore to Islamabad',
      time: 'Yesterday, 4:30 PM',
      points: -1200,
      type: WalletTransactionType.deduction,
    ),
    WalletTransaction(
      title: 'Wallet Top-Up',
      time: 'Oct 24, 10:15 AM',
      points: 3000,
      type: WalletTransactionType.deposit,
    ),
    WalletTransaction(
      title: 'Multan to Lahore',
      time: 'Oct 22, 09:00 AM',
      points: -800,
      type: WalletTransactionType.deduction,
    ),
  ];

  final List<WalletReward> walletRewards = const [
    WalletReward(
      icon: Icons.redeem,
      title: 'Free Ride',
      subtitle: 'Earn 5,000 more pts',
      isHighlighted: false,
    ),
    WalletReward(
      icon: Icons.bolt,
      title: 'Instant Top-up',
      subtitle: 'Via EasyPaisa',
      isHighlighted: true,
    ),
  ];

  final List<ProfileActionItem> profileActions = const [
    ProfileActionItem(
      kind: ProfileActionKind.savedRoutes,
      icon: Icons.map,
      label: 'Saved Routes',
    ),
    ProfileActionItem(
      kind: ProfileActionKind.settings,
      icon: Icons.settings,
      label: 'Settings',
    ),
    ProfileActionItem(
      kind: ProfileActionKind.help,
      icon: Icons.help,
      label: 'Help & Support',
    ),
    ProfileActionItem(
      kind: ProfileActionKind.privacyPolicy,
      icon: Icons.privacy_tip,
      label: 'Privacy Policy',
    ),
    ProfileActionItem(
      kind: ProfileActionKind.deleteAccount,
      icon: Icons.delete_forever,
      label: 'Delete Account',
      isDestructive: true,
    ),
  ];

  String _from = detectedLocation;
  String _to = '';
  String _searchedFrom = detectedLocation;
  String _searchedTo = '';
  bool _hasSearched = false;
  HomeTab _selectedTab = HomeTab.home;
  MyRidesTab _selectedMyRidesTab = MyRidesTab.upcoming;
  bool _isWalletTopUpOpen = false;
  bool _hasWalletProof = false;
  bool _isSubmittingWalletProof = false;
  bool _isWalletProofSubmitted = false;
  List<RideOption> _rides = [];
  List<UpcomingRide> _upcomingRides = _fallbackUpcomingRides;
  List<RideHistoryItem> _rideHistory = _fallbackRideHistory;
  bool _isLoadingRides = false;
  String? _ridesErrorMessage;

  String get from => _from;
  String get to => _to;
  bool get hasSearched => _hasSearched;
  bool get isLoadingRides => _isLoadingRides;
  String? get ridesErrorMessage => _ridesErrorMessage;
  List<RideOption> get rides {
    final source = _hasSearched ? _filteredRides() : _rides;
    return [...source]
      ..sort((a, b) => _fareAmount(a).compareTo(_fareAmount(b)));
  }

  String get ridesFoundLabel {
    final count = rides.length;
    return '$count ${count == 1 ? 'Ride' : 'Rides'} Found';
  }

  String get searchTitle {
    if (!_hasSearched || _searchedTo.isEmpty) {
      return 'Available Rides';
    }

    return '${_cityName(_searchedFrom)} to ${_cityName(_searchedTo)}';
  }

  String get searchSubtitle => 'Today, 24 Oct';
  String get departingSoonLabel =>
      rides.isEmpty ? '--' : rides.first.pickupTime;
  String get safetyLabel =>
      rides.isEmpty ? 'No Pilots' : '${rides.length} Verified Pilots';
  List<UpcomingRide> get upcomingRides => _upcomingRides;
  List<RideHistoryItem> get rideHistory => _rideHistory;
  HomeTab get selectedTab => _selectedTab;
  MyRidesTab get selectedMyRidesTab => _selectedMyRidesTab;
  bool get isWalletTopUpOpen => _isWalletTopUpOpen;
  bool get hasWalletProof => _hasWalletProof;
  bool get isSubmittingWalletProof => _isSubmittingWalletProof;
  bool get isWalletProofSubmitted => _isWalletProofSubmitted;
  String get appBarTitle {
    if (_selectedTab == HomeTab.wallet &&
        _isWalletTopUpOpen &&
        !_isWalletProofSubmitted) {
      return 'Top Up';
    }

    return switch (_selectedTab) {
      HomeTab.home => 'Ride Link',
      HomeTab.myRides => 'My Rides',
      HomeTab.wallet => 'Wallet & Balance',
      HomeTab.profile => 'My Profile',
    };
  }

  void updateFrom(String value) {
    _from = value.trim();
  }

  Future<void> loadRides() async {
    _isLoadingRides = true;
    _ridesErrorMessage = null;
    notifyListeners();

    try {
      _rides = await _rideRepository.fetchRides(_allRides);
      await loadBookings();
    } on Object {
      _rides = _allRides;
      _ridesErrorMessage = 'Using demo rides while Firebase is unavailable.';
    }

    _isLoadingRides = false;
    notifyListeners();
  }

  Future<void> loadBookings() async {
    try {
      final bookingDocs = await _rideRepository.fetchCurrentUserBookings();
      if (bookingDocs.isEmpty) {
        _upcomingRides = _fallbackUpcomingRides;
        _rideHistory = _fallbackRideHistory;
        return;
      }

      _upcomingRides = bookingDocs.map(_upcomingRideFromBooking).toList();
      _rideHistory = _fallbackRideHistory;
    } on Object {
      _upcomingRides = _fallbackUpcomingRides;
      _rideHistory = _fallbackRideHistory;
    }
  }

  void updateTo(String value) {
    _to = value.trim();
  }

  void selectQuickRoute(QuickRoute route) {
    _to = route.label;
    searchRides();
  }

  void swapLocations() {
    final previousFrom = _from;
    _from = _to;
    _to = previousFrom;
    notifyListeners();
  }

  void searchRides() {
    _searchedFrom = _from.isEmpty ? detectedLocation : _from;
    _searchedTo = _to;
    _hasSearched = true;
    notifyListeners();
  }

  void closeSearchResults() {
    if (!_hasSearched) {
      return;
    }

    _hasSearched = false;
    notifyListeners();
  }

  void selectTab(HomeTab tab) {
    if (_selectedTab == tab) {
      return;
    }

    _selectedTab = tab;
    if (tab != HomeTab.wallet) {
      _isWalletTopUpOpen = false;
    }
    if (tab == HomeTab.myRides) {
      loadBookings().then((_) => notifyListeners());
    }
    notifyListeners();
  }

  void openWalletTopUp() {
    _isWalletTopUpOpen = true;
    notifyListeners();
  }

  void closeWalletTopUp() {
    if (!_isWalletTopUpOpen) {
      return;
    }

    _isWalletTopUpOpen = false;
    notifyListeners();
  }

  void returnToWallet() {
    _isWalletTopUpOpen = false;
    _hasWalletProof = false;
    _isSubmittingWalletProof = false;
    _isWalletProofSubmitted = false;
    notifyListeners();
  }

  void selectWalletProof() {
    _hasWalletProof = true;
    _isWalletProofSubmitted = false;
    notifyListeners();
  }

  void removeWalletProof() {
    _hasWalletProof = false;
    _isWalletProofSubmitted = false;
    notifyListeners();
  }

  Future<void> submitWalletProof() async {
    if (!_hasWalletProof || _isSubmittingWalletProof) {
      return;
    }

    _isSubmittingWalletProof = false;
    _isWalletProofSubmitted = true;
    notifyListeners();
  }

  void selectMyRidesTab(MyRidesTab tab) {
    if (_selectedMyRidesTab == tab) {
      return;
    }

    _selectedMyRidesTab = tab;
    notifyListeners();
  }

  List<RideOption> _filteredRides() {
    final fromQuery = _normalize(_searchedFrom);
    final toQuery = _normalize(_searchedTo);

    return _rides.where((ride) {
      final fromMatches =
          fromQuery.isEmpty ||
          _normalize(ride.from).contains(fromQuery) ||
          _normalize(
            ride.from,
          ).contains(_normalize(_cityName(_searchedFrom))) ||
          fromQuery.contains(_normalize(_cityName(ride.from)));
      final toMatches =
          toQuery.isEmpty ||
          _normalize(ride.to).contains(toQuery) ||
          _normalize(_cityName(ride.to)).contains(toQuery);
      return fromMatches && toMatches;
    }).toList();
  }

  String _normalize(String value) => value.toLowerCase().trim();

  String _cityName(String value) {
    final cleaned = value
        .replaceAll(',', ' ')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .trim();
    return cleaned.split(RegExp(r'\s+')).first;
  }

  int _fareAmount(RideOption ride) {
    final digits = ride.fare.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  UpcomingRide _upcomingRideFromBooking(Map<String, dynamic> booking) {
    final seats = List<String>.from(
      (booking['seats'] as List<dynamic>?) ?? const [],
    );
    return UpcomingRide(
      status: (booking['status'] as String? ?? 'confirmed').toUpperCase(),
      departureTime: booking['pickupTime'] as String? ?? 'Today',
      seat: seats.isEmpty ? '--' : seats.join(', '),
      origin: booking['from'] as String? ?? detectedLocation,
      destination: booking['to'] as String? ?? 'Destination',
      driverName: booking['driverName'] as String? ?? 'Verified Driver',
      vehicle: booking['vehicle'] as String? ?? 'Verified Vehicle',
      plateNumber: 'BOOKED',
      tier: RideTier.standard,
    );
  }
}
