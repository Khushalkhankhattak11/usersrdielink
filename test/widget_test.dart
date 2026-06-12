import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/viewmodels/connectivity_view_model.dart';
import 'package:ridelink/views/network/network_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridelink/main.dart';

void main() {
  testWidgets('network gate shows no internet then restores app', (
    WidgetTester tester,
  ) async {
    var isOnline = false;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ConnectivityViewModel(
          internetChecker: () async => isOnline,
          checkInterval: const Duration(minutes: 1),
        ),
        child: const MaterialApp(home: NetworkGate(child: Text('Real screen'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Real screen'), findsNothing);

    isOnline = true;
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    expect(find.text('Real screen'), findsOneWidget);
  });

  testWidgets('splash shows first and then onboarding renders first time', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp(enableConnectivityCheck: false));

    expect(find.text('Ride Link'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Ride Link'), findsOneWidget);
    expect(find.text('Travel in 3 Easy Steps'), findsOneWidget);
    expect(find.text('Find a Ride'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('returning logged-out user goes splash then login', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'is_logged_in': false,
    });

    await tester.pumpWidget(const MyApp(enableConnectivityCheck: false));

    expect(find.text('Ride Link'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
  });

  testWidgets('signup navigation renders form instead of blank screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'is_logged_in': false,
    });

    await tester.pumpWidget(const MyApp(enableConnectivityCheck: false));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Sign Up'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Sign Up'));
    await tester.pump(const Duration(milliseconds: 140));

    expect(find.byType(Scaffold), findsWidgets);
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('FULL NAME'), findsOneWidget);
    expect(find.text('PHONE NUMBER'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
  });

  testWidgets('logged-in user goes splash then home and can logout', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'is_logged_in': true,
    });

    await tester.pumpWidget(const MyApp(enableConnectivityCheck: false));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Available Rides'), findsOneWidget);
    expect(find.text('Search Rides'), findsOneWidget);
    expect(find.text('No rides found'), findsOneWidget);
    expect(find.text('Book Seat'), findsNothing);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('home search auto-fills from and filters rides dynamically', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'is_logged_in': true,
    });

    await tester.pumpWidget(const MyApp(enableConnectivityCheck: false));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Current Location'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).at(1), 'Karak');
    await tester.tap(find.text('Search Rides'));
    await tester.pumpAndSettle();

    expect(find.text('Current to Karak'), findsOneWidget);
    expect(find.text('0 RIDES FOUND'), findsOneWidget);
    expect(find.text('Cheapest first'), findsOneWidget);
    expect(find.text('No rides found'), findsOneWidget);
    expect(find.text('Search Rides'), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'Lahore');
    await tester.tap(find.text('Search Rides'));
    await tester.pumpAndSettle();

    expect(find.text('0 RIDES FOUND'), findsOneWidget);
    expect(find.text('No rides found'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('home bottom nav switches tabs dynamically', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'is_logged_in': true,
    });

    await tester.pumpWidget(const MyApp(enableConnectivityCheck: false));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Available Rides'), findsOneWidget);

    await tester.tap(find.text('My Rides'));
    await tester.pumpAndSettle();

    expect(find.text('NEXT JOURNEY'), findsOneWidget);
    expect(find.text('No current booking is available'), findsOneWidget);

    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();

    expect(find.text('HISTORY'), findsOneWidget);
    expect(find.text('No past booking is available'), findsOneWidget);

    await tester.tap(find.text('Wallet'));
    await tester.pumpAndSettle();

    expect(find.text('Wallet & Balance'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.text('Pending Approvals'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Ride Link User'), findsOneWidget);
    expect(find.text('Past Rides'), findsOneWidget);
    expect(find.text('Saved Routes'), findsOneWidget);
  });

  testWidgets('profile has policy, theme, and delete account controls', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'is_logged_in': true,
    });

    await tester.pumpWidget(const MyApp(enableConnectivityCheck: false));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Privacy Policy'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Ride Link uses account details'),
      findsOneWidget,
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Delete Account').first,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Travel in 3 Easy Steps'), findsNothing);
  });

  testWidgets('wallet top up opens instructions and submits proof', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'is_logged_in': true,
    });

    await tester.pumpWidget(const MyApp(enableConnectivityCheck: false));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Top Up'));
    await tester.pumpAndSettle();

    expect(find.text('Top Up Your Balance'), findsOneWidget);
    expect(find.text('EasyPaisa'), findsOneWidget);
    expect(find.text('JazzCash'), findsOneWidget);
    expect(find.text('How to Top Up'), findsOneWidget);

    await tester.tap(find.text('0300 1234567'));
    await tester.pumpAndSettle();
    expect(find.text('Number 03001234567 copied!'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('wallet_upload_proof')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('wallet_upload_proof')));
    await tester.pumpAndSettle();
    expect(find.text('payment_screenshot.jpg'), findsOneWidget);
    expect(find.text('Ready to submit'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('wallet_submit_verification')),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('wallet_submit_verification')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Upload Received'), findsOneWidget);
    expect(find.text('Pending Admin Review'), findsOneWidget);
    expect(find.text('POINTS TO ADD'), findsOneWidget);
    expect(find.text('1,000 pts'), findsOneWidget);
    expect(find.text('Return to Wallet'), findsOneWidget);

    await tester.tap(find.text('Return to Wallet'));
    await tester.pumpAndSettle();
    expect(find.text('Recent Transactions'), findsOneWidget);
  });

  testWidgets('forgot password opens from login', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'is_logged_in': false,
    });

    await tester.pumpWidget(const MyApp(enableConnectivityCheck: false));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('SECURITY HUB'), findsOneWidget);
    expect(find.text('Send Code'), findsOneWidget);
    expect(find.text('Back to Login'), findsOneWidget);
  });

  testWidgets('available rides do not use hardcoded booking cards', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'is_logged_in': true,
    });

    await tester.pumpWidget(const MyApp(enableConnectivityCheck: false));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Available Rides'), findsOneWidget);
    expect(find.text('No rides found'), findsOneWidget);
    expect(find.text('Book Seat'), findsNothing);
    expect(find.text('Ride Details'), findsNothing);
  });

  testWidgets('search results stay empty without Firebase ride documents', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'is_logged_in': true,
    });

    await tester.pumpWidget(const MyApp(enableConnectivityCheck: false));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'Karak');
    await tester.tap(find.text('Search Rides'));
    await tester.pumpAndSettle();

    expect(find.text('0 RIDES FOUND'), findsOneWidget);
    expect(find.text('No rides found'), findsOneWidget);
    expect(find.text('Book Seat'), findsNothing);
  });
}
