import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../models/home_content.dart';

class FirebaseBackend {
  const FirebaseBackend._();

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static FirebaseAuth? get auth {
    if (!_isInitialized) {
      return null;
    }
    return FirebaseAuth.instance;
  }

  static FirebaseFirestore? get firestore {
    if (!_isInitialized) {
      return null;
    }
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

  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    final auth = FirebaseBackend.auth;
    if (auth == null) {
      return null;
    }

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
    if (auth == null) {
      return null;
    }

    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(fullName);

    if (firestore != null && credential.user != null) {
      await firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final auth = FirebaseBackend.auth;
    if (auth == null) {
      return;
    }

    await auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await FirebaseBackend.auth?.signOut();
  }

  Future<void> deleteCurrentAccount() async {
    final user = FirebaseBackend.auth?.currentUser;
    final firestore = FirebaseBackend.firestore;
    if (user == null) {
      return;
    }

    if (firestore != null) {
      await firestore.collection('accountDeletionRequests').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'requested',
      }, SetOptions(merge: true));
      await firestore.collection('users').doc(user.uid).set({
        'deletedAt': FieldValue.serverTimestamp(),
        'deletionStatus': 'requested',
      }, SetOptions(merge: true));
    }

    await user.delete();
  }
}

class RideRepository {
  static const _rideCollection = 'rides';
  static const _bookingCollection = 'bookings';

  Future<List<RideOption>> fetchRides(List<RideOption> fallbackRides) async {
    final firestore = FirebaseBackend.firestore;
    if (firestore == null) {
      return fallbackRides;
    }

    final snapshot = await firestore.collection(_rideCollection).get();
    if (snapshot.docs.isEmpty) {
      await seedRides(fallbackRides);
      return fallbackRides;
    }

    return snapshot.docs
        .map((doc) => _rideFromDocument(doc.id, doc.data()))
        .toList();
  }

  Future<void> seedRides(List<RideOption> rides) async {
    final firestore = FirebaseBackend.firestore;
    if (firestore == null) {
      return;
    }

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
    required int totalFare,
  }) async {
    final auth = FirebaseBackend.auth;
    final firestore = FirebaseBackend.firestore;
    if (firestore == null || auth?.currentUser == null) {
      return;
    }

    final rideRef = firestore.collection(_rideCollection).doc(_rideId(ride));
    final bookingRef = firestore.collection(_bookingCollection).doc();

    await firestore.runTransaction((transaction) async {
      final rideSnapshot = await transaction.get(rideRef);
      final bookedSeats = List<String>.from(
        (rideSnapshot.data()?['bookedSeats'] as List<dynamic>?) ?? const [],
      );
      final hasConflict = seats.any(bookedSeats.contains);
      if (hasConflict) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'seat-unavailable',
          message: 'One or more selected seats are already booked.',
        );
      }

      transaction.set(rideRef, {
        ..._rideToDocument(ride),
        'bookedSeats': [...bookedSeats, ...seats],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(bookingRef, {
        'userId': auth!.currentUser!.uid,
        'rideId': _rideId(ride),
        'driverName': ride.driverName,
        'vehicle': ride.vehicleDetails,
        'pickupTime': ride.pickupTime,
        'dropoffTime': ride.dropoffTime,
        'from': ride.from,
        'to': ride.to,
        'seats': seats,
        'totalFare': totalFare,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<List<Map<String, dynamic>>> fetchCurrentUserBookings() async {
    final auth = FirebaseBackend.auth;
    final firestore = FirebaseBackend.firestore;
    if (auth?.currentUser == null || firestore == null) {
      return const [];
    }

    final snapshot = await firestore
        .collection(_bookingCollection)
        .where('userId', isEqualTo: auth!.currentUser!.uid)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  static String rideIdFor(RideOption ride) => _rideId(ride);

  static String _rideId(RideOption ride) {
    final raw = '${ride.driverName}-${ride.from}-${ride.to}-${ride.pickupTime}';
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static Map<String, Object?> _rideToDocument(RideOption ride) {
    return {
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
  }

  static RideOption _rideFromDocument(String id, Map<String, dynamic> data) {
    return RideOption(
      id: id,
      driverName: data['driverName'] as String? ?? 'Verified Driver',
      ratingLabel: data['ratingLabel'] as String? ?? '4.8 (100 rides)',
      vehicle: data['vehicle'] as String? ?? 'Verified Vehicle',
      vehicleDetails:
          data['vehicleDetails'] as String? ?? 'Verified Vehicle • Registered',
      tier: data['tier'] as String? ?? 'Standard',
      fare: data['fare'] as String? ?? 'Rs. 1,000',
      from: data['from'] as String? ?? 'Islamabad',
      to: data['to'] as String? ?? 'Karak',
      pickupTime: data['pickupTime'] as String? ?? '09:00 AM',
      dropoffTime: data['dropoffTime'] as String? ?? '01:00 PM',
      seatsLeft: data['seatsLeft'] as String? ?? '2 Seats Left',
      accentColor: _colorFromValue(data['accentColor'], 0xFF0058BE),
      badgeColor: _colorFromValue(data['badgeColor'], 0xFFD8E2FF),
      badgeTextColor: _colorFromValue(data['badgeTextColor'], 0xFF001A42),
      isLowSeat: data['isLowSeat'] as bool? ?? false,
      bookedSeats: List<String>.from(
        (data['bookedSeats'] as List<dynamic>?) ?? const [],
      ),
    );
  }

  static Color _colorFromValue(Object? value, int fallback) {
    if (value is int) {
      return Color(value);
    }
    return Color(fallback);
  }
}
