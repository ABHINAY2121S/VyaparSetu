import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/trust_tier.dart';

/// Sizes for TrustTierBadge
enum TrustBadgeSize { small, medium, large }

/// A reusable badge that shows the current Trust Tier.
///
/// Usage:
///   TrustTierBadgeWidget(tier: provider.trustTier)
///   TrustTierBadgeWidget(tier: provider.trustTier, size: TrustBadgeSize.large, showTagline: true)
class TrustTierBadgeWidget extends StatelessWidget {
  final TrustTier tier;
  final TrustBadgeSize size;
  final bool showTagline;
  final bool animated;

  const TrustTierBadgeWidget({
    super.key,
    required this.tier,
    this.size = TrustBadgeSize.medium,
    this.showTagline = false,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    switch (size) {
      case TrustBadgeSize.small:
        return _SmallBadge(tier: tier);
      case TrustBadgeSize.medium:
        return _MediumBadge(tier: tier, showTagline: showTagline);
      case TrustBadgeSize.large:
        return _LargeBadge(tier: tier);
    }
  }
}

// ── Small: inline chip (e.g. transaction list row) ─────────────────────────
class _SmallBadge extends StatelessWidget {
  final TrustTier tier;
  const _SmallBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tier.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tier.color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(tier.emoji, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 3),
        Text(
          tier.label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: tier.color,
          ),
        ),
      ]),
    );
  }
}

// ── Medium: card-level badge with optional tagline ─────────────────────────
class _MediumBadge extends StatelessWidget {
  final TrustTier tier;
  final bool showTagline;
  const _MediumBadge({required this.tier, required this.showTagline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: tier.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tier.color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: tier.color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(tier.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              '${tier.label} Trust',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: tier.color,
              ),
            ),
          ]),
          if (showTagline) ...[
            const SizedBox(height: 4),
            Text(
              tier.tagline,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: tier.color.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Large: full gradient banner (passport / dedicated trust section) ────────
class _LargeBadge extends StatelessWidget {
  final TrustTier tier;
  const _LargeBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tier.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tier.color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(children: [
        Text(
          tier.emoji,
          style: const TextStyle(fontSize: 40),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${tier.label} Trust Level',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tier.tagline,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Tier Progress Bar ────────────────────────────────────────────────────────
/// Shows all 4 tiers as steps with the current one highlighted.
class TrustTierProgressBar extends StatelessWidget {
  final TrustTier currentTier;
  final double trustScore;

  const TrustTierProgressBar({
    super.key,
    required this.currentTier,
    required this.trustScore,
  });

  @override
  Widget build(BuildContext context) {
    final tiers = [TrustTier.bronze, TrustTier.silver, TrustTier.gold, TrustTier.diamond];
    final currentIndex = tiers.indexOf(currentTier);

    return Column(children: [
      // Progress bar
      Row(children: [
        for (int i = 0; i < tiers.length; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 6,
              decoration: BoxDecoration(
                color: i <= currentIndex
                    ? currentTier.color
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (i < tiers.length - 1) const SizedBox(width: 4),
        ],
      ]),
      const SizedBox(height: 8),
      // Labels
      Row(children: [
        for (int i = 0; i < tiers.length; i++)
          Expanded(
            child: Column(children: [
              Text(
                tiers[i].emoji,
                style: TextStyle(
                  fontSize: i == currentIndex ? 16 : 12,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                tiers[i].label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w400,
                  color: i <= currentIndex ? currentTier.color : Colors.grey.shade400,
                ),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
      ]),
    ]);
  }
}
