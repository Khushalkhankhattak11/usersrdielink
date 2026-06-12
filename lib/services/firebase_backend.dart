import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../models/home_content.dart';
import 'location_service.dart';

class FirebaseBackend {
  const FirebaseBackend._();

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static FirebaseAuth? get auth {
    if (!_isInitialized) return null;
    return FirebaseAuth.instance;
  }

  static FirebaseFirestore? get firestore {
    if (!_isInitialized) return null;
    return FirebaseFirestore.instance;
  }

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
    } on Object {
      _isInitialized = false;
    }
  }
}

class AuthRepository {
  Future<User?> get currentUser async => FirebaseBackend.auth?.currentUser;

  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final user = FirebaseBackend.auth?.currentUser;
    final firestore = FirebaseBackend.firestore;
    if (user == null) return null;

    final data = <String, dynamic>{
      'uid': user.uid,
      'fullName': user.displayName ?? 'Ride Link User',
      'email': user.email ?? '',
      'phone': user.phoneNumber ?? '',
    };

    if (firestore == null) return data;

    final snapshot = await firestore.collection('users').doc(user.uid).get();
    if (snapshot.exists) data.addAll(snapshot.data() ?? const {});
    return data;
  }

  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    final auth = FirebaseBackend.auth;
    if (auth == null) return null;
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final auth = FirebaseBackend.auth;
    final firestore = FirebaseBackend.firestore;
    if (auth == null) return null;

    final normalizedPhone = _normalizePakistanPhone(phone);
    final phoneNetwork = _pakistanPhoneNetwork(normalizedPhone);
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(fullName);

    if (firestore != null && credential.user != null) {
      final token = await _fcmToken();
      final location = await const LocationService().currentLocationSnapshot();
      final userData = <String, Object?>{
        'uid': credential.user!.uid,
        'fullName': fullName,
        'email': email,
        'phone': normalizedPhone,
        'phoneNetwork': phoneNetwork,
        'walletBalance': 0,
        'driverPoints': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (token != null) {
        userData.addAll({
          'fcmToken': token,
          'fcmTokens': FieldValue.arrayUnion([token]),
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (location != null) {
        userData.addAll({
          'currentLocation': location['label'],
          'currentLatitude': location['latitude'],
          'currentLongitude': location['longitude'],
          'currentLocationSource': 'geolocator',
          'locationUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
      await firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userData, SetOptions(merge: true));
    }

    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await FirebaseBackend.auth?.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await FirebaseBackend.auth?.signOut();
  }

  Future<void> deleteCurrentAccount() async {
    final user = FirebaseBackend.auth?.currentUser;
    final firestore = FirebaseBackend.firestore;
    if (user == null) return;

    if (firestore != null) {
      final activeRides = await _activeManagedRides(firestore, user.uid);
      if (activeRides.isNotEmpty) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'active-booking-exists',
          message: 'Please cancel your active ride before deleting account.',
        );
      }
      await _deleteUserFirestoreData(firestore, user.uid);
    }

    await user.delete();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _activeManagedRides(
    FirebaseFirestore firestore,
    String uid,
  ) async {
    final snapshot = await firestore
        .collection('manage rides')
        .where('userId', isEqualTo: uid)
        .get();
    return snapshot.docs
        .where((doc) => !_inactiveStatuses.contains(_status(doc.data())))
        .toList();
  }

  Future<void> _deleteUserFirestoreData(
    FirebaseFirestore firestore,
    String uid,
  ) async {
    final collections = ['Payments', 'bookings', 'manage rides'];
    for (final collection in collections) {
      final byUserId = await firestore
          .collection(collection)
          .where('userId', isEqualTo: uid)
          .get();
      final byUid = await firestore
          .collection(collection)
          .where('uid', isEqualTo: uid)
          .get();
      final batch = firestore.batch();
      for (final doc in {...byUserId.docs, ...byUid.docs}) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await firestore.collection('accountDeletionRequests').doc(uid).delete();
    await firestore.collection('users').doc(uid).delete();
  }

  Future<String?> _fcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      return messaging.getToken();
    } on Object {
      return null;
    }
  }

  static String _normalizePakistanPhone(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9]'), '');

  static String? _pakistanPhoneNetwork(String phone) {
    if (RegExp(r'^030[0-9]').hasMatch(phone)) return 'Jazz';
    if (RegExp(r'^031[0-9]').hasMatch(phone)) return 'Zong';
    if (RegExp(r'^033[0-7]').hasMatch(phone)) return 'Ufone';
    if (RegExp(r'^034[0-9]').hasMatch(phone)) return 'Telenor';
    return null;
  }

  static String _status(Map<String, dynamic> data) =>
      (data['bookingStatus'] ?? data['status'] ?? '').toString().toLowerCase();

  static const _inactiveStatuses = {'cancelled', 'canceled', 'completed'};
}

class WalletPaymentItem {
  const WalletPaymentItem({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.points,
    required this.statusLabel,
    required this.isApproved,
  });

  final String id;
  final String title;
  final String timeLabel;
  final int points;
  final String statusLabel;
  final bool isApproved;
}

class WalletSnapshot {
  const WalletSnapshot({
    required this.balance,
    required this.pendingCount,
    required this.transactions,
  });

  final int balance;
  final int pendingCount;
  final List<WalletPaymentItem> transactions;
}

class WalletRepository {
  static const defaultTopUpPoints = 1000;
  static const _paymentsCollection = 'Payments';

  Future<void> createTopUpPayment({required String proofName}) async {
    final user = FirebaseBackend.auth?.currentUser;
    final firestore = FirebaseBackend.firestore;
    if (user == null || firestore == null) return;

    await firestore.collection(_paymentsCollection).add({
      'uid': user.uid,
      'userId': user.uid,
      'userEmail': user.email,
      'points': defaultTopUpPoints,
      'amountRupees': defaultTopUpPoints,
      'status': 'pending',
      'credited': false,
      'proofName': proofName,
      'proofType': 'screenshot',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<WalletSnapshot> fetchWallet() async {
    final user = FirebaseBackend.auth?.currentUser;
    final firestore = FirebaseBackend.firestore;
    if (user == null || firestore == null) {
      return const WalletSnapshot(
        balance: 0,
        pendingCount: 0,
        transactions: [],
      );
    }

    await _creditApprovedPayments(firestore, user.uid);
    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final paymentDocs = await firestore
        .collection(_paymentsCollection)
        .where('uid', isEqualTo: user.uid)
        .get();

    final transactions = paymentDocs.docs.map((doc) {
      final data = doc.data();
      final status = _statusLabel(data['status']);
      return WalletPaymentItem(
        id: doc.id,
        title: 'Wallet Top-Up',
        timeLabel: _dateLabel(data['createdAt']),
        points:
            _intValue(data['points']) ?? _intValue(data['amountRupees']) ?? 0,
        statusLabel: status,
        isApproved: status == 'Approved',
      );
    }).toList()..sort((a, b) => b.timeLabel.compareTo(a.timeLabel));

    return WalletSnapshot(
      balance: _intValue(userDoc.data()?['walletBalance']) ?? 0,
      pendingCount: transactions
          .where((item) => item.statusLabel == 'Pending')
          .length,
      transactions: transactions,
    );
  }

  Future<void> _creditApprovedPayments(
    FirebaseFirestore firestore,
    String uid,
  ) async {
    final snapshot = await firestore
        .collection(_paymentsCollection)
        .where('uid', isEqualTo: uid)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!_isApproved(data['status']) || data['credited'] == true) continue;
      final points =
          _intValue(data['points']) ?? _intValue(data['amountRupees']) ?? 0;
      if (points <= 0) continue;

      await firestore.runTransaction((transaction) async {
        final fresh = await transaction.get(doc.reference);
        final freshData = fresh.data();
        if (freshData == null ||
            freshData['credited'] == true ||
            !_isApproved(freshData['status'])) {
          return;
        }
        transaction.set(firestore.collection('users').doc(uid), {
          'walletBalance': FieldValue.increment(points),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.update(doc.reference, {
          'credited': true,
          'creditedAt': FieldValue.serverTimestamp(),
          'status': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    }
  }

  static bool _isApproved(Object? value) =>
      value == true || value.toString().toLowerCase() == 'approved';

  static String _statusLabel(Object? value) {
    if (_isApproved(value)) return 'Approved';
    return value.toString().toLowerCase() == 'rejected'
        ? 'Rejected'
        : 'Pending';
  }

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _dateLabel(Object? value) {
    final date = value is Timestamp ? value.toDate() : null;
    if (date == null) return 'Just now';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class RideRepository {
  static const _rideCollection = 'rides';
  static const _bookingCollection = 'bookings';
  static const _managedRideCollection = 'manage rides';

  Future<List<RideOption>> fetchRides() async {
    final firestore = FirebaseBackend.firestore;
    if (firestore == null) return const [];

    final snapshot = await firestore.collection(_rideCollection).get();
    if (snapshot.docs.isEmpty) return const [];
    return snapshot.docs
        .map((doc) => _rideFromDocument(doc.id, doc.data()))
        .toList();
  }

  Future<void> seedRides(List<RideOption> rides) async {
    final firestore = FirebaseBackend.firestore;
    if (firestore == null) return;
    final batch = firestore.batch();
    for (final ride in rides) {
      batch.set(
        firestore.collection(_rideCollection).doc(_rideId(ride)),
        _rideToDocument(ride),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> createBooking({
    required RideOption ride,
    required List<String> seats,
    required List<Map<String, String>> seatDetails,
    required int seatFare,
    required int totalFare,
    required bool isFullCarBooking,
  }) async {
    final auth = FirebaseBackend.auth;
    final firestore = FirebaseBackend.firestore;
    final user = auth?.currentUser;
    if (firestore == null || user == null) return;

    final rideId = _rideId(ride);
    final rideRef = firestore.collection(_rideCollection).doc(rideId);
    final bookingRef = firestore.collection(_bookingCollection).doc();
    final managedRef = firestore
        .collection(_managedRideCollection)
        .doc(bookingRef.id);
    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? const {};

    await firestore.runTransaction((transaction) async {
      final rideSnapshot = await transaction.get(rideRef);
      final rideData = rideSnapshot.data() ?? _rideToDocument(ride);
      final bookedSeats = List<String>.from(
        (rideData['bookedSeats'] as List<dynamic>?) ?? const [],
      );
      if (seats.any(bookedSeats.contains)) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'seat-unavailable',
          message: 'One or more selected seats are already booked.',
        );
      }

      final totalSeats = _totalSeatCount(rideData, ride, bookedSeats);
      final updatedBookedSeats = {...bookedSeats, ...seats}.toList();
      if (updatedBookedSeats.length > totalSeats) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'ride-full',
          message: 'No seats are available.',
        );
      }

      final seatsLeft = totalSeats - updatedBookedSeats.length;
      final passenger = {
        'userId': user.uid,
        'name': userData['fullName'] ?? user.displayName ?? 'Passenger',
        'email': userData['email'] ?? user.email ?? '',
        'phone': userData['phone'] ?? '',
        'seats': seats,
        'seatLabels': seatDetails.map((seat) => seat['label']).toList(),
        'bookingId': bookingRef.id,
        'fare': totalFare,
        'bookingType': isFullCarBooking ? 'full_car_family' : 'seat',
        'createdAt': Timestamp.now(),
      };

      final bookingData = {
        'id': bookingRef.id,
        'bookingId': bookingRef.id,
        'userId': user.uid,
        'uid': user.uid,
        'rideId': rideId,
        'driverUid': rideData['driverUid'] ?? ride.id,
        'driverName': ride.driverName,
        'driverPhone': rideData['driverPhone'] ?? '',
        'vehicle': ride.vehicle,
        'vehicleDetails': ride.vehicleDetails,
        'pickupTime': ride.pickupTime,
        'dropoffTime': ride.dropoffTime,
        'from': ride.from,
        'to': ride.to,
        'seats': seats,
        'seatDetails': seatDetails,
        'seatLabels': seatDetails.map((seat) => seat['label']).toList(),
        'seatFare': seatFare,
        'totalFare': totalFare,
        'bookingType': isFullCarBooking ? 'full_car_family' : 'seat',
        'bookingStatus': 'confirmed',
        'rideStatus': 'active',
        'status': 'confirmed',
        'canUserCancel': true,
        'canDriverCancel': true,
        'userCancellationAllowed': true,
        'driverCancellationAllowed': true,
        'paymentStatus': 'pending_pickup',
        'pointsDebitStatus': 'pending',
        'driverPayoutStatus': 'pending',
        'driverPayoutPoints': totalFare,
        'driverAgreedCancellation': false,
        'userName': userData['fullName'] ?? user.displayName ?? 'Passenger',
        'userEmail': userData['email'] ?? user.email ?? '',
        'userPhone': userData['phone'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      transaction.set(rideRef, {
        ...rideData,
        'bookedSeats': updatedBookedSeats,
        'bookedSeatCount': updatedBookedSeats.length,
        'passengerCount': FieldValue.increment(1),
        'passengers': FieldValue.arrayUnion([passenger]),
        'seatsLeft': _seatsLeftLabel(seatsLeft),
        'isLowSeat': seatsLeft <= 1 && seatsLeft > 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(bookingRef, bookingData);
      transaction.set(managedRef, bookingData);
    });
  }

  Future<List<Map<String, dynamic>>> fetchCurrentUserBookings() =>
      fetchCurrentUserManagedRides();

  Future<List<Map<String, dynamic>>> fetchCurrentUserManagedRides() async {
    final user = FirebaseBackend.auth?.currentUser;
    final firestore = FirebaseBackend.firestore;
    if (user == null || firestore == null) return const [];

    await settleDueManagedRidePayments();
    final snapshot = await firestore
        .collection(_managedRideCollection)
        .where('userId', isEqualTo: user.uid)
        .get();
    final docs = snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
    docs.sort(
      (a, b) =>
          _dateValue(b['createdAt']).compareTo(_dateValue(a['createdAt'])),
    );
    return docs;
  }

  Future<void> settleDueManagedRidePayments() async {
    final user = FirebaseBackend.auth?.currentUser;
    final firestore = FirebaseBackend.firestore;
    if (user == null || firestore == null) return;

    final snapshot = await firestore
        .collection(_managedRideCollection)
        .where('userId', isEqualTo: user.uid)
        .where('paymentStatus', isEqualTo: 'pending_pickup')
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!_isWithinDebitWindow(data['pickupTime']) ||
          _inactiveStatuses.contains(_status(data))) {
        continue;
      }
      final amount =
          _intValue(data['totalFare']) ??
          _intValue(data['driverPayoutPoints']) ??
          0;
      final driverUid = data['driverUid']?.toString();
      if (amount <= 0 || driverUid == null || driverUid.isEmpty) continue;

      await firestore.runTransaction((transaction) async {
        final fresh = await transaction.get(doc.reference);
        if (fresh.data()?['paymentStatus'] != 'pending_pickup') return;
        transaction.set(firestore.collection('users').doc(user.uid), {
          'walletBalance': FieldValue.increment(-amount),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.set(firestore.collection('users').doc(driverUid), {
          'walletBalance': FieldValue.increment(amount),
          'driverPoints': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.update(doc.reference, {
          'paymentStatus': 'paid',
          'pointsDebitStatus': 'deducted',
          'driverPayoutStatus': 'paid',
          'settledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    }
  }

  Future<void> cancelManagedRide({
    required String managedRideId,
    required bool driverAgreed,
  }) async {
    final firestore = FirebaseBackend.firestore;
    final user = FirebaseBackend.auth?.currentUser;
    if (firestore == null || user == null) return;

    final managedRef = firestore
        .collection(_managedRideCollection)
        .doc(managedRideId);
    await firestore.runTransaction((transaction) async {
      final managedSnapshot = await transaction.get(managedRef);
      final managedData = managedSnapshot.data();
      if (managedData == null) return;

      final seats = List<String>.from(
        (managedData['seats'] as List<dynamic>?) ?? const [],
      );
      final rideId = managedData['rideId']?.toString() ?? '';
      if (rideId.isNotEmpty) {
        final rideRef = firestore.collection(_rideCollection).doc(rideId);
        final rideSnapshot = await transaction.get(rideRef);
        final rideData = rideSnapshot.data() ?? const <String, dynamic>{};
        final bookedSeats = List<String>.from(
          (rideData['bookedSeats'] as List<dynamic>?) ?? const [],
        )..removeWhere(seats.contains);
        final totalSeats = _totalSeatCountFromData(
          rideData,
          bookedSeats.length + seats.length,
        );
        final seatsLeft = totalSeats - bookedSeats.length;
        transaction.set(rideRef, {
          'bookedSeats': bookedSeats,
          'bookedSeatCount': bookedSeats.length,
          'seatsLeft': _seatsLeftLabel(seatsLeft),
          'isLowSeat': seatsLeft <= 1 && seatsLeft > 0,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final penaltyRequired =
          !driverAgreed && _isWithinDebitWindow(managedData['pickupTime']);
      final amount = _intValue(managedData['totalFare']) ?? 0;
      if (penaltyRequired && amount > 0) {
        transaction.set(firestore.collection('users').doc(user.uid), {
          'walletBalance': FieldValue.increment(-amount),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      transaction.update(managedRef, {
        'bookingStatus': 'cancelled',
        'rideStatus': 'cancelled',
        'status': 'cancelled',
        'driverAgreedCancellation': driverAgreed,
        'pointsDebitStatus': penaltyRequired ? 'deducted' : 'not_deducted',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> changeManagedRideSeat({
    required String managedRideId,
    required List<String> newSeats,
    required List<Map<String, String>> seatDetails,
  }) async {
    final firestore = FirebaseBackend.firestore;
    if (firestore == null) return;

    final managedRef = firestore
        .collection(_managedRideCollection)
        .doc(managedRideId);
    await firestore.runTransaction((transaction) async {
      final managedSnapshot = await transaction.get(managedRef);
      final managedData = managedSnapshot.data();
      if (managedData == null) return;
      final rideId = managedData['rideId']?.toString() ?? '';
      final oldSeats = List<String>.from(
        (managedData['seats'] as List<dynamic>?) ?? const [],
      );
      if (rideId.isEmpty) return;

      final rideRef = firestore.collection(_rideCollection).doc(rideId);
      final rideSnapshot = await transaction.get(rideRef);
      final rideData = rideSnapshot.data() ?? const <String, dynamic>{};
      final bookedSeats = List<String>.from(
        (rideData['bookedSeats'] as List<dynamic>?) ?? const [],
      );
      final seatsBookedByOthers = bookedSeats.where(
        (seat) => !oldSeats.contains(seat),
      );
      if (newSeats.any(seatsBookedByOthers.contains)) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'seat-unavailable',
          message: 'Selected seat is already booked.',
        );
      }
      final updatedSeats = [...seatsBookedByOthers, ...newSeats];

      transaction.update(rideRef, {
        'bookedSeats': updatedSeats,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(managedRef, {
        'seats': newSeats,
        'seatDetails': seatDetails,
        'seatLabels': seatDetails.map((seat) => seat['label']).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> submitDriverRating({
    required String managedRideId,
    required int rating,
    String? comment,
  }) async {
    final firestore = FirebaseBackend.firestore;
    final user = FirebaseBackend.auth?.currentUser;
    if (firestore == null || user == null) return;

    await firestore.collection(_managedRideCollection).doc(managedRideId).set({
      'userRating': rating,
      'userRatingComment': comment ?? '',
      'ratedByUserId': user.uid,
      'ratedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String rideIdFor(RideOption ride) => _rideId(ride);

  static String _rideId(RideOption ride) {
    if (ride.id != null && ride.id!.isNotEmpty) return ride.id!;
    final raw = '${ride.driverName}-${ride.from}-${ride.to}-${ride.pickupTime}';
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static Map<String, Object?> _rideToDocument(RideOption ride) => {
    'driverName': ride.driverName,
    'ratingLabel': ride.ratingLabel,
    'vehicle': ride.vehicle,
    'vehicleDetails': ride.vehicleDetails,
    'tier': ride.tier,
    'fare': ride.fare,
    'from': ride.from,
    'to': ride.to,
    'pickupTime': ride.pickupTime,
    'dropoffTime': ride.dropoffTime,
    'seatsLeft': ride.seatsLeft,
    'accentColor': ride.accentColor.toARGB32(),
    'badgeColor': ride.badgeColor.toARGB32(),
    'badgeTextColor': ride.badgeTextColor.toARGB32(),
    'isLowSeat': ride.isLowSeat,
    'bookedSeats': ride.bookedSeats,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static RideOption _rideFromDocument(String id, Map<String, dynamic> data) {
    final publishedRide = data['publishedRide'] is Map
        ? Map<String, dynamic>.from(data['publishedRide'] as Map)
        : const <String, dynamic>{};
    final journeyPreview = data['journeyPreview'] is Map
        ? Map<String, dynamic>.from(data['journeyPreview'] as Map)
        : const <String, dynamic>{};
    final merged = {...publishedRide, ...data};
    final from =
        _stringValue(merged['from']) ??
        _joinPlace(journeyPreview['originCity'], journeyPreview['originPlace']);
    final to =
        _stringValue(merged['to']) ??
        _joinPlace(
          journeyPreview['destinationCity'],
          journeyPreview['destinationPlace'],
        );

    return RideOption(
      id: id,
      driverName: _stringValue(merged['driverName']) ?? 'Verified Driver',
      ratingLabel: _stringValue(merged['ratingLabel']) ?? '',
      vehicle: _stringValue(merged['vehicle']) ?? 'Verified Vehicle',
      vehicleDetails:
          _stringValue(merged['vehicleDetails']) ??
          'Verified Vehicle - Registered',
      tier: _stringValue(merged['tier']) ?? 'Standard',
      fare: _stringValue(merged['fare']) ?? 'Rs. 1,000',
      from: from.isEmpty ? 'Current Location' : from,
      to: to.isEmpty ? 'Destination' : to,
      pickupTime: _stringValue(merged['pickupTime']) ?? '',
      dropoffTime: _stringValue(merged['dropoffTime']) ?? '',
      seatsLeft: _stringValue(merged['seatsLeft']) ?? '04 Seats Left',
      accentColor: _colorFromValue(merged['accentColor'], 0xFF0058BE),
      badgeColor: _colorFromValue(merged['badgeColor'], 0xFFD8E2FF),
      badgeTextColor: _colorFromValue(merged['badgeTextColor'], 0xFF001A42),
      isLowSeat: merged['isLowSeat'] as bool? ?? false,
      bookedSeats: List<String>.from(
        (merged['bookedSeats'] as List<dynamic>?) ?? const [],
      ),
    );
  }

  static int _totalSeatCount(
    Map<String, dynamic> data,
    RideOption ride,
    List<String> bookedSeats,
  ) => _totalSeatCountFromData(
    data,
    bookedSeats.length + ride.availableSeatCount,
  );

  static int _totalSeatCountFromData(Map<String, dynamic> data, int fallback) {
    final vehicles = data['vehicles'];
    if (vehicles is List && vehicles.isNotEmpty) return 4;
    final passengers = data['passengers'];
    if (passengers is List && passengers.length > 4) return passengers.length;
    return fallback <= 0 ? 4 : fallback;
  }

  static String _seatsLeftLabel(int count) {
    if (count <= 0) return 'Full';
    return '${count.toString().padLeft(2, '0')} ${count == 1 ? 'Seat' : 'Seats'} Left';
  }

  static String _status(Map<String, dynamic> data) =>
      (data['bookingStatus'] ?? data['status'] ?? '').toString().toLowerCase();

  static bool _isWithinDebitWindow(Object? pickupTime) {
    final pickup = _pickupDateTime(pickupTime?.toString() ?? '');
    if (pickup == null) return false;
    final now = DateTime.now();
    return !now.isBefore(pickup.subtract(const Duration(minutes: 30)));
  }

  static DateTime? _pickupDateTime(String value) {
    if (value.trim().isEmpty) return null;
    final match = RegExp(
      r'(\d{1,2}):(\d{2})\s*([AP]M)',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final meridiem = match.group(3)?.toUpperCase();
    if (hour == null || minute == null) return null;
    if (meridiem == 'PM' && hour != 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(
      value?.toString().replaceAll(RegExp(r'[^0-9-]'), '') ?? '',
    );
  }

  static DateTime _dateValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String? _stringValue(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _joinPlace(Object? city, Object? place) {
    return [
      _stringValue(city),
      _stringValue(place),
    ].whereType<String>().join(' ').trim();
  }

  static Color _colorFromValue(Object? value, int fallback) {
    if (value is int) return Color(value);
    return Color(fallback);
  }

  static const _inactiveStatuses = {'cancelled', 'canceled', 'completed'};
}
