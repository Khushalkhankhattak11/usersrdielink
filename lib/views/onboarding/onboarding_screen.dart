import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/onboarding_content.dart';
import '../../viewmodels/onboarding_view_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next(OnboardingViewModel viewModel) {
    if (viewModel.isLastPage) {
      widget.onFinished();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();

    return Scaffold(
      backgroundColor: OnboardingColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onSkip: widget.onFinished),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: viewModel.setPage,
                children: [
                  _StepsPage(steps: viewModel.steps),
                  _PricingPage(tiers: viewModel.pricingTiers),
                  _SafetyPage(tips: viewModel.safetyTips),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  _Dots(count: 3, activeIndex: viewModel.pageIndex),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _next(viewModel),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: OnboardingColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          viewModel.isLastPage ? 'I Understand' : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          viewModel.isLastPage
                              ? Icons.check_circle
                              : Icons.arrow_forward,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          const Text(
            'Ride Link',
            style: TextStyle(
              color: OnboardingColors.secondary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          TextButton(onPressed: onSkip, child: const Text('Skip')),
        ],
      ),
    );
  }
}

class _StepsPage extends StatelessWidget {
  const _StepsPage({required this.steps});

  final List<OnboardingStep> steps;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const _PageHeader(
            title: 'Travel in 3 Easy Steps',
            body:
                "Experience the next generation of intercity travel in Pakistan. We've simplified the process so you can focus on the destination.",
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: steps
                    .map(
                      (step) => SizedBox(
                        width: isWide
                            ? (constraints.maxWidth - 48) / 3
                            : constraints.maxWidth,
                        child: _StepCard(step: step),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'NO HIDDEN COSTS. FIXED FARES.',
            style: TextStyle(
              color: OnboardingColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: CircleAvatar(
                backgroundColor: OnboardingColors.primary,
                foregroundColor: Colors.white,
                child: Text(step.badge),
              ),
            ),
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 40,
              backgroundColor: OnboardingColors.secondaryFixed,
              child: Icon(
                step.icon,
                color: OnboardingColors.secondary,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              step.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OnboardingColors.onSurfaceVariant,
                fontSize: 14,
                height: 20 / 14,
              ),
            ),
            const SizedBox(height: 18),
            const _MiniRoadArt(height: 96),
          ],
        ),
      ),
    );
  }
}

class _PricingPage extends StatelessWidget {
  const _PricingPage({required this.tiers});

  final List<PricingTier> tiers;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PageHeader(
            title: 'Transparent Pricing',
            body:
                'Know your fare before you book. Rates are fixed per kilometer based on vehicle tier.',
          ),
          const SizedBox(height: 24),
          _FeaturedTier(tier: tiers.first),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _TierCard(tier: tiers[1])),
              const SizedBox(width: 12),
              Expanded(child: _TierCard(tier: tiers[2])),
            ],
          ),
          const SizedBox(height: 16),
          const _PolicyCard(),
        ],
      ),
    );
  }
}

class _FeaturedTier extends StatelessWidget {
  const _FeaturedTier({required this.tier});

  final PricingTier tier;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration(accent: OnboardingColors.secondary),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Capsule(text: tier.name.toUpperCase()),
            const SizedBox(height: 12),
            Text(
              tier.examples,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Executive travel and long-distance comfort on any terrain.',
              style: TextStyle(color: OnboardingColors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Text(
              tier.rate,
              style: const TextStyle(
                color: OnboardingColors.secondary,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            const _MiniRoadArt(height: 120),
          ],
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier});

  final PricingTier tier;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tier.badge.toUpperCase(),
              style: const TextStyle(
                color: OnboardingColors.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Icon(tier.icon, color: OnboardingColors.secondary),
            const SizedBox(height: 8),
            Text(
              tier.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              tier.examples,
              style: const TextStyle(
                color: OnboardingColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tier.rate,
              style: const TextStyle(
                color: OnboardingColors.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OnboardingColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.info, color: Color(0xFFADC6FF)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rates use the shortest GPS route. No hidden fuel surcharges or driver meal costs.',
                style: TextStyle(color: Color(0xFFBEC6E0), height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyPage extends StatelessWidget {
  const _SafetyPage({required this.tips});

  final List<SafetyTip> tips;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const _SafetyHero(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: tips
                    .map(
                      (tip) => SizedBox(
                        width: isWide
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth,
                        child: _SafetyCard(tip: tip),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          const _MonitoringCard(),
        ],
      ),
    );
  }
}

class _SafetyHero extends StatelessWidget {
  const _SafetyHero();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OnboardingColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: OnboardingColors.secondaryFixed,
              child: Icon(
                Icons.shield,
                color: OnboardingColors.secondary,
                size: 34,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Your Safety, Our Priority',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Rigorous safety protocols ensure every intercity journey is secure, reliable, and stress-free.',
              textAlign: TextAlign.center,
              style: TextStyle(color: OnboardingColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard({required this.tip});

  final SafetyTip tip;

  @override
  Widget build(BuildContext context) {
    final color = tip.isEmergency
        ? OnboardingColors.error
        : OnboardingColors.secondary;

    return DecoratedBox(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(tip.icon, color: color),
                const SizedBox(width: 8),
                Text(
                  tip.category.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tip.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              tip.description,
              style: const TextStyle(
                color: OnboardingColors.onSurfaceVariant,
                fontSize: 14,
                height: 20 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonitoringCard extends StatelessWidget {
  const _MonitoringCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OnboardingColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.info, color: Color(0xFFADC6FF)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'AI-driven route monitoring detects unusual stops or deviations in real time.',
                style: TextStyle(color: Color(0xFFBEC6E0), height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: OnboardingColors.onSurfaceVariant,
            fontSize: 16,
            height: 24 / 16,
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? OnboardingColors.secondary
                : OnboardingColors.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _Capsule extends StatelessWidget {
  const _Capsule({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OnboardingColors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MiniRoadArt extends StatelessWidget {
  const _MiniRoadArt({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(painter: _MiniRoadPainter()),
      ),
    );
  }
}

class _MiniRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8EEF8), Color(0xFFB8C8DC)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final road = Paint()..color = const Color(0xFF172033);
    final path = Path()
      ..moveTo(size.width * 0.1, size.height)
      ..lineTo(size.width * 0.45, size.height * 0.42)
      ..lineTo(size.width * 0.58, size.height * 0.42)
      ..lineTo(size.width * 0.92, size.height)
      ..close();
    canvas.drawPath(path, road);

    final line = Paint()
      ..color = const Color(0xFFDEC29A)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.54, size.height * 0.5),
      Offset(size.width * 0.5, size.height * 0.92),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

BoxDecoration _cardDecoration({Color? accent}) {
  return BoxDecoration(
    color: OnboardingColors.surfaceLowest,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: OnboardingColors.outlineVariant),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

abstract final class OnboardingColors {
  static const background = Color(0xFFFCF8FA);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F5);
  static const primary = Color(0xFF000000);
  static const primaryContainer = Color(0xFF131B2E);
  static const secondary = Color(0xFF0058BE);
  static const secondaryFixed = Color(0xFFD8E2FF);
  static const onSurfaceVariant = Color(0xFF45464D);
  static const outlineVariant = Color(0xFFC6C6CD);
  static const error = Color(0xFFBA1A1A);
}
