import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/welcome_content.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.content,
    required this.onLogin,
    required this.onSignup,
  });

  final WelcomeContent content;
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF131B2E)),
        child: Stack(
          children: [
            const Positioned.fill(child: _WelcomeRoadScene()),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2E).withValues(alpha: 0.66),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: isWide
                        ? Row(
                            children: [
                              Expanded(child: _WelcomeCopy(content: content)),
                              const SizedBox(width: 40),
                              SizedBox(
                                width: 380,
                                child: _ActionPanel(
                                  content: content,
                                  onLogin: onLogin,
                                  onSignup: onSignup,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _WelcomeCopy(content: content),
                              const SizedBox(height: 32),
                              _ActionPanel(
                                content: content,
                                onLogin: onLogin,
                                onSignup: onSignup,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy({required this.content});

  final WelcomeContent content;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.brandName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 40 / 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content.eyebrow.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFADC6FF),
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          content.heading,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            height: 40 / 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content.body,
          style: const TextStyle(
            color: Color(0xD9FFFFFF),
            fontSize: 16,
            height: 24 / 16,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _FeaturePill(
              icon: Icons.payments_outlined,
              label: content.fixedFareLabel,
            ),
            _FeaturePill(
              icon: Icons.verified_user_outlined,
              label: content.verifiedLabel,
            ),
            _FeaturePill(
              icon: Icons.support_agent_outlined,
              label: content.supportLabel,
            ),
          ],
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFADC6FF), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.content,
    required this.onLogin,
    required this.onSignup,
  });

  final WelcomeContent content;
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.login),
                  label: Text(content.loginLabel),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: const Color(0xFF0058BE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onSignup,
                  icon: const Icon(Icons.person_add_outlined),
                  label: Text(content.signupLabel),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0x66FFFFFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeRoadScene extends StatelessWidget {
  const _WelcomeRoadScene();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WelcomeRoadPainter());
  }
}

class _WelcomeRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF263A5A), Color(0xFF131B2E)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final ridge = Paint()..color = const Color(0xFF314762);
    final ridgePath = Path()
      ..moveTo(0, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.42,
        size.width * 0.5,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.72,
        size.width,
        size.height * 0.5,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ridgePath, ridge);

    final road = Paint()..color = const Color(0xFF0B1020);
    final roadPath = Path()
      ..moveTo(size.width * 0.12, size.height)
      ..lineTo(size.width * 0.46, size.height * 0.54)
      ..lineTo(size.width * 0.58, size.height * 0.54)
      ..lineTo(size.width * 0.92, size.height)
      ..close();
    canvas.drawPath(roadPath, road);

    final line = Paint()
      ..color = const Color(0xFFDEC29A)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.54, size.height * 0.6),
      Offset(size.width * 0.5, size.height * 0.96),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
