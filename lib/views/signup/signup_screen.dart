import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/signup_content.dart';
import '../../viewmodels/signup_view_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.onSignedUp, this.onOpenLogin});

  final VoidCallback? onSignedUp;
  final VoidCallback? onOpenLogin;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit(SignupViewModel viewModel) async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final termsError = viewModel.validateTerms();
    if (termsError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(termsError),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (isFormValid && termsError == null) {
      await viewModel.submit();
      if (viewModel.isSuccess) {
        widget.onSignedUp?.call();
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
    final viewModel = context.watch<SignupViewModel>();
    final content = viewModel.content;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: SignupColors.background),
        child: Row(
          children: [
            if (isDesktop)
              SizedBox(
                width: MediaQuery.sizeOf(context).width / 2,
                child: _HeroPanel(content: content),
              ),
            Expanded(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 16,
                      vertical: 48,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 576 : 448,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(content: content, showBrand: !isDesktop),
                          const SizedBox(height: 24),
                          _SignupForm(
                            formKey: _formKey,
                            content: content,
                            viewModel: viewModel,
                            onSubmit: () => _submit(viewModel),
                          ),
                          const SizedBox(height: 24),
                          _LoginFooter(
                            content: content,
                            onOpenLogin: widget.onOpenLogin,
                          ),
                          const SizedBox(height: 48),
                          const _TrustBadges(),
                        ],
                      ),
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.content});

  final SignupContent content;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: SignupColors.primaryContainer),
      child: Stack(
        children: [
          const Positioned.fill(child: _MountainRoadScene()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: SignupColors.primaryContainer.withValues(alpha: 0.62),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.brandName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        height: 40 / 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content.heroBody,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 16,
                        height: 24 / 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroBadge(
                            icon: Icons.verified_user_outlined,
                            label: content.driverBadge,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _HeroBadge(
                            icon: Icons.payments_outlined,
                            label: content.fareBadge,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: const Color(0xFFADC6FF)),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
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

class _Header extends StatelessWidget {
  const _Header({required this.content, required this.showBrand});

  final SignupContent content;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBrand) ...[
          Text(
            content.brandName,
            style: const TextStyle(
              color: SignupColors.secondary,
              fontSize: 24,
              height: 32 / 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          content.heading,
          style: const TextStyle(
            color: SignupColors.primary,
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content.description,
          style: const TextStyle(
            color: SignupColors.onSurfaceVariant,
            fontSize: 16,
            height: 24 / 16,
          ),
        ),
      ],
    );
  }
}

class _SignupForm extends StatelessWidget {
  const _SignupForm({
    required this.formKey,
    required this.content,
    required this.viewModel,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final SignupContent content;
  final SignupViewModel viewModel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SignupColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
              _SignupField(
                label: content.fullNameLabel,
                hintText: content.fullNamePlaceholder,
                icon: Icons.person_outline,
                onChanged: viewModel.updateFullName,
                validator: (value) =>
                    viewModel.validateRequired(value, 'Full name'),
              ),
              const SizedBox(height: 16),
              _SignupField(
                label: content.emailLabel,
                hintText: content.emailPlaceholder,
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                onChanged: viewModel.updateEmail,
                validator: viewModel.validateEmail,
              ),
              const SizedBox(height: 16),
              _SignupField(
                label: content.phoneLabel,
                hintText: content.phonePlaceholder,
                icon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: viewModel.updatePhone,
                validator: viewModel.validatePhone,
              ),
              const SizedBox(height: 16),
              _SignupField(
                label: content.passwordLabel,
                hintText: content.passwordPlaceholder,
                icon: viewModel.isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                obscureText: !viewModel.isPasswordVisible,
                onIconPressed: viewModel.togglePasswordVisibility,
                onChanged: viewModel.updatePassword,
                validator: viewModel.validatePassword,
              ),
              const SizedBox(height: 18),
              _TermsRow(content: content, viewModel: viewModel),
              const SizedBox(height: 20),
              _SubmitButton(viewModel: viewModel, onPressed: onSubmit),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupField extends StatelessWidget {
  const _SignupField({
    required this.label,
    required this.hintText,
    required this.icon,
    required this.onChanged,
    required this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.onIconPressed,
  });

  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final VoidCallback? onIconPressed;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, color: SignupColors.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: SignupColors.onSurfaceVariant,
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: onIconPressed == null
                ? iconWidget
                : IconButton(
                    tooltip: 'Toggle password visibility',
                    onPressed: onIconPressed,
                    icon: iconWidget,
                  ),
            filled: true,
            fillColor: SignupColors.surfaceLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: _border(SignupColors.outlineVariant),
            enabledBorder: _border(SignupColors.outlineVariant),
            focusedBorder: _border(SignupColors.secondary, width: 2),
            errorBorder: _border(SignupColors.error),
            focusedErrorBorder: _border(SignupColors.error, width: 2),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.content, required this.viewModel});

  final SignupContent content;
  final SignupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: viewModel.acceptedTerms,
          onChanged: viewModel.setAcceptedTerms,
          activeColor: SignupColors.secondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 4,
              runSpacing: 2,
              children: [
                Text(
                  content.termsPrefix,
                  style: const TextStyle(
                    color: SignupColors.onSurfaceVariant,
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
                _InlineLink(content.termsLabel),
                const Text(
                  'and',
                  style: TextStyle(
                    color: SignupColors.onSurfaceVariant,
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
                _InlineLink('${content.privacyLabel}.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineLink extends StatelessWidget {
  const _InlineLink(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: SignupColors.secondary,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.viewModel, required this.onPressed});

  final SignupViewModel viewModel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: viewModel.isSubmitting ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: viewModel.isSuccess
            ? const Color(0xFF16A34A)
            : SignupColors.secondary,
        disabledBackgroundColor: SignupColors.secondary.withValues(alpha: 0.72),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: viewModel.isSubmitting
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                key: ValueKey(viewModel.actionLabel),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewModel.actionLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    viewModel.isSuccess
                        ? Icons.check_circle_outline
                        : Icons.arrow_forward,
                  ),
                ],
              ),
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter({required this.content, required this.onOpenLogin});

  final SignupContent content;
  final VoidCallback? onOpenLogin;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          content.loginPrompt,
          style: const TextStyle(
            color: SignupColors.onSurfaceVariant,
            fontSize: 16,
            height: 24 / 16,
          ),
        ),
        TextButton(
          onPressed: onOpenLogin,
          style: TextButton.styleFrom(
            foregroundColor: SignupColors.secondary,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            content.loginLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _TrustBadges extends StatelessWidget {
  const _TrustBadges();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TrustBadge(icon: Icons.shield_outlined, label: 'SECURE'),
        SizedBox(width: 24),
        _TrustBadge(icon: Icons.gpp_good_outlined, label: 'TRUSTED'),
        SizedBox(width: 24),
        _TrustBadge(icon: Icons.support_agent_outlined, label: '24/7 SUPPORT'),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.45,
      child: Column(
        children: [
          Icon(icon, color: SignupColors.onSurfaceVariant, size: 36),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: SignupColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MountainRoadScene extends StatelessWidget {
  const _MountainRoadScene();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MountainRoadPainter());
  }
}

class _MountainRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF233653), Color(0xFF445E78), Color(0xFF131B2E)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final mountainPaint = Paint()..color = const Color(0xFF94A3B8);
    final mountains = Path()
      ..moveTo(0, size.height * 0.58)
      ..lineTo(size.width * 0.18, size.height * 0.28)
      ..lineTo(size.width * 0.38, size.height * 0.58)
      ..lineTo(size.width * 0.55, size.height * 0.34)
      ..lineTo(size.width * 0.82, size.height * 0.6)
      ..lineTo(size.width, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(mountains, mountainPaint);

    final darkRidge = Paint()..color = const Color(0xFF24364C);
    final ridge = Path()
      ..moveTo(0, size.height * 0.64)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.48,
        size.width * 0.52,
        size.height * 0.64,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.78,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ridge, darkRidge);

    final roadPaint = Paint()..color = const Color(0xFF101827);
    final road = Path()
      ..moveTo(size.width * 0.12, size.height)
      ..quadraticBezierTo(
        size.width * 0.46,
        size.height * 0.74,
        size.width * 0.52,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.73,
        size.width * 0.92,
        size.height,
      )
      ..close();
    canvas.drawPath(road, roadPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFDEC29A)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.6),
      Offset(size.width * 0.5, size.height * 0.96),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

abstract final class SignupColors {
  static const background = Color(0xFFFCF8FA);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const primary = Color(0xFF000000);
  static const primaryContainer = Color(0xFF131B2E);
  static const secondary = Color(0xFF0058BE);
  static const onSurfaceVariant = Color(0xFF45464D);
  static const outlineVariant = Color(0xFFC6C6CD);
  static const error = Color(0xFFBA1A1A);
}
