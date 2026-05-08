class Plan {
  /// Stable identifier the backend uses to map to its Stripe price IDs.
  final String id;

  /// Display name on the card.
  final String name;

  /// Big price string ("$29.99", "$300", "$40", "$460").
  final String price;

  /// Suffix shown right after the price ("/month", "/year").
  final String period;

  /// Smaller secondary line (e.g. "$25.00/mo" on annual plans). Optional.
  final String? secondary;

  /// One-liner under the price.
  final String description;

  /// Bullet-point feature list.
  final List<String> features;

  /// Highlighted card (gradient + "MOST POPULAR" badge).
  final bool highlight;

  /// Optional banner badge at the very top (e.g. "MOST POPULAR").
  final String? badge;

  /// Whether this plan tier is a group/team plan (drives the "Team" sidebar entry).
  final bool isGroup;

  const Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    this.secondary,
    required this.description,
    required this.features,
    this.highlight = false,
    this.badge,
    this.isGroup = false,
  });
}

/// The four production plans — mirrors the web Pricing page exactly so a user
/// who upgrades on web sees the same plan name in the app and vice versa.
const kPlans = <Plan>[
  Plan(
    id: 'individual_monthly',
    name: 'PronoteAI Individual',
    price: '\$29.99',
    period: '/month',
    description: 'Perfect for solo practitioners, billed monthly',
    features: [
      'Unlimited clinical notes',
      'All note templates',
      'Audio recording & upload',
      'AI-powered transcription',
      'Basic EHR export',
      'Email support',
      'Unlimited audio retention',
      'HIPAA BAA included',
    ],
  ),
  Plan(
    id: 'individual_annual',
    name: 'PronoteAI Individual Annual',
    price: '\$300',
    period: '/year',
    secondary: '\$25.00/mo',
    description: 'Save \$60/yr vs monthly — best for individuals',
    features: [
      'Everything in Individual Monthly',
      'Save \$60 per year',
      'Priority email support',
      'Early access to new features',
      'Advanced analytics',
      'EHR export',
      'HIPAA BAA included',
    ],
    highlight: true,
    badge: 'MOST POPULAR',
  ),
  Plan(
    id: 'group_monthly',
    name: 'Pronote Group Monthly',
    price: '\$40',
    period: '/month',
    description: 'Best for small practices & teams',
    features: [
      'Everything in Individual',
      'Up to 5 team members',
      'Custom templates',
      'Priority support',
      'Advanced analytics',
      'EHR integrations',
      'Team management dashboard',
      'HIPAA BAA included',
    ],
    isGroup: true,
  ),
  Plan(
    id: 'group_annual',
    name: 'Pronote Group Annual',
    price: '\$460',
    period: '/year',
    secondary: '\$38.33/mo',
    description: 'Best value for growing organizations',
    features: [
      'Everything in Group Monthly',
      'Annual billing discount',
      'Unlimited team members',
      'Custom AI training',
      'Dedicated success manager',
      'HIPAA BAA included',
      'Custom integrations',
      'SLA guarantees',
    ],
    isGroup: true,
  ),
];
