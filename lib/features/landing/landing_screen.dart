import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/plan.dart';
import '../../core/theme/app_theme.dart';

/// Marketing surface — what unauthenticated users see at "/".
/// Mirrors the web landing page sections: hero → stats → features →
/// how-it-works → pricing → security → FAQ → footer.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _openFaq = -1;

  // Section anchors used by the in-page nav links (Features, How It Works,
  // Pricing, Security, About). Each chip in the nav bar calls
  // Scrollable.ensureVisible on its key — Flutter then animates the scroll
  // smoothly to put that section at the top.
  final _featuresKey = GlobalKey();
  final _howItWorksKey = GlobalKey();
  final _pricingKey = GlobalKey();
  final _securityKey = GlobalKey();
  final _aboutKey = GlobalKey();

  void _jumpTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      alignment: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.slate900.withValues(alpha: 0.85),
                border: Border(
                  bottom: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    SizedBox(
                      height: 52,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: kEmeraldGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            const Text('Pronote',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.slate400,
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              child: const Text('Sign in'),
                            ),
                            const SizedBox(width: 6),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: kEmeraldGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextButton(
                                onPressed: () => context.go('/signup'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Start trial'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 42,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            _NavChip(label: 'Features', onTap: () => _jumpTo(_featuresKey)),
                            _NavChip(label: 'How It Works', onTap: () => _jumpTo(_howItWorksKey)),
                            _NavChip(label: 'Pricing', onTap: () => _jumpTo(_pricingKey)),
                            _NavChip(label: 'Security', onTap: () => _jumpTo(_securityKey)),
                            _NavChip(label: 'About', onTap: () => _jumpTo(_aboutKey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        // SingleChildScrollView + Column so every section is in the widget
        // tree at all times. This is what makes Scrollable.ensureVisible
        // work for jumps to far-away sections — a SliverList would lazy-
        // build children and the GlobalKey lookup would return null.
        child: Column(
          children: [
            const _HeroSection(),
            const _StatsBar(),
            KeyedSubtree(key: _featuresKey, child: const _FeaturesSection()),
            KeyedSubtree(key: _howItWorksKey, child: const _HowItWorksSection()),
            KeyedSubtree(key: _pricingKey, child: const _PricingSection()),
            KeyedSubtree(key: _securityKey, child: const _SecuritySection()),
            KeyedSubtree(key: _aboutKey, child: const _AboutSection()),
            _FaqSection(
              openIndex: _openFaq,
              onToggle: (i) => setState(() => _openFaq = _openFaq == i ? -1 : i),
            ),
            const _FinalCta(),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              label,
              style: const TextStyle(color: AppColors.slate400, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.slate900, AppColors.bgDeep, AppColors.slate900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.emerald500.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: AppColors.emerald400, size: 14),
                SizedBox(width: 6),
                Text(
                  'Trusted by 50,000+ clinicians',
                  style: TextStyle(color: AppColors.emerald400, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.8),
              children: [
                TextSpan(text: 'Your clinical notes.\n'),
                TextSpan(text: 'Auto', style: TextStyle(color: AppColors.emerald400)),
                TextSpan(text: ' generated.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Save 2+ hours per day on documentation. Pronote listens to your patient conversations and generates accurate clinical notes instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate400, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: kEmeraldGradient,
                borderRadius: BorderRadius.circular(16),
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
                  onTap: () => context.go('/signup'),
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Start free trial',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Sign in to your account'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 36,
                child: Stack(
                  children: List.generate(5, (i) {
                    final colors = [
                      const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF14B8A6)]),
                      const LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF6366F1)]),
                      const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)]),
                      const LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFEC4899)]),
                      const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF97316)]),
                    ];
                    return Positioned(
                      left: i * 20.0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: colors[i],
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bgDeep, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            ['E', 'S', 'J', 'M', 'R'][i],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (_) => const Icon(Icons.star, color: AppColors.warning, size: 14),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'from 2,000+ reviews',
                    style: TextStyle(color: AppColors.slate400, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stats bar
// ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('50,000+', 'Active clinicians', AppColors.emerald400),
      ('2M+', 'Notes generated', AppColors.info),
      ('10,000+', 'Hours saved daily', const Color(0xFFA78BFA)),
      ('98.5%', 'Accuracy rate', AppColors.warning),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.slate900, AppColors.slate800, AppColors.slate900],
        ),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 18,
        childAspectRatio: 1.6,
        children: stats
            .map(
              (s) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.$1,
                      style: TextStyle(color: s.$3, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(s.$2.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.slate400, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Features
// ─────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final features = [
      _Feat(Icons.access_time, AppColors.emerald400, 'Save 2+ hours/day',
          'Streamline your notes and reclaim time for what truly matters — your patients and your life.'),
      _Feat(Icons.shield_outlined, AppColors.info, 'HIPAA compliant & secure',
          "Your patients' data is encrypted and secure with industry-leading security protocols."),
      _Feat(Icons.bolt, const Color(0xFFA78BFA), 'Instant accuracy',
          'AI-powered medical speech recognition delivers accurate clinical documentation instantly.'),
      _Feat(Icons.psychology_outlined, const Color(0xFFFB7185), 'AI-powered summaries',
          'GPT-4 generates structured SOAP notes, HPI, assessment and plan automatically.'),
      _Feat(Icons.refresh, AppColors.warning, 'Real-time transcription',
          'See your conversation transcribed live as you speak with your patient.'),
      _Feat(Icons.lock_outline, const Color(0xFF22D3EE), 'Role-based access',
          'Secure multi-user support with admin controls and audit logging built in.'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.slate900, AppColors.slate800],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const _SectionBadge(label: 'Features', icon: Icons.auto_awesome),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.2),
              children: [
                TextSpan(text: 'Built for clinicians,\n'),
                TextSpan(text: 'by clinicians.', style: TextStyle(color: AppColors.emerald400)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Every feature designed to save you time and improve documentation quality.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate400, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FeatureCard(feature: f),
              )),
        ],
      ),
    );
  }
}

class _Feat {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _Feat(this.icon, this.color, this.title, this.desc);
}

class _FeatureCard extends StatelessWidget {
  final _Feat feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(feature.icon, color: feature.color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(feature.title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(feature.desc,
              style: const TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// How it works
// ─────────────────────────────────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('01', 'Start visit', 'Tap the mic and start recording the patient conversation.', Icons.mic, AppColors.emerald400),
      ('02', 'AI transcribes live', 'Real-time speech recognition captures every word as you speak.', Icons.graphic_eq, AppColors.info),
      ('03', 'Clinical note generated', 'Personalised SOAP note ready to review, edit, sign, and export.', Icons.description, const Color(0xFFA78BFA)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.slate800, AppColors.slate900],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const _SectionBadge(label: 'How it works', icon: Icons.checklist),
          const SizedBox(height: 12),
          const Text(
            'Super simple.',
            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'From patient visit to finalised note — in under 60 seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate400, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _StepCard(num: s.$1, title: s.$2, desc: s.$3, icon: s.$4, color: s.$5),
              )),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String num;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  const _StepCard({required this.num, required this.title, required this.desc, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 6),
              Text(num,
                  style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Pricing
// ─────────────────────────────────────────────────────────────────

class _PricingSection extends StatelessWidget {
  const _PricingSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
      color: AppColors.slate900,
      child: Column(
        children: [
          const _SectionBadge(label: 'Pricing', icon: Icons.workspace_premium_outlined),
          const SizedBox(height: 12),
          const Text(
            'Plain pricing.\nNo surprises.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.2),
          ),
          const SizedBox(height: 8),
          const Text(
            '7-day free trial on all paid plans. No credit card required.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate400, fontSize: 14),
          ),
          const SizedBox(height: 28),
          // Render the 4 real plans from kPlans (same source the /plans
          // checkout screen uses) so pricing copy can never drift between
          // landing and checkout.
          ...kPlans.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _LandingPlanCard(plan: p),
              )),
          // Enterprise lives outside kPlans because it has no self-serve
          // Stripe price — it routes to a "Contact sales" page.
          const _EnterprisePlanCard(),
        ],
      ),
    );
  }
}

class _LandingPlanCard extends StatelessWidget {
  final Plan plan;
  const _LandingPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: plan.highlight
            ? LinearGradient(
                colors: [AppColors.emerald500.withValues(alpha: 0.16), AppColors.teal500.withValues(alpha: 0.08)],
              )
            : null,
        color: plan.highlight ? null : AppColors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: plan.highlight ? AppColors.emerald500.withValues(alpha: 0.5) : AppColors.cardBorder,
          width: plan.highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.emerald500,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(plan.badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          if (plan.badge != null) const SizedBox(height: 10),
          Text(plan.name,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(plan.description, style: const TextStyle(color: AppColors.slate400, fontSize: 13)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(plan.price,
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
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
          const SizedBox(height: 14),
          ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.emerald400, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: plan.highlight
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: kEmeraldGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.go('/plans'),
                        borderRadius: BorderRadius.circular(14),
                        child: const Center(
                          child: Text('Start free trial',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () => context.go('/plans'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Start free trial'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EnterprisePlanCard extends StatelessWidget {
  const _EnterprisePlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enterprise',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('For health systems and large groups.',
              style: TextStyle(color: AppColors.slate400, fontSize: 13)),
          const SizedBox(height: 14),
          const Text('Custom',
              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 14),
          ...const [
            'Everything in Group',
            'EHR integrations',
            'Dedicated account manager',
            'Custom SLA',
            'On-premise deployment available',
          ].map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.emerald400, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => context.go('/enterprise'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Contact sales'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Security
// ─────────────────────────────────────────────────────────────────

class _SecuritySection extends StatelessWidget {
  const _SecuritySection();

  static const _trustBar = [
    _SecTrust(Icons.shield, 'HIPAA Compliant', [Color(0xFF34D399), Color(0xFF14B8A6)]),
    _SecTrust(Icons.lock, 'AES-256-GCM Encrypted', [Color(0xFF60A5FA), Color(0xFF6366F1)]),
    _SecTrust(Icons.refresh, '24h JWT Sessions', [Color(0xFFA78BFA), Color(0xFF8B5CF6)]),
    _SecTrust(Icons.bolt, 'Rate Limited APIs', [Color(0xFFFBBF24), Color(0xFFF97316)]),
  ];

  static const _detailCards = [
    _SecDetail(
      icon: Icons.lock,
      gradient: [Color(0xFF34D399), Color(0xFF14B8A6)],
      title: 'AES-256-GCM PHI Encryption',
      desc: 'All Protected Health Information is encrypted at rest using AES-256-GCM — the gold standard for medical data. Each record gets a unique IV and authentication tag to detect tampering.',
      badge: 'At Rest',
    ),
    _SecDetail(
      icon: Icons.shield,
      gradient: [Color(0xFF60A5FA), Color(0xFF6366F1)],
      title: 'HIPAA-Compliant Audit Logs',
      desc: 'Every data access, login attempt, note creation, and admin action is recorded in immutable audit logs with timestamps, IP addresses, and user agents for full regulatory traceability.',
      badge: 'Compliance',
    ),
    _SecDetail(
      icon: Icons.refresh,
      gradient: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
      title: 'JWT Session Management',
      desc: 'Authentication tokens expire in 24 hours per HIPAA session management requirements. Tokens are signed with a 256-bit secret and verified on every protected API request.',
      badge: 'Auth',
    ),
    _SecDetail(
      icon: Icons.bolt,
      gradient: [Color(0xFFFBBF24), Color(0xFFF97316)],
      title: 'Rate Limiting & Brute Force Protection',
      desc: 'API endpoints are rate-limited to 100 requests/15 min per IP. Login attempts are tracked — after 5 failures, accounts are automatically locked for 15 minutes to prevent brute force attacks.',
      badge: 'DDoS Shield',
    ),
    _SecDetail(
      icon: Icons.people,
      gradient: [Color(0xFFFB7185), Color(0xFFEC4899)],
      title: 'Role-Based Access Control',
      desc: 'Strict RBAC separates clinician and admin privileges. Users can only access their own patient notes. Admins have dedicated routes with additional authentication guards.',
      badge: 'RBAC',
    ),
    _SecDetail(
      icon: Icons.psychology,
      gradient: [Color(0xFF22D3EE), Color(0xFF0EA5E9)],
      title: 'bcrypt Password Hashing',
      desc: 'Passwords are never stored in plain text. bcrypt with cost factor 12 is used to hash all passwords — making offline dictionary attacks computationally infeasible.',
      badge: 'Credentials',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.slate800, AppColors.slate900],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Header
          const _SectionBadge(label: 'Security', icon: Icons.lock_outline),
          const SizedBox(height: 14),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.2),
              children: [
                TextSpan(text: 'Enterprise-grade '),
                TextSpan(text: 'security.', style: TextStyle(color: AppColors.emerald400)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Every layer of Pronote is built with HIPAA compliance and patient data protection as the foundation — not an afterthought.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate400, fontSize: 14, height: 1.55),
          ),
          const SizedBox(height: 28),

          // Hero trust bar — 4 small cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: _trustBar.map((t) => _TrustCard(item: t)).toList(),
          ),
          const SizedBox(height: 28),

          // Main 6-card detail grid (single column on phone for readability)
          ..._detailCards.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SecurityDetailCard(item: c),
              )),

          const SizedBox(height: 8),

          // Transport + Infrastructure row
          const _SecondaryCard(
            icon: Icons.shield,
            iconGradient: [Color(0xFF34D399), Color(0xFF14B8A6)],
            title: 'TLS Encryption in Transit',
            label: 'Transport Security',
            labelColor: AppColors.emerald400,
            desc: 'All data between client and server is encrypted via HTTPS/TLS. HTTP security headers are enforced using Helmet.js — preventing XSS, clickjacking, MIME sniffing, and other common web attacks.',
            chips: ['HTTPS / TLS', 'Helmet.js Headers', 'CORS Policy', 'XSS Protection', 'HSTS Enabled'],
            chipColor: AppColors.emerald400,
          ),
          const SizedBox(height: 12),
          const _SecondaryCard(
            icon: Icons.bolt,
            iconGradient: [Color(0xFF60A5FA), Color(0xFF6366F1)],
            title: 'Secure Infrastructure',
            label: 'Cloud Architecture',
            labelColor: AppColors.info,
            desc: 'Backend runs on Render with environment-variable-only secrets — no keys in source code. Supabase provides a SOC 2 Type II certified database with row-level security policies.',
            chips: ['Render Cloud', 'Supabase RLS', 'Env-Only Secrets', 'SOC 2 Type II', 'No Plaintext Keys'],
            chipColor: AppColors.info,
          ),
          const SizedBox(height: 24),

          // HIPAA compliance banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.emerald500.withValues(alpha: 0.16),
                AppColors.teal500.withValues(alpha: 0.06),
                AppColors.emerald500.withValues(alpha: 0.16),
              ]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.emerald500.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield, color: AppColors.emerald400, size: 14),
                      SizedBox(width: 6),
                      Text('HIPAA Compliant Platform',
                          style: TextStyle(color: AppColors.emerald400, fontSize: 12, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Your patients' privacy is our highest priority",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.25),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pronote is built from the ground up to meet and exceed HIPAA requirements. Every technical safeguard — from AES-256 encryption to 24-hour session expiry — is intentionally designed for clinical environments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.55),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _CheckBadge('Encryption at Rest'),
                    _CheckBadge('Encryption in Transit'),
                    _CheckBadge('Access Controls'),
                    _CheckBadge('Audit Logging'),
                    _CheckBadge('Session Timeout'),
                    _CheckBadge('Breach Notification Ready'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecTrust {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  const _SecTrust(this.icon, this.label, this.gradient);
}

class _TrustCard extends StatelessWidget {
  final _SecTrust item;
  const _TrustCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: item.gradient),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, color: Colors.white, size: 19),
          ),
          const SizedBox(height: 10),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SecDetail {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String desc;
  final String badge;
  const _SecDetail({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.desc,
    required this.badge,
  });
}

class _SecurityDetailCard extends StatelessWidget {
  final _SecDetail item;
  const _SecurityDetailCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: item.gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: Colors.white, size: 21),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.gradient.first.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: item.gradient.first.withValues(alpha: 0.3)),
                ),
                child: Text(
                  item.badge,
                  style: TextStyle(color: item.gradient.first, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.3)),
          const SizedBox(height: 6),
          Text(item.desc,
              style: const TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.55)),
        ],
      ),
    );
  }
}

class _SecondaryCard extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String label;
  final Color labelColor;
  final String desc;
  final List<String> chips;
  final Color chipColor;

  const _SecondaryCard({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.label,
    required this.labelColor,
    required this.desc,
    required this.chips,
    required this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: iconGradient),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(label,
                        style: TextStyle(color: labelColor, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(desc, style: const TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.55)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: chips
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: chipColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(c,
                          style: TextStyle(color: chipColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  final String label;
  const _CheckBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.emerald500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✓', style: TextStyle(color: AppColors.emerald400, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: AppColors.emerald400, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// About
// ─────────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
      color: AppColors.slate900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: _SectionBadge(label: 'About', icon: Icons.info_outline)),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Built by clinicians.\nFor clinicians.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pronote was started after watching family-medicine doctors lose two hours every evening to documentation. Charts came home. Dinners got cold. Burnout was the only thing keeping pace with the EHR.',
            style: TextStyle(color: AppColors.slate400, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 12),
          const Text(
            'We built Pronote to give that time back. Real clinicians designed every template. Every workflow was tested in a real clinic before it shipped. Every privacy decision was made with HIPAA, not just "compliance theatre", in mind.',
            style: TextStyle(color: AppColors.slate400, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag_outlined, color: AppColors.emerald400, size: 20),
                    SizedBox(width: 8),
                    Text('Our promise',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
                SizedBox(height: 10),
                _PromiseRow(text: 'Your patient data never trains an AI model.'),
                _PromiseRow(text: 'You can export and delete everything, anytime.'),
                _PromiseRow(text: 'A real human answers every support email — usually the same day.'),
                _PromiseRow(text: 'New features ship monthly — request anything you need at support@pronoteai.com.'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 12,
              children: [
                _Stat(big: '50K+', sub: 'clinicians'),
                _Stat(big: '2M+', sub: 'notes'),
                _Stat(big: '7-day', sub: 'free trial'),
                _Stat(big: '100%', sub: 'HIPAA-aligned'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromiseRow extends StatelessWidget {
  final String text;
  const _PromiseRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.emerald400, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.slate400, fontSize: 13.5, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String big;
  final String sub;
  const _Stat({required this.big, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(big,
            style: const TextStyle(color: AppColors.emerald400, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(color: AppColors.slate400, fontSize: 11)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FAQ
// ─────────────────────────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  final int openIndex;
  final void Function(int) onToggle;
  const _FaqSection({required this.openIndex, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      ('Is my patient data HIPAA-protected?',
          'Yes. All audio and clinical notes are encrypted in transit (TLS 1.3) and at rest (AES-256). We sign a Business Associate Agreement on every paid plan. Cloud backup is disabled at the OS level so PHI never leaks to Google Drive.'),
      ('How accurate is the AI transcription?',
          'Pronote averages 92.5% transcription accuracy on clinical vocabulary. You can always edit the generated note before signing — the AI is a draft, never the final record.'),
      ('How long can I record?',
          'Up to 2 hours of continuous recording per visit. The app warns at 1h55m and stops automatically at 2h.'),
      ('Can I import templates from another scribe?',
          'Yes — upload your existing template structure and we will format it. Custom templates support every section the major EHRs use (SOAP, HPI, A&P, ROS, etc.).'),
      ('What happens after the 7-day trial?',
          'You pick a paid plan or your account locks until you do. We never auto-charge a credit card you did not enter.'),
      ('Do you train AI models on my patient data?',
          'No. Patient audio and notes are never used to train any model. They live only in your account, encrypted, and are deleted when you delete your account.'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      color: AppColors.slate900,
      child: Column(
        children: [
          const _SectionBadge(label: 'FAQ', icon: Icons.help_outline),
          const SizedBox(height: 12),
          const Text(
            'Questions, answered.',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 24),
          ...faqs.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value.$1;
            final a = e.value.$2;
            final open = openIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onToggle(i),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(q,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                            ),
                            Icon(open ? Icons.expand_less : Icons.expand_more, color: AppColors.slate400),
                          ],
                        ),
                        if (open) ...[
                          const SizedBox(height: 10),
                          Text(a,
                              style: const TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.5)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Final CTA
// ─────────────────────────────────────────────────────────────────

class _FinalCta extends StatelessWidget {
  const _FinalCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.slate900, AppColors.bgDeep],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Ready to save 2+ hours a day?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.2),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start your 7-day free trial. No credit card required.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate400, fontSize: 14),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: kEmeraldGradient,
                borderRadius: BorderRadius.circular(16),
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
                  onTap: () => context.go('/signup'),
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Text("Get started — it's free",
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      color: AppColors.bgDeep,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: kEmeraldGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text('Pronote', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _FooterLink(label: 'Sign in', onTap: () => context.go('/login')),
              _FooterLink(label: 'Privacy', onTap: () => context.go('/privacy')),
              _FooterLink(label: 'Terms', onTap: () => context.go('/terms')),
              _FooterLink(label: 'HIPAA BAA', onTap: () => context.go('/hipaa-baa')),
              _FooterLink(label: 'Enterprise', onTap: () => context.go('/enterprise')),
              _FooterLink(label: 'Help', onTap: () => context.go('/help')),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '© 2026 Pronote — AI Medical Scribe',
            style: TextStyle(color: AppColors.slate500, fontSize: 11),
          ),
          const SizedBox(height: 4),
          const Text(
            'Built for clinicians. HIPAA-aligned. Made with care.',
            style: TextStyle(color: AppColors.slate500, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.slate400, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shared section badge
// ─────────────────────────────────────────────────────────────────

class _SectionBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.emerald500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.emerald400, size: 13),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: AppColors.emerald400, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
