import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/trust_tier.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/document_upload_sheet.dart';
import '../../../shared/widgets/score_ring_widget.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/account_sync_sheet.dart';
import '../../../shared/widgets/trust_tier_badge_widget.dart';
import '../../../shared/widgets/verification_badge_widget.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/models/insight_model.dart';
import '../providers/dashboard_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../../core/l10n/app_localizations.dart';
import 'all_insights_screen.dart';
import '../../home/home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final onboarding = context.watch<OnboardingProvider>();
    final l10n = L10n.of(onboarding.selectedLanguage);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.load(),
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(provider, l10n),
                  SliverPadding(
                    padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildFinancialSummary(provider, l10n),
                        const SizedBox(height: 16),
                        _buildTrustTierSection(provider, l10n),
                        const SizedBox(height: 16),
                        _buildScoreSection(provider, l10n),
                        const SizedBox(height: 16),
                        _buildRevenueChart(provider, l10n),
                        const SizedBox(height: 16),
                        _buildInsightsSection(provider, l10n),
                        const SizedBox(height: 16),
                        _buildRecentTransactions(provider, l10n),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar(DashboardProvider provider, L10n l10n) {
    final user = provider.user;
    final business = provider.business;

    final hour = DateTime.now().hour;
    String greeting = l10n.pick('Good Evening', 'शुभ संध्या', 'शुभ संध्याकाळ');
    if (hour < 12) {
      greeting = l10n.pick('Good Morning', 'शुभ प्रभात', 'शुभ सकाळ');
    } else if (hour < 17) {
      greeting = l10n.pick('Good Afternoon', 'शुभ दोपहर', 'शुभ दुपार');
    }

    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      snap: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF047857), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingXXL,
                vertical: AppDimensions.paddingMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onLongPress: () => _triggerDemoMode(context, provider, l10n),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting, 👋',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.name ?? l10n.pick('Welcome', 'स्वागत है', 'स्वागत आहे'),
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              business?.businessName ?? l10n.pick('Your Business', 'आपका व्यापार', 'तुमचा व्यवसाय'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (_) => const AccountSyncSheet(),
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.sync,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showNotificationsDialog(context, l10n),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(DashboardProvider provider, L10n l10n) {
    final revenue = provider.totalRevenue;

    // Revenue-based gradient: red → orange/amber → blue → green → purple
    final Gradient revenueGradient;
    final Color accentColor;
    if (revenue <= 0) {
      revenueGradient = const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFB91C1C)], // Vibrant Red
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      );
      accentColor = const Color(0xFFFECACA);
    } else if (revenue < 10000) {
      revenueGradient = const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)], // Vibrant Orange/Amber
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      );
      accentColor = const Color(0xFFFEF3C7);
    } else if (revenue < 30000) {
      revenueGradient = const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Vibrant Blue
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      );
      accentColor = const Color(0xFFDBEAFE);
    } else if (revenue < 75000) {
      revenueGradient = const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF047857)], // Vibrant Green
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      );
      accentColor = const Color(0xFFD1FAE5);
    } else {
      revenueGradient = const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)], // Vibrant Purple
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      );
      accentColor = const Color(0xFFEDE9FE);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: revenueGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.pick('This Month', 'इस महीने', 'या महिन्यात'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppFormatters.formatMonthYear(DateTime.now()),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppFormatters.formatCompact(revenue),
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          Text(
            l10n.pick('Total Revenue', 'कुल आय', 'एकूण उत्पन्न'),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  l10n.pick('Net Profit', 'शुद्ध लाभ', 'निव्वळ नफा'),
                  AppFormatters.formatCompact(provider.netProfit),
                  accentColor,
                  Icons.trending_up_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.15)),
              Expanded(
                child: _buildMiniStat(
                  l10n.pick('Total Expenses', 'कुल खर्च', 'एकूण खर्च'),
                  AppFormatters.formatCompact(provider.totalExpenses),
                  const Color(0xFFFC8181),
                  Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildMiniStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustTierSection(DashboardProvider provider, L10n l10n) {
    final tier = provider.trustTier;
    final score = provider.trustScore;
    final breakdown = TrustTierCalculator.getBreakdown(
      transactions: provider.transactions,
      documents: provider.documents,
      confidenceScore: provider.confidenceScore,
    );
    final tip = breakdown.firstWhere(
      (b) => b['tip'] != null,
      orElse: () => <String, dynamic>{},
    )['tip'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.pick('Trust Tier', 'विश्वास टियर', 'विश्वास स्तर')),
        const SizedBox(height: 12),
        // Large gradient banner
        TrustTierBadgeWidget(tier: tier, size: TrustBadgeSize.large),
        const SizedBox(height: 12),
        AppCard(
          child: Column(children: [
            // Progress bar
            TrustTierProgressBar(currentTier: tier, trustScore: score),
            const SizedBox(height: 16),
            // Score row
            Row(
              children: [
                _buildTrustStat(
                  l10n.pick('Trust Score', 'विश्वास स्कोर', 'विश्वास स्कोअर'),
                  '${score.round()}/100',
                  tier.color,
                ),
                Container(width: 1, height: 32, color: AppColors.border),
                _buildTrustStat(
                  l10n.pick('Bank Imported', 'बैंक आयातित', 'बँक आयातित'),
                  provider.transactions.isNotEmpty
                      ? '${provider.transactions.where((t) => t.verificationBadge == VerificationBadge.bankImported).length}/${provider.transactions.length}'
                      : '0/0',
                  const Color(0xFFD97706),
                ),
                Container(width: 1, height: 32, color: AppColors.border),
                _buildTrustStat(
                  l10n.pick('Next Tier', 'अगला स्तर', 'पुढील स्तर'),
                  tier == TrustTier.diamond
                      ? l10n.pick('Max!', 'सर्वोच्च!', 'कमाल!')
                      : _nextTierName(tier),
                  AppColors.textSecondary,
                ),
              ],
            ),
            // Tip to level up
            if (tip != null && tier != TrustTier.diamond) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tier.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tier.color.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.tips_and_updates_rounded, size: 14, color: tier.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: tier.color,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ]),
        ),
      ],
    );
  }

  Widget _buildTrustStat(String label, String value, Color color) {
    return Expanded(
      child: Column(children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  String _nextTierName(TrustTier current) {
    switch (current) {
      case TrustTier.bronze: return '🥈 Silver';
      case TrustTier.silver: return '🥇 Gold';
      case TrustTier.gold:   return '♦ Diamond';
      case TrustTier.diamond: return 'Max!';
    }
  }

  Widget _buildScoreSection(DashboardProvider provider, L10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.pick('Your Scores', 'आपके स्कोर', 'तुमचे स्कोअर')),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildScoreCard(
                label: l10n.pick('Business\nHealth', 'व्यापार\nस्वास्थ्य', 'व्यवसाय\nआरोग्य'),
                score: provider.businessHealthScore,
                color: AppColors.primary,
                icon: Icons.favorite_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildScoreCard(
                label: l10n.pick('Loan\nReadiness', 'ऋण\nतैयारी', 'कर्ज\nतयारी'),
                score: provider.loanReadinessScore,
                color: AppColors.secondary,
                icon: Icons.account_balance_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const DocumentUploadSheet(),
                ),
                child: _buildScoreCard(
                  label: l10n.pick('Confidence\nScore', 'विश्वास\nस्कोर', 'आत्मविश्वास\nस्कोअर'),
                  score: provider.confidenceScore,
                  color: const Color(0xFF7C3AED),
                  icon: Icons.verified_rounded,
                  tappable: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreCard({
    required String label,
    required double score,
    required Color color,
    required IconData icon,
    bool tappable = false,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: AppDimensions.paddingLG,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              ScoreRingWidget(
                score: score,
                label: label,
                color: color,
                size: 80,
                strokeWidth: 7,
                sublabel: '/100',
              ),
              if (tappable)
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 12,
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label.replaceAll('\n', ' '),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          if (tappable) ...
            [
              const SizedBox(height: 3),
              Text(
                'Tap to upload',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildRevenueChart(DashboardProvider provider, L10n l10n) {
    final data = provider.monthlyChartData;
    if (data.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.pick('Revenue vs Expenses', 'आय बनाम खर्च', 'उत्पन्न वि खर्च'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  _buildLegend(l10n.pick('Income', 'आय', 'उत्पन्न'), AppColors.chartIncome),
                  const SizedBox(width: 10),
                  _buildLegend(l10n.pick('Expense', 'खर्च', 'खर्च'), AppColors.chartExpense),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: AppDimensions.chartHeight,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: data
                    .map(
                      (d) => [d['income'] ?? 0, d['expense'] ?? 0].fold<double>(
                        0,
                        (a, b) => a > b ? a : b,
                      ),
                    )
                    .fold<double>(0, (a, b) => a > b ? a : b) *
                    1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        AppFormatters.formatCompact(rod.toY),
                        GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final intVal = value.toInt();
                        if (value != intVal.toDouble() || intVal < 0 || intVal > 5) {
                          return const SizedBox.shrink();
                        }
                        final months = [
                          '',
                          l10n.pick('Jan', 'जन', 'जाने'),
                          l10n.pick('Feb', 'फर', 'फेब्रु'),
                          l10n.pick('Mar', 'मार्च', 'मार्च'),
                          l10n.pick('Apr', 'अप्रैल', 'एप्रिल'),
                          l10n.pick('May', 'मई', 'मे'),
                          l10n.pick('Jun', 'जून', 'जून'),
                          l10n.pick('Jul', 'जुलाई', 'जुलै'),
                          l10n.pick('Aug', 'अगस्त', 'ऑगस्ट'),
                          l10n.pick('Sep', 'सितंबर', 'सप्टेंबर'),
                          l10n.pick('Oct', 'अक्टूबर', 'ऑक्टोबर'),
                          l10n.pick('Nov', 'नवंबर', 'नोव्हेंबर'),
                          l10n.pick('Dec', 'दिसंबर', 'डिसेंबर'),
                        ];
                        final now = DateTime.now();
                        final monthDate = DateTime(now.year, now.month - (5 - intVal), 1);
                        final actualMonth = monthDate.month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            months[actualMonth],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        );
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          AppFormatters.formatCompact(value),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppColors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  final i = entry.key;
                  final d = entry.value;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: d['income'] ?? 0,
                        color: AppColors.chartIncome,
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: d['expense'] ?? 0,
                        color: AppColors.chartExpense.withValues(alpha: 0.8),
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(DashboardProvider provider, L10n l10n) {
    final insights = provider.insights.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.pick('AI Insights', 'एआई इनसाइट्स', 'AI इनसाइट्स'),
          actionLabel: insights.isNotEmpty ? l10n.pick('View All', 'सभी देखें', 'सर्व पहा') : null,
          onActionTap: insights.isNotEmpty
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AllInsightsScreen(
                        insights: provider.insights,
                      ),
                    ),
                  )
              : null,
        ),
        const SizedBox(height: 12),
        if (insights.isEmpty) ...[
          _buildShimmerInsightCard(),
          const SizedBox(height: 8),
          _buildShimmerInsightCard(),
        ] else ...[
          ...insights.map((insight) => _buildInsightCard(insight)),
        ],
      ],
    );
  }

  Widget _buildShimmerInsightCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 180,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(InsightModel insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: insight.isPositive
            ? AppColors.primarySurface
            : AppColors.warningSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: insight.isPositive
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Text(insight.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(DashboardProvider provider, L10n l10n) {
    final txs = provider.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.pick('Recent Transactions', 'हाल के लेनदेन', 'अलीकडील व्यवहार'),
          actionLabel: l10n.pick('View All', 'सभी देखें', 'सर्व पहा'),
          onActionTap: () {
            context.findAncestorStateOfType<HomeScreenState>()?.setTab(1);
          },
        ),
        const SizedBox(height: 12),
        if (txs.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.pick('No transactions yet. Add your first transaction!', 'अभी तक कोई लेनदेन नहीं। अपना पहला लेनदेन जोड़ें!', 'अद्याप कोणतेही व्यवहार नाहीत. तुमचा पहिला व्यवहार जोडा!'),
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: txs.asMap().entries.map((entry) {
                final i = entry.key;
                final tx = entry.value;
                return Column(
                  children: [
                    _buildTransactionTile(tx),
                    if (i < txs.length - 1)
                      const Divider(height: 1, indent: 60),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
    final isIncome = tx.type == TransactionType.income;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLG,
        vertical: AppDimensions.paddingMD,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.primarySurface
                  : AppColors.errorSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isIncome ? AppColors.primary : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      AppFormatters.getRelativeTime(tx.date),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    VerificationBadgeWidget(
                      badge: tx.verificationBadge,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${AppFormatters.formatCurrency(tx.amount)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isIncome ? AppColors.primary : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _triggerDemoMode(BuildContext context, DashboardProvider provider, L10n l10n) {
    final isActive = provider.isDemoModeActive;

    if (isActive) {
      // ── Disable Dialog ──
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.toggle_off_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.pick('Disable Demo Mode', 'डेमो मोड बंद करें', 'डेमो मोड बंद करा'),
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),
          content: Text(
            l10n.pick(
              'This will remove the demo transactions and documents, restoring the seed data view.',
              'यह डेमो लेनदेन और दस्तावेज़ हटा देगा और डेटा रीसेट करेगा।',
              'हे डेमो व्यवहार आणि दस्तऐवज काढेल आणि डेटा रीसेट करेल.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.pick('Cancel', 'रद्द करें', 'रद्द करा')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await provider.disableDemoMode();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.pick(
                          'Demo Mode disabled. Seed data restored.',
                          'डेमो मोड बंद हुआ। सीड डेटा पुनर्स्थापित किया गया।',
                          'डेमो मोड बंद झाला. सीड डेटा पुनर्संचयित केला.',
                        ),
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: Text(l10n.pick('Disable', 'बंद करें', 'बंद करा')),
            ),
          ],
        ),
      );
    } else {
      // ── Enable Dialog ──
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.pick('Enable Judge Demo Mode?', 'जज डेमो मोड सक्षम करें?', 'जज डेमो मोड सक्षम करायचा?'),
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),
          content: Text(
            l10n.pick(
              'This will load realistic transactions and verified documents to showcase Gold/Diamond trust tier.',
              'यह गोल्ड/डायमंड ट्रस्ट स्तर को प्रदर्शित करने के लिए वास्तविक लेनदेन और दस्तावेज़ लोड करेगा।',
              'हे गोल्ड/डायमंड ट्रस्ट पातळी दाखवण्यासाठी वास्तववादी व्यवहार आणि दस्तऐवज लोड करेल.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.pick('Cancel', 'रद्द करें', 'रद्द करा')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await provider.enableDemoMode();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.pick(
                          '✅ Demo Mode enabled! Ramesh Vegetable Store loaded.',
                          '✅ डेमो मोड सक्षम! रमेश वेजिटेबल स्टोर लोड हुआ।',
                          '✅ डेमो मोड सक्षम! रमेश व्हेजिटेबल स्टोअर लोड झाले.',
                        ),
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              child: Text(l10n.pick('Enable', 'सक्षम करें', 'सक्षम करा')),
            ),
          ],
        ),
      );
    }
  }

  void _showNotificationsDialog(BuildContext context, L10n l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.pick('Notifications', 'अधिसूचनाएं', 'सूचना'),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                title: l10n.pick('Level Up Trust Tier', 'ट्रस्ट टियर बढ़ाएं', 'ट्रस्ट टियर सुधारा'),
                message: l10n.pick(
                  'Import your bank statement to unlock Gold Trust Level and get higher credit eligibility.',
                  'उच्च क्रेडिट पात्रता प्राप्त करने के लिए गोल्ड ट्रस्ट स्तर को अनलॉक करने हेतु अपना बैंक विवरण आयात करें।',
                  'उच्च क्रेडिट पात्रता मिळवण्यासाठी गोल्ड ट्रस्ट पातळी अनलॉक करण्यासाठी तुमचे बँक स्टेटमेंट आयात करा.'
                ),
                time: l10n.pick('Just now', 'अभी-अभी', 'आत्ताच'),
                icon: Icons.auto_awesome_rounded,
                iconColor: Colors.amber,
              ),
              const SizedBox(height: 8),
              _buildNotificationItem(
                title: l10n.pick('New Scheme Matched', 'नया योजना मैच हुआ', 'नवीन योजना मॅच झाली'),
                message: l10n.pick(
                  'Your business is eligible for Prime Minister MUDRA Scheme. Check details in Schemes tab.',
                  'आपका व्यवसाय प्रधान मंत्री मुद्रा योजना के लिए पात्र है। योजनाएं टैब में विवरण देखें।',
                  'तुमचा व्यवसाय प्रधानमंत्री मुद्रा योजनेसाठी पात्र आहे. योजना टॅबमध्ये तपशील तपासा.'
                ),
                time: l10n.pick('2 hours ago', '२ घंटे पहले', '२ तासांपूर्वी'),
                icon: Icons.account_balance_rounded,
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
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
