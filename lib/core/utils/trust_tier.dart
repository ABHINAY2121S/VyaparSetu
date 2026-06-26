import '../../shared/models/transaction_model.dart';
import '../../shared/models/document_model.dart';
import 'package:flutter/material.dart';

/// Trust Tier System — VyaparSetu
/// Judges a business's data trustworthiness in a single visual tier.
///
/// Tiers (highest to lowest):
///   Diamond ♦  — Most bank-imported data, fully verified docs, max confidence
///   Gold    🥇 — Majority bank-imported or OCR, most docs verified
///   Silver  🥈 — Some verified transactions, partial docs
///   Bronze  🥉 — Mostly manual entry, few/no docs
enum TrustTier { diamond, gold, silver, bronze }

extension TrustTierExt on TrustTier {
  String get label {
    switch (this) {
      case TrustTier.diamond:
        return 'Diamond';
      case TrustTier.gold:
        return 'Gold';
      case TrustTier.silver:
        return 'Silver';
      case TrustTier.bronze:
        return 'Bronze';
    }
  }

  String get emoji {
    switch (this) {
      case TrustTier.diamond:
        return '♦';
      case TrustTier.gold:
        return '🥇';
      case TrustTier.silver:
        return '🥈';
      case TrustTier.bronze:
        return '🥉';
    }
  }

  /// Primary color for the tier badge
  Color get color {
    switch (this) {
      case TrustTier.diamond:
        return const Color(0xFF7C3AED); // violet
      case TrustTier.gold:
        return const Color(0xFFD97706); // amber
      case TrustTier.silver:
        return const Color(0xFF6B7280); // cool gray
      case TrustTier.bronze:
        return const Color(0xFF92400E); // brown
    }
  }

  /// Light background color for the badge
  Color get backgroundColor {
    switch (this) {
      case TrustTier.diamond:
        return const Color(0xFFF5F3FF);
      case TrustTier.gold:
        return const Color(0xFFFFFBEB);
      case TrustTier.silver:
        return const Color(0xFFF3F4F6);
      case TrustTier.bronze:
        return const Color(0xFFFEF3C7);
    }
  }

  /// Gradient colors for the large banner
  List<Color> get gradientColors {
    switch (this) {
      case TrustTier.diamond:
        return [const Color(0xFF5B21B6), const Color(0xFF7C3AED), const Color(0xFF8B5CF6)];
      case TrustTier.gold:
        return [const Color(0xFF92400E), const Color(0xFFD97706), const Color(0xFFFBBF24)];
      case TrustTier.silver:
        return [const Color(0xFF374151), const Color(0xFF6B7280), const Color(0xFF9CA3AF)];
      case TrustTier.bronze:
        return [const Color(0xFF78350F), const Color(0xFF92400E), const Color(0xFFB45309)];
    }
  }

  String get tagline {
    switch (this) {
      case TrustTier.diamond:
        return 'Highest Trust — Bank-verified data';
      case TrustTier.gold:
        return 'High Trust — Mostly verified data';
      case TrustTier.silver:
        return 'Moderate Trust — Partially verified';
      case TrustTier.bronze:
        return 'Basic Trust — Import bank statement to level up';
    }
  }
}

/// Computes TrustTier from transaction and document data.
class TrustTierCalculator {
  TrustTierCalculator._();

  /// Scores are 0–100 and map to tiers as follows:
  ///   80–100 → Diamond
  ///   60–79  → Gold
  ///   35–59  → Silver
  ///   0–34   → Bronze
  static TrustTier calculate({
    required List<TransactionModel> transactions,
    required List<DocumentModel> documents,
    required double confidenceScore,
  }) {
    final score = computeScore(
      transactions: transactions,
      documents: documents,
      confidenceScore: confidenceScore,
    );
    return fromScore(score);
  }

  static TrustTier fromScore(double score) {
    if (score >= 80) return TrustTier.diamond;
    if (score >= 60) return TrustTier.gold;
    if (score >= 35) return TrustTier.silver;
    return TrustTier.bronze;
  }

  /// Compute a 0–100 trust score broken down as:
  ///   40 pts — Bank-imported transaction ratio (highest weight)
  ///   25 pts — Other verified transaction ratio (OCR, UPI)
  ///   25 pts — Verified document ratio
  ///   10 pts — Confidence score pass-through
  static double computeScore({
    required List<TransactionModel> transactions,
    required List<DocumentModel> documents,
    required double confidenceScore,
  }) {
    double score = 0;

    if (transactions.isNotEmpty) {
      // 40 pts: bank-imported ratio
      final bankImported =
          transactions.where((t) => t.verificationBadge == VerificationBadge.bankImported).length;
      final bankRatio = bankImported / transactions.length;
      score += bankRatio * 40;

      // 25 pts: other verified (OCR/UPI/bankVerified)
      final otherVerified = transactions.where((t) =>
          t.verificationBadge == VerificationBadge.ocrVerified ||
          t.verificationBadge == VerificationBadge.upiVerified ||
          t.verificationBadge == VerificationBadge.bankVerified).length;
      final otherRatio = otherVerified / transactions.length;
      score += otherRatio * 25;
    }

    if (documents.isNotEmpty) {
      // 25 pts: document verification ratio
      final verifiedDocs =
          documents.where((d) => d.status == DocumentStatus.verified).length;
      final docRatio = verifiedDocs / documents.length;
      score += docRatio * 25;
    } else {
      // No documents at all → partial credit so bronze is reachable
      score += 5;
    }

    // 10 pts: confidence score contribution
    score += (confidenceScore / 100) * 10;

    return score.clamp(0, 100);
  }

  /// Human-readable breakdown for the "how to improve" section.
  static List<Map<String, dynamic>> getBreakdown({
    required List<TransactionModel> transactions,
    required List<DocumentModel> documents,
    required double confidenceScore,
  }) {
    final bankImported = transactions
        .where((t) => t.verificationBadge == VerificationBadge.bankImported)
        .length;
    final otherVerified = transactions
        .where((t) =>
            t.verificationBadge == VerificationBadge.ocrVerified ||
            t.verificationBadge == VerificationBadge.upiVerified ||
            t.verificationBadge == VerificationBadge.bankVerified)
        .length;
    final verifiedDocs =
        documents.where((d) => d.status == DocumentStatus.verified).length;

    final bankRatio = transactions.isNotEmpty ? bankImported / transactions.length : 0.0;
    final docRatio = documents.isNotEmpty ? verifiedDocs / documents.length : 0.0;

    return [
      {
        'label': 'Bank-Imported Transactions',
        'points': (bankRatio * 40).round(),
        'maxPoints': 40,
        'value': '$bankImported/${transactions.length}',
        'positive': bankImported > 0,
        'tip': bankImported == 0
            ? 'Import your bank statement to jump to Gold or Diamond tier!'
            : null,
      },
      {
        'label': 'OCR / UPI Verified',
        'points': (otherVerified / (transactions.isNotEmpty ? transactions.length : 1) * 25).round(),
        'maxPoints': 25,
        'value': '$otherVerified/${transactions.length}',
        'positive': otherVerified > 0,
        'tip': otherVerified == 0 ? 'Scan receipts or add UPI transactions.' : null,
      },
      {
        'label': 'Verified Documents',
        'points': (docRatio * 25).round(),
        'maxPoints': 25,
        'value': '$verifiedDocs/${documents.length}',
        'positive': verifiedDocs > 0,
        'tip': verifiedDocs < documents.length ? 'Upload remaining documents.' : null,
      },
      {
        'label': 'Confidence Score',
        'points': (confidenceScore / 100 * 10).round(),
        'maxPoints': 10,
        'value': '${confidenceScore.round()}/100',
        'positive': confidenceScore >= 50,
        'tip': null,
      },
    ];
  }
}
