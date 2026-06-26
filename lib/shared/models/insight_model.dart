enum InsightType {
  revenueUp,
  revenueDown,
  expenseHigh,
  expenseLow,
  profitAlert,
  cashFlowHealthy,
  cashFlowLow,
  loanReady,
  scoreImproved,
  documentsNeeded,
}

extension InsightTypeExt on InsightType {
  String get emoji {
    switch (this) {
      case InsightType.revenueUp:
        return '📈';
      case InsightType.revenueDown:
        return '📉';
      case InsightType.expenseHigh:
        return '⚠️';
      case InsightType.expenseLow:
        return '✅';
      case InsightType.profitAlert:
        return '🔴';
      case InsightType.cashFlowHealthy:
        return '💚';
      case InsightType.cashFlowLow:
        return '💧';
      case InsightType.loanReady:
        return '🏦';
      case InsightType.scoreImproved:
        return '⭐';
      case InsightType.documentsNeeded:
        return '📋';
    }
  }

  bool get isPositive {
    switch (this) {
      case InsightType.revenueUp:
      case InsightType.expenseLow:
      case InsightType.cashFlowHealthy:
      case InsightType.loanReady:
      case InsightType.scoreImproved:
        return true;
      default:
        return false;
    }
  }
}

class InsightModel {
  final String id;
  final InsightType type;
  final String title;
  final String message;
  final String actionText;
  final double? changePercent;
  final DateTime generatedAt;

  const InsightModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.actionText,
    this.changePercent,
    required this.generatedAt,
  });

  bool get isPositive => type.isPositive;
  String get emoji => type.emoji;

  static List<InsightModel> generateInsights({
    required double healthScore,
    required double loanScore,
    required double confidenceScore,
    required double revenueChangePercent,
    required double expenseChangePercent,
    required double profitMargin,
    required int verifiedDocCount,
    required int totalDocCount,
  }) {
    final insights = <InsightModel>[];
    final now = DateTime.now();

    // Revenue insight
    if (revenueChangePercent >= 5) {
      insights.add(InsightModel(
        id: 'ins_rev_up',
        type: InsightType.revenueUp,
        title: 'Revenue Increased',
        message:
            'Your revenue grew by ${revenueChangePercent.toStringAsFixed(1)}% this month compared to last month. Great work! Keep recording transactions to maintain this momentum.',
        actionText: 'View Details',
        changePercent: revenueChangePercent,
        generatedAt: now,
      ));
    } else if (revenueChangePercent < -5) {
      insights.add(InsightModel(
        id: 'ins_rev_down',
        type: InsightType.revenueDown,
        title: 'Revenue Decreased',
        message:
            'Revenue dipped by ${revenueChangePercent.abs().toStringAsFixed(1)}% this month. Consider if there are seasonal factors or new competition nearby.',
        actionText: 'Get Advice',
        changePercent: revenueChangePercent,
        generatedAt: now,
      ));
    }

    // Expense insight
    if (expenseChangePercent >= 15) {
      insights.add(InsightModel(
        id: 'ins_exp_high',
        type: InsightType.expenseHigh,
        title: 'Expenses Rising',
        message:
            'Your expenses increased by ${expenseChangePercent.toStringAsFixed(1)}% this month. Review your stock purchases and transport costs to see where you can save.',
        actionText: 'Review Expenses',
        changePercent: expenseChangePercent,
        generatedAt: now,
      ));
    }

    // Profit margin insight
    if (profitMargin < 0.2) {
      insights.add(InsightModel(
        id: 'ins_profit_low',
        type: InsightType.profitAlert,
        title: 'Profit Alert',
        message:
            'Your profit margin is ${(profitMargin * 100).toStringAsFixed(0)}%, which is lower than the recommended 30%. Consider reducing costs or increasing prices.',
        actionText: 'Improve Margins',
        generatedAt: now,
      ));
    } else {
      insights.add(InsightModel(
        id: 'ins_cashflow',
        type: InsightType.cashFlowHealthy,
        title: 'Cash Flow Healthy',
        message:
            'Your income consistently exceeds expenses with a ${(profitMargin * 100).toStringAsFixed(0)}% profit margin. This is excellent for your loan readiness!',
        actionText: 'View Passport',
        generatedAt: now,
      ));
    }

    // Loan readiness insight
    if (loanScore >= 70) {
      insights.add(InsightModel(
        id: 'ins_loan',
        type: InsightType.loanReady,
        title: 'Loan Ready!',
        message:
            'Your Loan Readiness Score is ${loanScore.round()}/100. You are eligible for PM Mudra Yojana. Visit your nearest bank with your Financial Passport!',
        actionText: 'View Schemes',
        generatedAt: now,
      ));
    }

    // Score insight
    if (healthScore >= 75) {
      insights.add(InsightModel(
        id: 'ins_score',
        type: InsightType.scoreImproved,
        title: 'Strong Business Score',
        message:
            'Your Business Health Score of ${healthScore.round()} is excellent! This reflects your consistent revenue and good financial management.',
        actionText: 'Generate Passport',
        generatedAt: now,
      ));
    }

    // Document insight
    if (verifiedDocCount < totalDocCount) {
      final pending = totalDocCount - verifiedDocCount;
      insights.add(InsightModel(
        id: 'ins_docs',
        type: InsightType.documentsNeeded,
        title: 'Upload $pending More Documents',
        message:
            'You have $verifiedDocCount of $totalDocCount documents verified. Uploading more documents improves your Confidence Score significantly.',
        actionText: 'Upload Documents',
        generatedAt: now,
      ));
    }

    return insights;
  }
}
