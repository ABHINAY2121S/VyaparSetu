import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/verification_badge_widget.dart';
import '../providers/transaction_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final onboarding = context.watch<OnboardingProvider>();
    final l10n = L10n.of(onboarding.selectedLanguage);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(l10n.transactions),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            color: AppColors.primary,
            onPressed: () => Navigator.of(context).pushNamed('/add-transaction')
                .then((_) => provider.load()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
          onTap: (index) {
            if (index == 0) {
              provider.showAllTransactions();
            } else if (index == 1) {
              provider.setFilter(TransactionType.income);
            } else {
              provider.setFilter(TransactionType.expense);
            }
          },
          tabs: [
            Tab(text: l10n.all),
            Tab(text: l10n.income),
            Tab(text: l10n.expense),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary row
          _buildSummaryRow(provider, l10n),
          const SizedBox(height: 8),
          // Transaction list
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTransactionList(provider, l10n),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .pushNamed('/add-transaction')
            .then((_) => provider.load()),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          l10n.addTransaction,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(TransactionProvider provider, L10n l10n) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingXXL,
        vertical: AppDimensions.paddingMD,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryChip(
              l10n.income,
              AppFormatters.formatCompact(provider.totalIncome),
              AppColors.primary,
              AppColors.primarySurface,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryChip(
              l10n.expense,
              AppFormatters.formatCompact(provider.totalExpense),
              AppColors.error,
              AppColors.errorSurface,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryChip(
              l10n.net,
              AppFormatters.formatCompact(
                provider.totalIncome - provider.totalExpense,
              ),
              provider.totalIncome >= provider.totalExpense
                  ? AppColors.secondary
                  : AppColors.error,
              AppColors.secondarySurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(
    String label,
    String value,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(TransactionProvider provider, L10n l10n) {
    final transactions = provider.filteredTransactions;

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: AppColors.border,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noTransactionsYet,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tapToAddFirst,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<TransactionModel>>{};
    for (final tx in transactions) {
      final key = AppFormatters.formatDate(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPaddingH,
        8,
        AppDimensions.screenPaddingH,
        100,
      ),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final txs = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
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
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
    final isIncome = tx.type == TransactionType.income;

    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(
        '/transaction-detail',
        arguments: tx,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLG,
          vertical: AppDimensions.paddingMD,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isIncome
                    ? AppColors.primarySurface
                    : AppColors.errorSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isIncome ? AppColors.primary : AppColors.error,
                size: 20,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tx.category,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${isIncome ? '+' : '-'}${AppFormatters.formatCurrency(tx.amount)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isIncome ? AppColors.primary : AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatTime(tx.date),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
