import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Mirrors the web SignupPage at frontend/src/pages/SignupPage.tsx — same
/// field set, same defaults, same copy, same validation rules. The only
/// concession to mobile is that the right-hand visual panel (benefits +
/// testimonial) renders BELOW the form instead of beside it.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _specialty = 'General Medicine';
  bool _showPassword = false;
  bool _agreedToTerms = false;
  String? _termsError;

  // Same list as frontend/src/data/index.ts:364-380
  static const _specialties = <String>[
    'General Medicine',
    'Internal Medicine',
    'Family Medicine',
    'Pediatrics',
    'Psychiatry',
    'Psychology',
    'Cardiology',
    'Dermatology',
    'Orthopedics',
    'Neurology',
    'Oncology',
    'Emergency Medicine',
    'Surgery',
    'OB/GYN',
    'Other',
  ];

  // Web's web-only "What's included" benefits (lines 40-46).
  static const _benefits = <String>[
    '7-day free trial — no credit card',
    'All specialty templates included',
    'HIPAA-compliant & fully encrypted',
    'AI notes in under 60 seconds',
    'Cancel anytime, hassle-free',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Same scoring as the web: +1 for length≥8, uppercase, digit, special char.
  int get _passwordStrength {
    final p = _passCtrl.text;
    var s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s;
  }

  Color get _strengthColor => switch (_passwordStrength) {
        1 => AppColors.danger,
        2 => AppColors.warning,
        3 => AppColors.info,
        4 => AppColors.emerald400,
        _ => AppColors.cardBorder,
      };

  String get _strengthLabel => switch (_passwordStrength) {
        1 => 'Weak',
        2 => 'Fair',
        3 => 'Good',
        4 => 'Strong',
        _ => '',
      };

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _termsError = _agreedToTerms ? null : 'You must agree to the Terms and Privacy Policy';
    });
    final formOk = _formKey.currentState!.validate();
    if (!formOk || !_agreedToTerms) return;

    final ok = await ref.read(authControllerProvider.notifier).signup(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          specialty: _specialty,
        );

    if (!mounted) return;
    if (ok) {
      context.go('/dashboard');
    } else {
      final err = ref.read(authControllerProvider).error;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(err, style: const TextStyle(color: Colors.white)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return AuthScaffold(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SignupBrand(),
            const SizedBox(height: 28),
            _SignupHeading(),
            const SizedBox(height: 22),
            _FormCard(
              children: [
                // Google sign-up button (placeholder until OAuth is wired
                // through the same flow auth_controller exposes).
                _GoogleButton(
                  onTap: () => _openLink('https://pronoteai.com/signup?provider=google'),
                ),
                const SizedBox(height: 14),
                const _OrDivider(label: 'or sign up with email'),
                const SizedBox(height: 14),

                _FieldLabel('Full Name'),
                _StyledField(
                  controller: _nameCtrl,
                  hint: 'Dr. John Doe',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),

                _FieldLabel('Email Address'),
                _StyledField(
                  controller: _emailCtrl,
                  hint: 'you@clinic.com',
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim())) {
                      return 'Invalid email format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _FieldLabel('Specialty'),
                _SpecialtyDropdown(
                  value: _specialty,
                  items: _specialties,
                  onChanged: (v) => setState(() => _specialty = v ?? 'General Medicine'),
                ),
                const SizedBox(height: 14),

                _FieldLabel('Password'),
                _StyledField(
                  controller: _passCtrl,
                  hint: 'Min 8 characters',
                  obscureText: !_showPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  suffix: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.slate400,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Minimum 8 characters';
                    return null;
                  },
                ),
                if (_passCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _PasswordStrengthMeter(
                    score: _passwordStrength,
                    color: _strengthColor,
                    label: _strengthLabel,
                  ),
                ],
                const SizedBox(height: 14),

                _FieldLabel('Confirm Password'),
                _StyledField(
                  controller: _confirmCtrl,
                  hint: '••••••••',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _TermsCheckbox(
                  agreed: _agreedToTerms,
                  error: _termsError,
                  onTap: () => setState(() {
                    _agreedToTerms = !_agreedToTerms;
                    if (_agreedToTerms) _termsError = null;
                  }),
                  onTapTerms: () => context.go('/terms'),
                  onTapPrivacy: () => context.go('/privacy'),
                ),
                const SizedBox(height: 18),

                _CreateAccountButton(busy: state.busy, onPressed: _submit),
              ],
            ),

            const SizedBox(height: 22),

            // Mobile version of the web's right visual panel.
            const _BenefitsPanel(items: _benefits),
            const SizedBox(height: 14),
            const _Testimonial(),

            const SizedBox(height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account?',
                  style: TextStyle(color: AppColors.slate400, fontSize: 13),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Sub-widgets — kept private to this file. Each maps directly onto a
// chunk of the web SignupPage so a reader can find the corresponding
// JSX block by name.
// ─────────────────────────────────────────────────────────────────

class _SignupBrand extends StatelessWidget {
  const _SignupBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => GoRouter.of(context).go('/'),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: kEmeraldGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald500.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pronote',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'AI Medical Scribe',
                    style: TextStyle(color: AppColors.emerald400, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignupHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Start your 7-day free trial. No credit card required.',
          style: TextStyle(color: AppColors.slate400, fontSize: 13.5),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  // ignore: unused_element_parameter
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.slate400,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final Widget? suffix;

  const _StyledField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: AppColors.emerald400,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0x0DFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x14FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x14FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.emerald400.withValues(alpha: 0.5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.danger.withValues(alpha: 0.6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.danger.withValues(alpha: 0.7), width: 1.5),
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 14),
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 11.5),
      ),
    );
  }
}

class _SpecialtyDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _SpecialtyDropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        dropdownColor: AppColors.slate800,
        iconEnabledColor: AppColors.slate400,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          filled: false,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      ),
    );
  }
}

class _PasswordStrengthMeter extends StatelessWidget {
  final int score;
  final Color color;
  final String label;

  const _PasswordStrengthMeter({
    required this.score,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final on = score > i;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                height: 3,
                decoration: BoxDecoration(
                  color: on ? color : const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          score == 0 ? '' : '$label password',
          style: const TextStyle(color: AppColors.slate500, fontSize: 11),
        ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool agreed;
  final String? error;
  final VoidCallback onTap;
  final VoidCallback onTapTerms;
  final VoidCallback onTapPrivacy;

  const _TermsCheckbox({
    required this.agreed,
    required this.error,
    required this.onTap,
    required this.onTapTerms,
    required this.onTapPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: agreed
                      ? AppColors.emerald500
                      : (error != null ? AppColors.danger.withValues(alpha: 0.1) : const Color(0x0DFFFFFF)),
                  border: Border.all(
                    color: agreed
                        ? AppColors.emerald500
                        : (error != null ? AppColors.danger.withValues(alpha: 0.6) : const Color(0x29FFFFFF)),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: agreed
                      ? [
                          BoxShadow(
                            color: AppColors.emerald500.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: agreed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(color: AppColors.slate400, fontSize: 12, height: 1.5),
                    children: [
                      const TextSpan(text: 'I have read and agree to the '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: const TextStyle(
                          color: AppColors.emerald400,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: _TapGesture(onTapTerms),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: AppColors.emerald400,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: _TapGesture(onTapPrivacy),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You must agree to the Terms of Service and Privacy Policy to create an account.',
                    style: TextStyle(color: AppColors.danger.withValues(alpha: 0.9), fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Tiny shim so the inline TextSpan recognisers feel like the regular link
/// taps the rest of the app uses.
class _TapGesture extends TapGestureRecognizer {
  _TapGesture(VoidCallback onTap) {
    this.onTap = onTap;
  }
}

class _CreateAccountButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onPressed;

  const _CreateAccountButton({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: kEmeraldGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald500.withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: busy ? null : onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GoogleIcon(),
                const SizedBox(width: 10),
                const Text(
                  'Sign up with Google',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

/// Hand-drawn 4-colour Google "G" so we don't need an extra asset.
class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / 2;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = size.width * 0.18;
    final r = size.width * 0.42;
    final rect = Rect.fromCircle(center: Offset(c, c), radius: r);

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -1.05, 1.7, false, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -1.05 - 1.7, 1.65, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -1.05 - 1.7 - 1.65, 1.6, false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, -1.05 - 1.7 - 1.65 - 1.6, 1.5, false, paint);

    // Horizontal bar inside the G
    final barPaint = Paint()..color = const Color(0xFF4285F4)..strokeWidth = size.width * 0.16;
    canvas.drawLine(
      Offset(size.width * 0.55, c),
      Offset(size.width * 0.92, c),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0x14FFFFFF), height: 1)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 11.5, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0x14FFFFFF), height: 1)),
      ],
    );
  }
}

// ── Mobile equivalent of the web's right visual panel ───────────

class _BenefitsPanel extends StatelessWidget {
  final List<String> items;
  const _BenefitsPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: AppColors.emerald400, size: 14),
              SizedBox(width: 6),
              Text(
                "WHAT'S INCLUDED",
                style: TextStyle(
                  color: AppColors.slate400,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.emerald500.withValues(alpha: 0.18),
                        border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.4)),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.check, size: 11, color: AppColors.emerald400),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Testimonial extends StatelessWidget {
  const _Testimonial();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (_) => const Icon(Icons.star, color: AppColors.warning, size: 14),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '"Pronote has completely transformed my practice. I save over 2 hours every day and can finally focus on my patients."',
            style: TextStyle(
              color: AppColors.slate400,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: kEmeraldGradient,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('S',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Dr. Sarah Johnson',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  Text('Family Medicine',
                      style: TextStyle(color: AppColors.slate500, fontSize: 11)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.shield_outlined, color: AppColors.emerald400, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
