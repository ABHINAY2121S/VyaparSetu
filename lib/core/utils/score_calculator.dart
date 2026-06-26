import '../../shared/models/transaction_model.dart';
import '../../shared/models/document_model.dart';

class ScoreCalculator {
  ScoreCalculator._();

  /// Calculate Business Health Score (0-100)
  /// Based on: revenue consistency, profitability, and growth trend
  static double calculateBusinessHealthScore(
    List<TransactionModel> transactions,
  ) {
    if (transactions.isEmpty) return 0;

    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (income.isEmpty) return 0;

    double score = 0;

    // 1. Revenue Consistency Score (0-30 points)
    final monthlyRevenues = _getMonthlyTotals(income);
    if (monthlyRevenues.length >= 2) {
      final consistencyScore = _calculateConsistency(monthlyRevenues);
      score += consistencyScore * 30;
    }
    // No partial points for single-month data — must prove consistency

    // 2. Profitability Score (0-40 points)
    final totalIncome = income.fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = expenses.fold<double>(0, (sum, t) => sum + t.amount);
    if (totalIncome > 0) {
      final profitMargin = (totalIncome - totalExpense) / totalIncome;
      final profitScore = (profitMargin.clamp(0.0, 1.0));
      score += profitScore * 40;
    }

    // 3. Growth Trend Score (0-30 points)
    final growthScore = _calculateGrowthScore(monthlyRevenues);
    score += growthScore * 30;

    return score.clamp(0, 100);
  }

  /// Calculate Loan Readiness Score (0-100)
  /// Based on: repayment ability, cash flow stability, risk
  static double calculateLoanReadinessScore(
    List<TransactionModel> transactions,
  ) {
    if (transactions.isEmpty) return 0;

    double score = 0;

    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (income.isEmpty) return 0;

    final totalIncome = income.fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = expenses.fold<double>(0, (sum, t) => sum + t.amount);

    // 1. Average Monthly Income Score (0-30 points)
    final monthCount = _getMonthlyTotals(income).length.toDouble();
    final avgMonthlyIncome = totalIncome / (monthCount > 0 ? monthCount : 1);
    if (avgMonthlyIncome >= 50000) {
      score += 30;
    } else if (avgMonthlyIncome >= 25000) {
      score += 22;
    } else if (avgMonthlyIncome >= 10000) {
      score += 15;
    } else {
      score += 8;
    }

    // 2. Cash Flow Stability (0-25 points)
    final monthlyRevenues = _getMonthlyTotals(income);
    if (monthlyRevenues.length >= 3) {
      final stability = _calculateConsistency(monthlyRevenues);
      score += stability * 25;
    }
    // No partial points — stability must be proven over 3+ months

    // 3. Expense to Income Ratio (0-25 points)
    if (totalIncome > 0) {
      final ratio = totalExpense / totalIncome;
      if (ratio <= 0.4) {
        score += 25;
      } else if (ratio <= 0.6) {
        score += 18;
      } else if (ratio <= 0.8) {
        score += 10;
      } else {
        score += 3;
      }
    }

    // 4. Transaction Frequency Score (0-20 points)
    final txPerMonth = transactions.length / (monthCount > 0 ? monthCount : 1);
    if (txPerMonth >= 20) {
      score += 20;
    } else if (txPerMonth >= 10) {
      score += 15;
    } else if (txPerMonth >= 5) {
      score += 8;
    } else if (txPerMonth >= 1) {
      score += 3;
    }
    // 0 points for zero transactions

    return score.clamp(0, 100);
  }

  /// Calculate Confidence Score (0-100)
  /// Based on: verified documents, verified transactions, profile completeness
  static double calculateConfidenceScore(
    List<TransactionModel> transactions,
    List<DocumentModel> documents,
    bool profileComplete,
  ) {
    double score = 0;

    // 1. Verified Documents (0-40 points)
    if (documents.isNotEmpty) {
      final verifiedDocs =
          documents.where((d) => d.status == DocumentStatus.verified).length;
      final docScore = verifiedDocs / documents.length;
      score += docScore * 40;
    }

    // 2. Verified Transactions (0-40 points)
    if (transactions.isNotEmpty) {
      final verifiedTx = transactions
          .where(
            (t) =>
                t.verificationBadge == VerificationBadge.bankImported ||
                t.verificationBadge == VerificationBadge.bankVerified ||
                t.verificationBadge == VerificationBadge.upiVerified ||
                t.verificationBadge == VerificationBadge.ocrVerified,
          )
          .length;
      final txScore = verifiedTx / transactions.length;
      score += txScore * 40;
    }

    // 3. Profile Completeness (0-20 points)
    // Only awarded once the user has at least 1 verified document AND
    // at least 5 transactions — prevents gaming the score by just registering.
    final hasVerifiedDoc = documents.any((d) => d.status == DocumentStatus.verified);
    final hasTxHistory = transactions.length >= 5;
    if (profileComplete && hasVerifiedDoc && hasTxHistory) {
      score += 20;
    } else if (profileComplete && hasVerifiedDoc) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  /// Get recommended loan range based on scores and income
  static Map<String, dynamic> getRecommendedLoan(
    List<TransactionModel> transactions,
    double loanReadinessScore,
  ) {
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    if (income.isEmpty) {
      return {
        'min': 10000,
        'max': 25000,
        'label': '₹10,000 – ₹25,000',
      };
    }

    final totalIncome = income.fold<double>(0, (sum, t) => sum + t.amount);
    final monthCount = _getMonthlyTotals(income).length;
    final avgMonthlyIncome = totalIncome / (monthCount > 0 ? monthCount : 1);

    // Loan multiplier based on readiness score
    double multiplier;
    if (loanReadinessScore >= 80) {
      multiplier = 3.0;
    } else if (loanReadinessScore >= 60) {
      multiplier = 2.0;
    } else if (loanReadinessScore >= 40) {
      multiplier = 1.5;
    } else {
      multiplier = 1.0;
    }

    final maxLoan = (avgMonthlyIncome * multiplier).round();
    final minLoan = (maxLoan * 0.6).round();

    return {
      'min': minLoan,
      'max': maxLoan,
      'label':
          '₹${_formatLoanAmount(minLoan)} – ₹${_formatLoanAmount(maxLoan)}',
    };
  }

  /// Get risk level string based on scores
  static String getRiskLevel(
    double healthScore,
    double loanScore,
    double confidenceScore,
  ) {
    final avgScore = (healthScore + loanScore + confidenceScore) / 3;
    if (avgScore >= 70) return 'Low';
    if (avgScore >= 45) return 'Medium';
    return 'High';
  }

  /// Get score breakdown for explainable AI
  static List<Map<String, dynamic>> getScoreBreakdown(
    List<TransactionModel> transactions,
    List<DocumentModel> documents,
  ) {
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    final totalIncome = income.fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final verifiedDocs =
        documents.where((d) => d.status == DocumentStatus.verified).length;
    final profitMargin =
        totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) : 0.0;

    final breakdown = <Map<String, dynamic>>[
      {
        'label': 'Income Stability',
        'points': '+${(profitMargin * 25).round()}',
        'positive': true,
        'description': 'Based on regular monthly income',
      },
      {
        'label': 'Profitability',
        'points': '+${(profitMargin * 20).round()}',
        'positive': true,
        'description': 'Profit margin analysis',
      },
      {
        'label': 'Verified Documents',
        'points': '+${verifiedDocs * 8}',
        'positive': true,
        'description': '$verifiedDocs of ${documents.length} documents verified',
      },
      {
        'label': 'Transaction History',
        'points': '+${(transactions.length * 0.5).round().clamp(0, 20)}',
        'positive': true,
        'description': '${transactions.length} transactions recorded',
      },
    ];

    if (profitMargin < 0.2) {
      breakdown.add({
        'label': 'Low Profit Margin',
        'points': '-5',
        'positive': false,
        'description': 'Expenses are high relative to income',
      });
    }

    return breakdown;
  }

  // ── Private Helpers ──────────────────────────────────────────────────────

  static Map<String, double> _getMonthlyTotals(List<TransactionModel> txs) {
    final map = <String, double>{};
    for (final tx in txs) {
      final key =
          '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + tx.amount;
    }
    return map;
  }

  static double _calculateConsistency(Map<String, double> monthlyData) {
    if (monthlyData.length < 2) return 0.5;
    final values = monthlyData.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean == 0) return 0;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
        values.length;
    final stdDev = variance > 0 ? variance : 0.0;
    final cv = stdDev / mean;
    return (1 - cv.clamp(0.0, 1.0));
  }

  static double _calculateGrowthScore(Map<String, double> monthlyData) {
    if (monthlyData.length < 2) return 0.5;
    final values = monthlyData.values.toList();
    double growthCount = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] >= values[i - 1]) growthCount++;
    }
    return growthCount / (values.length - 1);
  }

  static String _formatLoanAmount(int amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).round()}K';
    }
    return amount.toString();
  }
}
