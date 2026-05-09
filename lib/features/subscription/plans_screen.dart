import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/billing_api.dart';
import '../../core/models/plan.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

/// On iOS we hide the Stripe button — Apple's payment policy lets us redirect
/// out for a B2B medical service, but PayPal's web checkout is the cleaner
/// option that keeps us out of App Review trouble.
bool get _stripeAllowed {
  if (kIsWeb) return true;
  return Platform.isAndroid;
}

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  String? _busyPlanId;

  Future<void> _onSelectPlan(Plan plan) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      // Not signed in → bounce them through signup, then they come back here.
      context.go('/signup');
      return;
    }

    final provider = await _showPaymentSheet(plan);
    if (provider == null) return;

    setState(() => _busyPlanId = plan.id);

    try {
      final session = await ref.read(billingApiProvider).startCheckout(
            planId: plan.id,
            provider: provider,
          );

      final uri = Uri.parse(session.url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        throw ApiException('Could not open the checkout page in your browser.');
      }

      if (!mounted) return;
      _showCompleteOnReturnHint();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message, AppColors.danger);
    } catch (e) {
      if (!mounted) return;
      _toast('Could not start checkout: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _busyPlanId = null);
    }
  }

  Future<CheckoutProvider?> _showPaymentSheet(Plan plan) {
    return showModalBottomSheet<CheckoutProvider>(
      context: context,
      backgroundColor: AppColors.slate800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.slate500,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              Text(
                plan.name,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick how you\'d like to pay',
                style: const TextStyle(color: AppColors.slate400, fontSize: 13),
              ),
              const SizedBox(height: 18),
              if (_stripeAllowed)
                _PaymentMethodRow(
                  icon: Icons.credit_card,
                  label: 'Credit / Debit card',
                  sub: 'Visa · Mastercard · Amex via Stripe',
                  color: AppColors.info,
                  onTap: () => Navigator.pop(ctx, CheckoutProvider.stripe),
                ),
              _PaymentMethodRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'PayPal',
                sub: 'Pay from your PayPal balance or linked card',
                color: const Color(0xFF003087),
                onTap: () => Navigator.pop(ctx, CheckoutProvider.paypal),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 13, color: AppColors.slate400),
                  SizedBox(width: 6),
                  Text(
                    'Payment is secured by Stripe / PayPal — we never see your card details.',
                    style: TextStyle(color: AppColors.slate400, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompleteOnReturnHint() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate800,
        title: const Row(
          children: [
            Icon(Icons.open_in_new, color: AppColors.emerald400),
            SizedBox(width: 8),
            Text('Finish checkout in your browser', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'We opened the secure checkout page in your browser. Once you complete payment, return to the app — your subscription unlocks automatically.',
          style: TextStyle(color: AppColors.slate400, fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: AppColors.emerald400, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final currentPlanId = user?.subscriptionPlan;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Plans'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(user == null ? '/' : '/dashboard'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text(
              'Choose your plan',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            const Text(
              '7-day free trial on every plan. No credit card required to try Pronote.',
              style: TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 18),
            ...kPlans.map((plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PlanCard(
                    plan: plan,
                    busy: _busyPlanId == plan.id,
                    isCurrent: currentPlanId == plan.id,
                    onSelect: () => _onSelectPlan(plan),
                  ),
                )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.emerald400, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'HIPAA Business Associate Agreement is included on every paid plan — no separate paperwork required.',
                      style: TextStyle(color: AppColors.slate400, fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: () => context.go('/enterprise'),
                icon: const Icon(Icons.workspace_premium_outlined, size: 16),
                label: const Text('Need more than this? See Enterprise →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final bool busy;
  final bool isCurrent;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.busy,
    required this.isCurrent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: plan.highlight
            ? LinearGradient(colors: [
                AppColors.emerald500.withValues(alpha: 0.16),
                AppColors.teal500.withValues(alpha: 0.06),
              ])
            : null,
        color: plan.highlight ? null : AppColors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: plan.highlight
              ? AppColors.emerald400.withValues(alpha: 0.55)
              : AppColors.cardBorder,
          width: plan.highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.badge != null)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald500,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  plan.badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ),
            ),
          if (plan.badge != null) const SizedBox(height: 10),
          Text(plan.name,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.price,
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(plan.period, style: const TextStyle(color: AppColors.slate400, fontSize: 13)),
              ),
            ],
          ),
          if (plan.secondary != null) ...[
            const SizedBox(height: 2),
            Text(plan.secondary!,
                style: const TextStyle(color: AppColors.emerald400, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 6),
          Text(plan.description,
              style: const TextStyle(color: AppColors.slate400, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 14),
          ...plan.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.emerald400, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isCurrent
                ? Container(
                    decoration: BoxDecoration(
                      color: AppColors.emerald500.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.4)),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: AppColors.emerald400, size: 18),
                          SizedBox(width: 8),
                          Text('Your current plan',
                              style: TextStyle(color: AppColors.emerald400, fontSize: 14, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  )
                : plan.highlight
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: kEmeraldGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: busy ? null : onSelect,
                            child: Center(
                              child: busy
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                                  : const Text(
                                      'Start free trial',
                                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                                    ),
                            ),
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: busy ? null : onSelect,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: busy
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.emerald400))
                            : const Text('Start free trial'),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _PaymentMethodRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(sub, style: const TextStyle(color: AppColors.slate400, fontSize: 11.5)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.slate400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
