import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/login_content.dart';
import '../../viewmodels/login_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onAuthenticated,
    this.onOpenSignup,
    this.onForgotPassword,
  });

  final VoidCallback? onAuthenticated;
  final VoidCallback? onOpenSignup;
  final VoidCallback? onForgotPassword;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _introController;
  late final Animation<double> _introOpacity;
  late final Animation<Offset> _introSlide;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _introOpacity = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _introSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Future<void> _submit(LoginViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      await viewModel.submit();
      if (viewModel.isSuccess) {
        widget.onAuthenticated?.call();
      } else if (viewModel.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    final content = viewModel.content;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: Stack(
          children: [
            const _LoginBackground(),
            Row(
              children: [
                Expanded(
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 448),
                          child: FadeTransition(
                            opacity: _introOpacity,
                            child: SlideTransition(
                              position: _introSlide,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _BrandHeader(content: content),
                                  const SizedBox(height: 24),
                                  _LoginCard(
                                    formKey: _formKey,
                                    content: content,
                                    viewModel: viewModel,
                                    onSubmit: () => _submit(viewModel),
                                    onOpenSignup: widget.onOpenSignup,
                                    onForgotPassword: widget.onForgotPassword,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (MediaQuery.sizeOf(context).width >= 1024)
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width / 3,
                    child: _MarketingPanel(content: content),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.content});

  final LoginContent content;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          content.brandName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 28,
            height: 32 / 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.content,
    required this.viewModel,
    required this.onSubmit,
    required this.onOpenSignup,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final LoginContent content;
  final LoginViewModel viewModel;
  final VoidCallback onSubmit;
  final VoidCallback? onOpenSignup;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                content.heading,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content.description,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                  height: 20 / 14,
                ),
              ),
              const SizedBox(height: 16),
              _LabeledTextField(
                label: content.emailLabel,
                hintText: content.emailPlaceholder,
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                onChanged: viewModel.updateEmail,
                validator: viewModel.validateEmail,
              ),
              const SizedBox(height: 16),
              _LabeledTextField(
                label: content.passwordLabel,
                trailingLabel: content.forgotPasswordLabel,
                onTrailingPressed: onForgotPassword,
                hintText: content.passwordPlaceholder,
                icon: Icons.lock_outline,
                obscureText: !viewModel.isPasswordVisible,
                onChanged: viewModel.updatePassword,
                validator: viewModel.validatePassword,
                suffix: IconButton(
                  tooltip: viewModel.isPasswordVisible
                      ? 'Hide password'
                      : 'Show password',
                  onPressed: viewModel.togglePasswordVisibility,
                  icon: Icon(
                    viewModel.isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _PrimaryLoginButton(viewModel: viewModel, onPressed: onSubmit),
              const SizedBox(height: 24),
              _DividerLabel(label: content.dividerLabel),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      label: content.googleLabel,
                      child: const Text(
                        'G',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SocialButton(
                      label: content.appleLabel,
                      child: const Icon(Icons.apple, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SignUpFooter(content: content, onOpenSignup: onOpenSignup),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.hintText,
    required this.icon,
    required this.onChanged,
    required this.validator,
    this.trailingLabel,
    this.onTrailingPressed,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final String? trailingLabel;
  final VoidCallback? onTrailingPressed;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _FieldLabel(label)),
            if (trailingLabel != null)
              TextButton(
                onPressed: onTrailingPressed,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  trailingLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.surfaceLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: _fieldBorder(AppColors.outlineVariant),
            enabledBorder: _fieldBorder(AppColors.outlineVariant),
            focusedBorder: _fieldBorder(AppColors.secondary, width: 2),
            errorBorder: _fieldBorder(AppColors.error),
            focusedErrorBorder: _fieldBorder(AppColors.error, width: 2),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.onSurfaceVariant,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _PrimaryLoginButton extends StatelessWidget {
  const _PrimaryLoginButton({required this.viewModel, required this.onPressed});

  final LoginViewModel viewModel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: viewModel.isSubmitting ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: viewModel.isSuccess
            ? const Color(0xFF16A34A)
            : AppColors.secondary,
        disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.72),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 24 / 16,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: viewModel.isSubmitting
            ? Row(
                key: const ValueKey('submitting'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(viewModel.actionLabel),
                ],
              )
            : Text(key: ValueKey(viewModel.actionLabel), viewModel.actionLabel),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.outlineVariant)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.onSurface,
        side: const BorderSide(color: AppColors.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 16,
          height: 24 / 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          child,
          const SizedBox(width: 8),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _SignUpFooter extends StatelessWidget {
  const _SignUpFooter({required this.content, required this.onOpenSignup});

  final LoginContent content;
  final VoidCallback? onOpenSignup;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          content.signUpPrompt,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
            height: 20 / 14,
          ),
        ),
        TextButton(
          onPressed: onOpenSignup,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondary,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            content.signUpLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _MarketingPanel extends StatelessWidget {
  const _MarketingPanel({required this.content});

  final LoginContent content;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.primaryContainer),
      child: Stack(
        children: [
          const Positioned.fill(child: _RoadScene()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryContainer.withValues(alpha: 0.05),
                    AppColors.primaryContainer.withValues(alpha: 0.45),
                    AppColors.primaryContainer,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 48,
            right: 48,
            bottom: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.panelHeading,
                  style: const TextStyle(
                    color: Color(0xFFFEFCFF),
                    fontSize: 32,
                    height: 40 / 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  content.panelBody,
                  style: const TextStyle(
                    color: Color(0xCCFEFCFF),
                    fontSize: 16,
                    height: 24 / 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadScene extends StatelessWidget {
  const _RoadScene();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RoadScenePainter());
  }
}

class _RoadScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E2A44), Color(0xFF324967), Color(0xFF131B2E)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    final hillPaint = Paint()..color = const Color(0xFF263C54);
    final hillPath = Path()
      ..moveTo(0, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.43,
        size.width * 0.56,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.6,
        size.width,
        size.height * 0.5,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hillPath, hillPaint);

    final roadPaint = Paint()..color = const Color(0xFF0E1524);
    final roadPath = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.47, size.height * 0.56)
      ..lineTo(size.width * 0.62, size.height * 0.56)
      ..lineTo(size.width * 0.95, size.height)
      ..close();
    canvas.drawPath(roadPath, roadPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFFCDEB5).withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.6, size.height),
      Offset(size.width * 0.55, size.height * 0.6),
      linePaint,
    );

    final busPaint = Paint()..color = const Color(0xFFEAE7E9);
    final busRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.34, size.height * 0.46, 112, 54),
      const Radius.circular(10),
    );
    canvas.drawRRect(busRect, busPaint);

    final windowPaint = Paint()..color = const Color(0xFF2170E4);
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.37 + i * 26, size.height * 0.48, 20, 14),
          const Radius.circular(3),
        ),
        windowPaint,
      );
    }

    final wheelPaint = Paint()..color = const Color(0xFF111827);
    canvas.drawCircle(
      Offset(size.width * 0.39, size.height * 0.535),
      7,
      wheelPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.58, size.height * 0.535),
      7,
      wheelPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned(
          top: -140,
          right: -80,
          child: _SoftGlow(size: 384, color: Color(0x0D2170E4)),
        ),
        Positioned(
          bottom: -120,
          left: -80,
          child: _SoftGlow(size: 288, color: Color(0x1A2170E4)),
        ),
      ],
    );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

abstract final class AppColors {
  static const background = Color(0xFFFCF8FA);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F5);
  static const onSurface = Color(0xFF1B1B1D);
  static const onSurfaceVariant = Color(0xFF45464D);
  static const outlineVariant = Color(0xFFC6C6CD);
  static const secondary = Color(0xFF0058BE);
  static const primaryContainer = Color(0xFF131B2E);
  static const error = Color(0xFFBA1A1A);
}
