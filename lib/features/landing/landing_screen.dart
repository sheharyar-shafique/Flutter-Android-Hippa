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
  final _scrollCtrl = ScrollController();

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
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      // ── Premium slide-out menu ──
      endDrawer: _LandingDrawer(
        onNavigate: (key) {
          Navigator.pop(context); // close drawer
          _jumpTo(key);
        },
        featuresKey: _featuresKey,
        howItWorksKey: _howItWorksKey,
        pricingKey: _pricingKey,
        securityKey: _securityKey,
        aboutKey: _aboutKey,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Clean minimal app bar ──
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.slate900.withValues(alpha: 0.92),
                border: Border(
                  bottom: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: kEmeraldGradient,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 17, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text('Pronote',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                  const Spacer(),
                  // Sign in — minimal text
                  TextButton(
                    onPressed: () => context.go('/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.slate300,
                      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Sign in'),
                  ),
                  const SizedBox(width: 4),
                  // Hamburger menu — Builder provides a context below the
                  // Scaffold so openEndDrawer() works.
                  Builder(
                    builder: (scaffoldCtx) => Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => Scaffold.of(scaffoldCtx).openEndDrawer(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x1AFFFFFF)),
                          ),
                          child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Scrollable body ──
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                child: Column(
                  children: [
                    const _HeroSection(),
                    const _StatsBar(),
                    KeyedSubtree(key: _featuresKey, child: const _FeaturesSection()),
                    KeyedSubtree(key: _howItWorksKey, child: const _HowItWorksSection()),
                    KeyedSubtree(key: _aboutKey, child: const _ForDifferentRolesSection()),
                    KeyedSubtree(key: _pricingKey, child: const _PricingSection()),
                    _FaqSection(
                      openIndex: _openFaq,
                      onToggle: (i) => setState(() => _openFaq = _openFaq == i ? -1 : i),
                    ),
                    KeyedSubtree(key: _securityKey, child: const _SecuritySection()),
                    const _FinalCta(),
                    const _Footer(),
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

// ─────────────────────────────────────────────────────────────────
// Premium slide-out drawer (replaces nav chip bar)
// ─────────────────────────────────────────────────────────────────
class _LandingDrawer extends StatelessWidget {
  final void Function(GlobalKey key) onNavigate;
  final GlobalKey featuresKey;
  final GlobalKey howItWorksKey;
  final GlobalKey pricingKey;
  final GlobalKey securityKey;
  final GlobalKey aboutKey;

  const _LandingDrawer({
    required this.onNavigate,
    required this.featuresKey,
    required this.howItWorksKey,
    required this.pricingKey,
    required this.securityKey,
    required this.aboutKey,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Features', Icons.auto_awesome_outlined, featuresKey),
      ('How It Works', Icons.checklist_rounded, howItWorksKey),
      ('Pricing', Icons.workspace_premium_outlined, pricingKey),
      ('Security', Icons.shield_outlined, securityKey),
      ('About', Icons.info_outline_rounded, aboutKey),
    ];

    return Drawer(
      width: 280,
      backgroundColor: AppColors.slate900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: kEmeraldGradient,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Pronote',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.slate400, size: 22),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0x14FFFFFF), height: 1),
            const SizedBox(height: 8),

            // Nav items
            ...items.map((item) => _DrawerItem(
                  icon: item.$2,
                  label: item.$1,
                  onTap: () => onNavigate(item.$3),
                )),

            const SizedBox(height: 8),
            const Divider(color: Color(0x14FFFFFF), height: 1),
            const Spacer(),

            // Bottom CTA buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0x33FFFFFF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Sign in'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: kEmeraldGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/signup');
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: const Center(
                        child: Text('Start free trial',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
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

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.slate400, size: 20),
                const SizedBox(width: 14),
                Text(label,
                    style: const TextStyle(color: AppColors.slate300, fontSize: 14.5, fontWeight: FontWeight.w600)),
              ],
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

void _showDemoDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.slate900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: kEmeraldGradient,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 18),
            const Text(
              '60-second product tour',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'See Pronote turn a real patient conversation into a finished SOAP note in under a minute.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate400, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/signup');
                },
                icon: const Icon(Icons.bolt),
                label: const Text('Skip the demo — start free trial'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ),
  );
}

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
              onPressed: () => _showDemoDialog(context),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Watch Demo'),
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
      // Copy ported verbatim from the web LandingPage.tsx (lines 433-445).
      ('01', 'Capture',
          'Click "Capture conversation" when your visit begins. Pronote listens for up to 1.5 hours, virtual or in-office visits.',
          Icons.mic, AppColors.emerald400),
      ('02', 'Review and Edit',
          'Click "End conversation" and view your personalised note in just a few seconds. With every visit, Pronote learns your style.',
          Icons.edit_note, AppColors.info),
      ('03', 'Send',
          'Easily send auto-generated patient instructions, and copy completed notes into any EHR system with one click.',
          Icons.send, const Color(0xFFA78BFA)),
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
// For Different Roles (web's id="about" lives here)
// ─────────────────────────────────────────────────────────────────

class _ForDifferentRolesSection extends StatelessWidget {
  const _ForDifferentRolesSection();

  static const _roles = [
    _Role(
      icon: Icons.people,
      gradient: [Color(0xFF34D399), Color(0xFF14B8A6)],
      title: 'For MDs',
      desc: 'Streamlined notes, clinical accuracy, and integration with your existing workflows.',
      badge: '50,000+ MDs',
    ),
    _Role(
      icon: Icons.description_outlined,
      gradient: [Color(0xFF60A5FA), Color(0xFF6366F1)],
      title: 'For RNs',
      desc: 'Document patient assessments and care plans in a fraction of the time.',
      badge: '20,000+ RNs',
    ),
    _Role(
      icon: Icons.mic,
      gradient: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
      title: 'For Therapists',
      desc: 'Capture session details while staying present with your clients.',
      badge: '15,000+ Therapists',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
      color: AppColors.slate900,
      child: Column(
        children: [
          const Text(
            'For every healthcare professional',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2),
          ),
          const SizedBox(height: 10),
          const Text(
            "Whether you're a physician, nurse, or therapist — Pronote adapts to your specialty.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate400, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          ..._roles.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RoleCard(role: r),
              )),
        ],
      ),
    );
  }
}

class _Role {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String desc;
  final String badge;
  const _Role({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.desc,
    required this.badge,
  });
}

class _RoleCard extends StatelessWidget {
  final _Role role;
  const _RoleCard({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: role.gradient),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: role.gradient.first.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(role.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emerald500.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              role.badge,
              style: const TextStyle(color: AppColors.emerald400, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            role.title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            role.desc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.slate400, fontSize: 13.5, height: 1.5),
          ),
        ],
      ),
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
    // FAQs ported verbatim from frontend/src/data/index.ts (lines 310-331)
    // so the landing FAQ in app and on the web stay synchronised.
    final faqs = [
      (
        'How does Pronote ensure data security and patient privacy?',
        'Pronote maintains HIPAA compliance through end-to-end encryption, secure data centers, automatic audio deletion after processing, and strict access controls. All data is encrypted both in transit and at rest using AES-256 encryption.',
      ),
      (
        'Can Pronote integrate with existing Electronic Health Record (EHR) systems?',
        'Yes, Pronote integrates with most major EHR systems including Epic, Cerner, Allscripts, and others through our secure API. Contact our enterprise team for custom integration support.',
      ),
      (
        'What kind of AI technology powers the note-taking features?',
        'Pronote uses advanced medical-grade speech recognition combined with large language models specifically trained on clinical documentation. Our AI understands medical terminology, context, and formatting requirements across specialties.',
      ),
      (
        'Is there a learning curve for new users to adopt Pronote?',
        'Pronote is designed to be intuitive and easy to use. Most clinicians are productive within minutes. We also provide onboarding support, video tutorials, and dedicated customer success managers for enterprise clients.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      color: AppColors.slate900,
      child: Column(
        children: [
          const _SectionBadge(label: 'FAQ', icon: Icons.help_outline),
          const SizedBox(height: 14),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.2),
              children: [
                TextSpan(text: 'Frequently asked\n'),
                TextSpan(text: 'questions', style: TextStyle(color: AppColors.emerald400)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Everything you need to know about Pronote.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate400, fontSize: 13.5),
          ),
          const SizedBox(height: 22),
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
          colors: [AppColors.slate900, AppColors.slate800, AppColors.slate900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // "Join 50,000+ clinicians" pill — matches web (line 855-857).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.emerald500.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: AppColors.emerald400, size: 13),
                SizedBox(width: 6),
                Text('Join 50,000+ clinicians',
                    style: TextStyle(color: AppColors.emerald400, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Reclaim your time.\nImprove patient care.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Join thousands of healthcare professionals who have transformed their documentation workflow with AI.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate400, fontSize: 14, height: 1.55),
          ),
          const SizedBox(height: 24),
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
                        Text('Start Your Free Trial',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => _showDemoDialog(context),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Watch Demo'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No credit card required • 7-day free trial • Cancel anytime',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate500, fontSize: 12),
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
    final year = DateTime.now().year;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.slate900,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand block (web's first column)
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: kEmeraldGradient,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.auto_awesome, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text('Pronote',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'AI-powered clinical documentation for modern healthcare.',
            style: TextStyle(color: AppColors.slate500, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 28),

          // Three columns: Product / Company / Legal — same as web (lines 897-901).
          _FooterColumn(title: 'Product', items: [
            _FooterItem('Features', () { /* in-page anchor */ }),
            _FooterItem('Pricing', () => context.go('/plans')),
            _FooterItem('Security', () { /* in-page anchor */ }),
            _FooterItem('Changelog', () => context.go('/help')),
          ]),
          const SizedBox(height: 22),
          _FooterColumn(title: 'Company', items: [
            _FooterItem('About', () { /* in-page anchor */ }),
            _FooterItem('Enterprise', () => context.go('/enterprise')),
            _FooterItem('Support', () => context.go('/help')),
            _FooterItem('Contact', () => context.go('/help')),
          ]),
          const SizedBox(height: 22),
          _FooterColumn(title: 'Legal', items: [
            _FooterItem('Privacy Policy', () => context.go('/privacy')),
            _FooterItem('Terms of Service', () => context.go('/terms')),
            _FooterItem('HIPAA BAA', () => context.go('/hipaa-baa')),
            _FooterItem('Delete Account', () => context.go('/delete-account')),
          ]),

          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 18),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
            ),
            child: Column(
              children: [
                Text(
                  '© $year Pronote. All rights reserved.',
                  style: const TextStyle(color: AppColors.slate500, fontSize: 12),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Made with ❤️ for healthcare professionals',
                  style: TextStyle(color: AppColors.slate500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterItem {
  final String label;
  final VoidCallback onTap;
  const _FooterItem(this.label, this.onTap);
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<_FooterItem> items;
  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 12),
        ...items.map((it) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: it.onTap,
                child: Text(
                  it.label,
                  style: const TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            )),
      ],
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
