import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/home_content.dart';
import '../services/firebase_backend.dart';
import '../services/location_service.dart';

enum HomeTab { home, myRides, wallet, profile }

enum MyRidesTab { upcoming, past }

enum RideTier { economy, standard, premium }

class UpcomingRide {
  const UpcomingRide({
    required this.id,
    required this.status,
    required this.departureTime,
    required this.seat,
    required this.origin,
    required this.destination,
    required this.driverName,
    required this.vehicle,
    required this.plateNumber,
    required this.tier,
    required this.raw,
  });

  final String id;
  final String status;
  final String departureTime;
  final String seat;
  final String origin;
  final String destination;
  final String driverName;
  final String vehicle;
  final String plateNumber;
  final RideTier tier;
  final Map<String, dynamic> raw;
}

class RideHistoryItem {
  const RideHistoryItem({
    required this.id,
    required this.tier,
    required this.date,
    required this.from,
    required this.to,
    required this.fare,
    required this.status,
    required this.raw,
  });

  final String id;
  final RideTier tier;
  final String date;
  final String from;
  final String to;
  final String fare;
  final String status;
  final Map<String, dynamic> raw;
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.joined,
    required this.phone,
    required this.ridesTaken,
  });

  final String name;
  final String email;
  final String joined;
  final String phone;
  final String ridesTaken;
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
    required this.status,
  });

  final String title;
  final String time;
  final int points;
  final WalletTransactionType type;
  final String status;
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
  HomeViewModel({
    RideRepository? rideRepository,
    WalletRepository? walletRepository,
    AuthRepository? authRepository,
    LocationService? locationService,
  }) : _rideRepository = rideRepository ?? RideRepository(),
       _walletRepository = walletRepository ?? WalletRepository(),
       _authRepository = authRepository ?? AuthRepository(),
       _locationService = locationService ?? const LocationService() {
    loadInitialData();
  }

  static const detectedLocation = 'Current Location';
  final RideRepository _rideRepository;
  final WalletRepository _walletRepository;
  final AuthRepository _authRepository;
  final LocationService _locationService;

  final List<QuickRoute> quickRoutes = const [
    QuickRoute(label: 'Karak'),
    QuickRoute(label: 'Islamabad'),
    QuickRoute(label: 'Lahore'),
  ];

  UserProfile _profile = const UserProfile(
    name: 'Ride Link User',
    email: '',
    joined: 'Joined recently',
    phone: '',
    ridesTaken: '0',
  );

  final List<WalletReward> walletRewards = const [
    WalletReward(
      icon: Icons.redeem,
      title: 'Free Ride',
      subtitle: 'Earn points with every ride',
      isHighlighted: false,
    ),
    WalletReward(
      icon: Icons.bolt,
      title: 'Instant Top-up',
      subtitle: 'Via payment screenshot',
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
  bool _isLoadingRides = false;
  bool _isLoadingBookings = false;
  bool _isLoadingWallet = false;
  bool _hasLoadedRides = false;
  bool _hasLoadedBookings = false;
  bool _hasLoadedWallet = false;
  String? _ridesErrorMessage;
  List<RideOption> _rides = [];
  List<UpcomingRide> _upcomingRides = [];
  List<RideHistoryItem> _rideHistory = [];
  List<PastRide> _pastRides = [];
  Map<String, dynamic>? _completedRideNeedingRating;
  String? _dismissedRatingRideId;
  int _walletBalance = 0;
  int _pendingWalletCount = 0;
  List<WalletTransaction> _walletTransactions = [];

  String get from => _from;
  String get to => _to;
  bool get hasSearched => _hasSearched;
  bool get isLoadingRides => _isLoadingRides;
  bool get isLoadingBookings => _isLoadingBookings;
  bool get isLoadingWallet => _isLoadingWallet;
  bool get shouldShowRidesSkeleton => _isLoadingRides && !_hasLoadedRides;
  bool get shouldShowBookingsSkeleton =>
      _isLoadingBookings && !_hasLoadedBookings;
  bool get shouldShowWalletSkeleton => _isLoadingWallet && !_hasLoadedWallet;
  String? get ridesErrorMessage => _ridesErrorMessage;
  UserProfile get profile => _profile;
  List<PastRide> get pastRides => _pastRides;
  int get walletBalance => _walletBalance;
  String get pendingWalletApprovals {
    if (_pendingWalletCount == 0) return 'No pending top-up requests';
    return '$_pendingWalletCount top-up ${_pendingWalletCount == 1 ? 'request' : 'requests'} pending approval';
  }

  List<WalletTransaction> get walletTransactions => _walletTransactions;
  Map<String, dynamic>? get completedRideNeedingRating =>
      _completedRideNeedingRating;

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
    if (!_hasSearched || _searchedTo.isEmpty) return 'Available Rides';
    return '${_cityName(_searchedFrom)} to ${_cityName(_searchedTo)}';
  }

  String get searchSubtitle => 'Today';
  String get departingSoonLabel =>
      rides.isEmpty ? '--' : rides.first.pickupTime;
  String get safetyLabel =>
      rides.isEmpty ? 'No Drivers' : '${rides.length} Verified Drivers';
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

  Future<void> loadInitialData() async {
    await Future.wait([
      loadCurrentLocation(),
      loadRides(),
      loadBookings(),
      loadWallet(),
      loadProfile(),
    ]);
  }

  Future<void> loadCurrentLocation() async {
    final label = await _locationService.currentLocationLabel();
    if (label == null || label.isEmpty) return;
    _from = label;
    _searchedFrom = label;
    notifyListeners();
  }

  void resetToHomeTab() {
    _selectedTab = HomeTab.home;
    _isWalletTopUpOpen = false;
    _hasWalletProof = false;
    _isWalletProofSubmitted = false;
    notifyListeners();
  }

  void updateFrom(String value) {
    _from = value.trim();
  }

  void updateTo(String value) {
    _to = value.trim();
  }

  Future<void> loadRides() async {
    _isLoadingRides = true;
    _ridesErrorMessage = null;
    notifyListeners();
    try {
      _rides = await _rideRepository.fetchRides();
    } on Object {
      _rides = const [];
      _ridesErrorMessage = 'Unable to load rides from Firebase.';
    }
    _hasLoadedRides = true;
    _isLoadingRides = false;
    notifyListeners();
  }

  Future<void> loadBookings() async {
    _isLoadingBookings = true;
    notifyListeners();
    try {
      final bookingDocs = await _rideRepository.fetchCurrentUserManagedRides();
      final upcoming = <UpcomingRide>[];
      final past = <RideHistoryItem>[];
      final profilePast = <PastRide>[];
      for (final booking in bookingDocs) {
        if (_isPastBooking(booking)) {
          final item = _historyFromBooking(booking);
          past.add(item);
          profilePast.add(_pastRideFromHistory(item));
          if (_completedRideNeedingRating == null &&
              _needsDriverRating(booking)) {
            _completedRideNeedingRating = booking;
          }
        } else {
          upcoming.add(_upcomingRideFromBooking(booking));
        }
      }
      _upcomingRides = upcoming;
      _rideHistory = past;
      _pastRides = profilePast;
      _profile = UserProfile(
        name: _profile.name,
        email: _profile.email,
        joined: _profile.joined,
        phone: _profile.phone,
        ridesTaken: bookingDocs.length.toString(),
      );
    } on Object {
      _upcomingRides = [];
      _rideHistory = [];
      _pastRides = [];
    }
    _hasLoadedBookings = true;
    _isLoadingBookings = false;
    notifyListeners();
  }

  Future<void> loadWallet() async {
    _isLoadingWallet = true;
    notifyListeners();
    try {
      final snapshot = await _walletRepository.fetchWallet();
      _walletBalance = snapshot.balance;
      _pendingWalletCount = snapshot.pendingCount;
      _walletTransactions = snapshot.transactions
          .map(
            (item) => WalletTransaction(
              title: item.title,
              time: '${item.timeLabel} - ${item.statusLabel}',
              points: item.points,
              type: WalletTransactionType.deposit,
              status: item.statusLabel,
            ),
          )
          .toList();
    } on Object {
      _walletBalance = 0;
      _pendingWalletCount = 0;
      _walletTransactions = [];
    }
    _hasLoadedWallet = true;
    _isLoadingWallet = false;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    try {
      final data = await _authRepository.fetchCurrentUserProfile();
      if (data == null) return;
      _profile = UserProfile(
        name: (data['fullName'] ?? data['name'] ?? 'Ride Link User').toString(),
        email: (data['email'] ?? '').toString(),
        joined: _joinedLabel(data['createdAt']),
        phone: (data['phone'] ?? '').toString(),
        ridesTaken: _profile.ridesTaken,
      );
      notifyListeners();
    } on Object {
      // Keep existing profile data if Firebase is unavailable.
    }
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
    if (!_hasSearched) return;
    _hasSearched = false;
    notifyListeners();
  }

  void selectTab(HomeTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    if (tab != HomeTab.wallet) _isWalletTopUpOpen = false;
    if (tab == HomeTab.myRides || tab == HomeTab.profile) loadBookings();
    if (tab == HomeTab.wallet) loadWallet();
    if (tab == HomeTab.profile) loadProfile();
    notifyListeners();
  }

  void openWalletTopUp() {
    _isWalletTopUpOpen = true;
    notifyListeners();
  }

  void closeWalletTopUp() {
    if (!_isWalletTopUpOpen) return;
    _isWalletTopUpOpen = false;
    notifyListeners();
  }

  void returnToWallet() {
    _isWalletTopUpOpen = false;
    _hasWalletProof = false;
    _isSubmittingWalletProof = false;
    _isWalletProofSubmitted = false;
    loadWallet();
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
    if (!_hasWalletProof || _isSubmittingWalletProof) return;
    _isSubmittingWalletProof = true;
    notifyListeners();
    try {
      await _walletRepository.createTopUpPayment(
        proofName: 'payment_screenshot.jpg',
      );
      _isWalletProofSubmitted = true;
      _hasWalletProof = false;
      await loadWallet();
    } finally {
      _isSubmittingWalletProof = false;
      notifyListeners();
    }
  }

  Future<void> cancelManagedRide({
    required String managedRideId,
    required bool driverAgreed,
  }) async {
    await _rideRepository.cancelManagedRide(
      managedRideId: managedRideId,
      driverAgreed: driverAgreed,
    );
    await Future.wait([loadBookings(), loadRides(), loadWallet()]);
  }

  Future<void> changeManagedRideSeat({
    required String managedRideId,
    required List<String> newSeats,
    required List<Map<String, String>> seatDetails,
  }) async {
    await _rideRepository.changeManagedRideSeat(
      managedRideId: managedRideId,
      newSeats: newSeats,
      seatDetails: seatDetails,
    );
    await Future.wait([loadBookings(), loadRides()]);
  }

  Future<void> submitDriverRating({
    required String managedRideId,
    required int rating,
    String? comment,
  }) async {
    await _rideRepository.submitDriverRating(
      managedRideId: managedRideId,
      rating: rating,
      comment: comment,
    );
    _dismissedRatingRideId = managedRideId;
    _completedRideNeedingRating = null;
    notifyListeners();
    await loadBookings();
  }

  void dismissRatingPrompt() {
    _dismissedRatingRideId = _completedRideNeedingRating?['id']?.toString();
    _completedRideNeedingRating = null;
    notifyListeners();
  }

  Future<void> deleteCurrentAccount() => _authRepository.deleteCurrentAccount();

  void selectMyRidesTab(MyRidesTab tab) {
    if (_selectedMyRidesTab == tab) return;
    _selectedMyRidesTab = tab;
    notifyListeners();
  }

  List<RideOption> _filteredRides() {
    final fromQuery = _searchedFrom == detectedLocation
        ? ''
        : _normalize(_searchedFrom);
    final toQuery = _normalize(_searchedTo);
    return _rides.where((ride) {
      final fromMatches =
          fromQuery.isEmpty ||
          _normalize(ride.from).contains(fromQuery) ||
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
    if (cleaned.isEmpty) return '';
    return cleaned.split(RegExp(r'\s+')).first;
  }

  int _fareAmount(RideOption ride) {
    final digits = ride.fare.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  bool _isPastBooking(Map<String, dynamic> booking) {
    final status = (booking['bookingStatus'] ?? booking['status'] ?? '')
        .toString()
        .toLowerCase();
    return status == 'completed' ||
        status == 'cancelled' ||
        status == 'canceled';
  }

  bool _needsDriverRating(Map<String, dynamic> booking) {
    final id = booking['id']?.toString();
    final status = (booking['bookingStatus'] ?? booking['status'] ?? '')
        .toString()
        .toLowerCase();
    return status == 'completed' &&
        id != null &&
        id != _dismissedRatingRideId &&
        booking['userRating'] == null;
  }

  UpcomingRide _upcomingRideFromBooking(Map<String, dynamic> booking) {
    final seats = _stringList(booking['seatLabels']).isNotEmpty
        ? _stringList(booking['seatLabels'])
        : _stringList(booking['seats']);
    return UpcomingRide(
      id: booking['id']?.toString() ?? '',
      status: (booking['bookingStatus'] ?? booking['status'] ?? 'confirmed')
          .toString()
          .toUpperCase(),
      departureTime: booking['pickupTime']?.toString() ?? 'Today',
      seat: seats.isEmpty ? '--' : seats.join(', '),
      origin: booking['from']?.toString() ?? detectedLocation,
      destination: booking['to']?.toString() ?? 'Destination',
      driverName: booking['driverName']?.toString() ?? 'Verified Driver',
      vehicle:
          booking['vehicleDetails']?.toString() ??
          booking['vehicle']?.toString() ??
          'Verified Vehicle',
      plateNumber: 'BOOKED',
      tier: RideTier.standard,
      raw: booking,
    );
  }

  RideHistoryItem _historyFromBooking(Map<String, dynamic> booking) {
    return RideHistoryItem(
      id: booking['id']?.toString() ?? '',
      tier: RideTier.standard,
      date: _dateLabel(booking['createdAt']),
      from: booking['from']?.toString() ?? detectedLocation,
      to: booking['to']?.toString() ?? 'Destination',
      fare: _fareLabel(booking['totalFare']),
      status: (booking['bookingStatus'] ?? booking['status'] ?? 'Completed')
          .toString(),
      raw: booking,
    );
  }

  PastRide _pastRideFromHistory(RideHistoryItem item) {
    return PastRide(
      origin: item.from,
      destination: item.to,
      fare: item.fare,
      date: item.date,
      vehicle:
          item.raw['vehicleDetails']?.toString() ??
          item.raw['vehicle']?.toString() ??
          'Verified Vehicle',
      accentColor: const Color(0xFF0058BE),
    );
  }

  List<String> _stringList(Object? value) {
    if (value is List) return value.map((item) => item.toString()).toList();
    return const [];
  }

  String _fareLabel(Object? value) {
    if (value == null) return 'Rs. 0';
    final text = value.toString();
    return text.startsWith('Rs') ? text : 'Rs. $text';
  }

  String _joinedLabel(Object? value) {
    final date = value is Timestamp ? value.toDate() : null;
    if (date == null) return 'Joined recently';
    return 'Joined ${date.day}/${date.month}/${date.year}';
  }

  String _dateLabel(Object? value) {
    final date = value is Timestamp ? value.toDate() : null;
    if (date == null) return 'Today';
    return '${date.day}/${date.month}/${date.year}';
  }
}
