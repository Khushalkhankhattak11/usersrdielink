import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/splash_content.dart';
import '../../viewmodels/splash_view_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _loadingController;
  late final AnimationController _pulseController;
  late final Animation<double> _introOpacity;
  late final Animation<Offset> _introSlide;
  Offset _pointerOffset = Offset.zero;

  @override
  void initState() {
    super.initState();

    final viewModel = context.read<SplashViewModel>();

    _introController = AnimationController(
      vsync: this,
      duration: viewModel.introDuration,
    )..forward();
    _loadingController = AnimationController(
      vsync: this,
      duration: viewModel.loadingDuration,
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: viewModel.pulseDuration,
    )..repeat(reverse: true);

    _introOpacity = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _introSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _introController.dispose();
    _loadingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _trackPointer(PointerEvent event) {
    final size = MediaQuery.sizeOf(context);
    final x = (event.position.dx - size.width / 2) * 0.01;
    final y = (event.position.dy - size.height / 2) * 0.01;
    setState(() => _pointerOffset = Offset(x, y));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SplashViewModel>();
    final content = viewModel.content;

    return Scaffold(
      body: Listener(
        onPointerMove: _trackPointer,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF131B2E)),
          child: Stack(
            children: [
              const _AmbientBackground(),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 384),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const Spacer(),
                          FadeTransition(
                            opacity: _introOpacity,
                            child: SlideTransition(
                              position: _introSlide,
                              child: Transform.translate(
                                offset: _pointerOffset,
                                child: _LogoSection(content: content),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 40),
                                child: _LoadingSection(
                                  status: content.status,
                                  verificationLabel: content.verificationLabel,
                                  loadingController: _loadingController,
                                  pulseController: _pulseController,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: IgnorePointer(
                  child: Text(
                    content.footer,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0x4D7C839B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned(
          top: -130,
          left: -95,
          child: _Glow(color: Color(0x330058BE)),
        ),
        Positioned(
          right: -95,
          bottom: -130,
          child: _Glow(color: Color(0x33BEC6E0)),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection({required this.content});

  final SplashContent content;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Semantics(
                label: 'Ride Link logo',
                image: true,
                child: Image.asset(
                  'assets/images/Logo Section.png',
                  width: 240,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${content.brandLead} ${content.brandTail}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content.tagline.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0x997C839B),
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection({
    required this.status,
    required this.verificationLabel,
    required this.loadingController,
    required this.pulseController,
  });

  final String status;
  final String verificationLabel;
  final AnimationController loadingController;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: pulseController,
          builder: (context, child) {
            final opacity = 0.7 + (pulseController.value * 0.3);
            return Opacity(opacity: opacity, child: child);
          },
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xCC7C839B),
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 2,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: AnimatedBuilder(
                animation: loadingController,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: 0.25,
                    alignment: Alignment(-1 + loadingController.value * 2.5, 0),
                    child: child,
                  );
                },
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gpp_good, color: Color(0x667C839B), size: 18),
            const SizedBox(width: 8),
            Text(
              verificationLabel.toUpperCase(),
              style: const TextStyle(
                color: Color(0x667C839B),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
