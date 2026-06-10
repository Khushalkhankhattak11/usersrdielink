import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_flow_view_model.dart';
import '../forgot_password/forgot_password_screen.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../ride_details/ride_details_screen.dart';
import '../signup/signup_screen.dart';

class AuthFlow extends StatelessWidget {
  const AuthFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthFlowViewModel>();
    final destination = viewModel.destination;
    final child = switch (destination) {
      AuthDestination.onboarding => OnboardingScreen(
        key: const ValueKey(AuthDestination.onboarding),
        onFinished: viewModel.completeOnboarding,
      ),
      AuthDestination.login => LoginScreen(
        key: const ValueKey(AuthDestination.login),
        onAuthenticated: viewModel.recordLogin,
        onOpenSignup: viewModel.openSignup,
        onForgotPassword: viewModel.openForgotPassword,
      ),
      AuthDestination.signup => SignupScreen(
        key: const ValueKey(AuthDestination.signup),
        onSignedUp: viewModel.recordSignup,
        onOpenLogin: viewModel.openLogin,
      ),
      AuthDestination.forgotPassword => ForgotPasswordScreen(
        key: const ValueKey(AuthDestination.forgotPassword),
        onBackToLogin: viewModel.openLogin,
      ),
      AuthDestination.home => HomeScreen(
        key: const ValueKey(AuthDestination.home),
        onLogout: viewModel.logout,
        onDeleteAccount: viewModel.deleteAccount,
        onBookSeat: viewModel.openRideDetails,
      ),
      AuthDestination.rideDetails => RideDetailsScreen(
        key: ValueKey(
          '${AuthDestination.rideDetails}-${viewModel.selectedRide?.id ?? viewModel.selectedRide?.driverName}',
        ),
        ride: viewModel.selectedRide!,
        onBack: viewModel.closeRideDetails,
      ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          children: [...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: child,
    );
  }
}
