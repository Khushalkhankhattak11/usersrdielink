import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/forgot_password_content.dart';
import '../../viewmodels/forgot_password_view_model.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.onBackToLogin});

  final VoidCallback? onBackToLogin;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _sendCode(ForgotPasswordViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      await viewModel.sendCode();
      if (viewModel.errorMessage != null && mounted) {
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
    final viewModel = context.watch<ForgotPasswordViewModel>();
    final content = viewModel.content;

    return Scaffold(
      backgroundColor: ResetColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              _TopBar(content: content, onBack: widget.onBackToLogin),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 96, 16, 40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: _ResetCard(
                          formKey: _formKey,
                          content: content,
                          viewModel: viewModel,
                          onSendCode: () => _sendCode(viewModel),
                          onBackToLogin: widget.onBackToLogin,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  content.footer,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ResetColors.outline,
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.content, required this.onBack});

  final ForgotPasswordContent content;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ResetColors.surface,
          border: const Border(
            bottom: BorderSide(color: ResetColors.outlineVariant),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  tooltip: content.backToLoginLabel,
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: ResetColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  content.brandName,
                  style: const TextStyle(
                    color: ResetColors.secondary,
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.security_outlined,
                  color: ResetColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetCard extends StatelessWidget {
  const _ResetCard({
    required this.formKey,
    required this.content,
    required this.viewModel,
    required this.onSendCode,
    required this.onBackToLogin,
  });

  final GlobalKey<FormState> formKey;
  final ForgotPasswordContent content;
  final ForgotPasswordViewModel viewModel;
  final VoidCallback onSendCode;
  final VoidCallback? onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ResetColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CardHero(content: content),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      content.description,
                      style: const TextStyle(
                        color: ResetColors.onSurfaceVariant,
                        fontSize: 16,
                        height: 24 / 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _EmailField(content: content, viewModel: viewModel),
                    const SizedBox(height: 16),
                    _SendCodeButton(
                      viewModel: viewModel,
                      onPressed: onSendCode,
                    ),
                    const SizedBox(height: 24),
                    _DividerLabel(label: content.dividerLabel),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: onBackToLogin,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text(content.backToLoginLabel),
                        style: TextButton.styleFrom(
                          foregroundColor: ResetColors.secondary,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            height: 24 / 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _SupportNote(content: content),
          ],
        ),
      ),
    );
  }
}

class _CardHero extends StatelessWidget {
  const _CardHero({required this.content});

  final ForgotPasswordContent content;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 192,
      child: Stack(
        children: [
          const Positioned.fill(child: _DuskHighwayScene()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ResetColors.primaryContainer.withValues(alpha: 0.05),
                    ResetColors.primaryContainer.withValues(alpha: 0.3),
                    ResetColors.surfaceLowest,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: ResetColors.secondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Text(
                      content.badgeLabel.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content.heading,
                  style: const TextStyle(
                    color: ResetColors.primary,
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w700,
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

class _EmailField extends StatelessWidget {
  const _EmailField({required this.content, required this.viewModel});

  final ForgotPasswordContent content;
  final ForgotPasswordViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          content.emailLabel.toUpperCase(),
          style: const TextStyle(
            color: ResetColors.onSurfaceVariant,
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          keyboardType: TextInputType.emailAddress,
          onChanged: viewModel.updateEmail,
          validator: viewModel.validateEmail,
          decoration: InputDecoration(
            hintText: content.emailPlaceholder,
            prefixIcon: const Icon(
              Icons.mail_outline,
              color: ResetColors.outline,
              size: 20,
            ),
            filled: true,
            fillColor: ResetColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: _border(ResetColors.outlineVariant),
            enabledBorder: _border(ResetColors.outlineVariant),
            focusedBorder: _border(ResetColors.secondary, width: 2),
            errorBorder: _border(ResetColors.error),
            focusedErrorBorder: _border(ResetColors.error, width: 2),
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

class _SendCodeButton extends StatelessWidget {
  const _SendCodeButton({required this.viewModel, required this.onPressed});

  final ForgotPasswordViewModel viewModel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: viewModel.isSending ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: viewModel.isSent
            ? const Color(0xFF16A34A)
            : ResetColors.secondary,
        disabledBackgroundColor: ResetColors.secondary.withValues(alpha: 0.72),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: viewModel.isSending
            ? Row(
                key: const ValueKey('sending'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(viewModel.actionLabel),
                ],
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
                  Icon(viewModel.isSent ? Icons.check_circle : Icons.send),
                ],
              ),
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
        const Expanded(child: Divider(color: ResetColors.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: ResetColors.outline,
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: ResetColors.outlineVariant)),
      ],
    );
  }
}

class _SupportNote extends StatelessWidget {
  const _SupportNote({required this.content});

  final ForgotPasswordContent content;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ResetColors.surfaceLow,
        border: Border(top: BorderSide(color: ResetColors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info, color: ResetColors.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: ResetColors.onSurfaceVariant,
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                  children: [
                    TextSpan(text: '${content.note} '),
                    TextSpan(
                      text: content.supportLabel,
                      style: const TextStyle(
                        color: ResetColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuskHighwayScene extends StatelessWidget {
  const _DuskHighwayScene();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DuskHighwayPainter());
  }
}

class _DuskHighwayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF203653), Color(0xFF6B7280), Color(0xFF131B2E)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final glow = Paint()
      ..color = const Color(0xFFDEC29A).withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.26), 34, glow);

    final land = Paint()..color = const Color(0xFF26384F);
    final landPath = Path()
      ..moveTo(0, size.height * 0.66)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.52,
        size.width * 0.52,
        size.height * 0.64,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.78,
        size.width,
        size.height * 0.56,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(landPath, land);

    final roadPaint = Paint()..color = const Color(0xFF0D1526);
    final road = Path()
      ..moveTo(size.width * 0.18, size.height)
      ..lineTo(size.width * 0.48, size.height * 0.56)
      ..lineTo(size.width * 0.58, size.height * 0.56)
      ..lineTo(size.width * 0.88, size.height)
      ..close();
    canvas.drawPath(road, roadPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFFCDEB5).withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.62),
      Offset(size.width * 0.52, size.height * 0.94),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

abstract final class ResetColors {
  static const background = Color(0xFFFCF8FA);
  static const surface = Color(0xFFFCF8FA);
  static const surfaceLow = Color(0xFFF6F3F5);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const primary = Color(0xFF000000);
  static const primaryContainer = Color(0xFF131B2E);
  static const secondary = Color(0xFF0058BE);
  static const onSurfaceVariant = Color(0xFF45464D);
  static const outline = Color(0xFF76777D);
  static const outlineVariant = Color(0xFFC6C6CD);
  static const error = Color(0xFFBA1A1A);
}
