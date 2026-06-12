import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/firebase_backend.dart';
import 'services/location_service.dart';
import 'viewmodels/app_theme_view_model.dart';
import 'viewmodels/auth_flow_view_model.dart';
import 'viewmodels/connectivity_view_model.dart';
import 'viewmodels/forgot_password_view_model.dart';
import 'viewmodels/home_view_model.dart';
import 'viewmodels/login_view_model.dart';
import 'viewmodels/onboarding_view_model.dart';
import 'viewmodels/ride_details_view_model.dart';
import 'viewmodels/signup_view_model.dart';
import 'viewmodels/splash_view_model.dart';
import 'views/auth/auth_flow.dart';
import 'views/network/network_gate.dart';
import 'views/splash/splash_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBackend.initialize();
  await const LocationService().requestStartupPermission();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.enableConnectivityCheck = true});

  final bool enableConnectivityCheck;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppThemeViewModel()),
        ChangeNotifierProvider(
          create: (_) =>
              ConnectivityViewModel(enabled: enableConnectivityCheck),
        ),
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => RideRepository()),
        ChangeNotifierProvider(create: (_) => AuthFlowViewModel()),
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => OnboardingViewModel()),
        ChangeNotifierProvider(create: (_) => SignupViewModel()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => RideDetailsViewModel()),
      ],
      child: Consumer<AppThemeViewModel>(
        builder: (context, themeViewModel, _) => MaterialApp(
          title: 'Ride Link',
          debugShowCheckedModeBanner: false,
          themeMode: themeViewModel.themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.2,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const NetworkGate(child: SplashGate(next: AuthFlow())),
        ),
      ),
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0058BE),
    brightness: brightness,
  );

  return ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF101113)
        : const Color(0xFFFCF8FA),
    fontFamily: 'Inter',
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: isDark
          ? const Color(0xFF101113)
          : const Color(0xFFFCF8FA),
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
