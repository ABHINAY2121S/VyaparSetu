import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/widgets/verification_badge_widget.dart';
import '../providers/transaction_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = ModalRoute.of(context)!.settings.arguments as TransactionModel;
    final isIncome = tx.type == TransactionType.income;
    final onboarding = context.watch<OnboardingProvider>();
    final l10n = L10n.of(onboarding.selectedLanguage);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l10n.transactionDetail),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.error,
            onPressed: () => _confirmDelete(context, tx, l10n),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.padding32),
              color: AppColors.background,
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isIncome
                          ? AppColors.primarySurface
                          : AppColors.errorSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIncome
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: isIncome ? AppColors.primary : AppColors.error,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${isIncome ? '+' : '-'}${AppFormatters.formatCurrency(tx.amount)}',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: isIncome ? AppColors.primary : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  VerificationBadgeWidget(badge: tx.verificationBadge),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Details
            Container(
              color: AppColors.background,
              child: Column(
                children: [
                  _buildDetailRow(
                    l10n.typeLabel,
                    isIncome ? l10n.income : l10n.expense,
                    Icons.swap_horiz_rounded,
                    isIncome ? AppColors.primary : AppColors.error,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildDetailRow(
                    l10n.categoryLabel.replaceAll(' *', ''), // Removing ' *' added previously for AddTransaction
                    tx.category,
                    Icons.label_outline_rounded,
                    AppColors.textSecondary,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildDetailRow(
                    l10n.dateLabel,
                    AppFormatters.formatDateTime(tx.date),
                    Icons.calendar_today_rounded,
                    AppColors.textSecondary,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildDetailRow(
                    l10n.verificationLabel,
                    _getVerificationLabel(tx.verificationBadge, l10n),
                    Icons.verified_rounded,
                    tx.verificationBadge.isVerified
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                  if (tx.note != null) ...[
                    const Divider(height: 1, indent: 56),
                    _buildDetailRow(
                      l10n.noteLabel,
                      tx.note!,
                      Icons.note_outlined,
                      AppColors.textSecondary,
                    ),
                  ],
                  if (tx.integrityHash != null) ...[
                    const Divider(height: 1, indent: 56),
                    _buildDetailRow(
                      l10n.pick('Integrity Hash', 'इंटीग्रिटी हैश', 'इंटिग्रिटी हॅश'),
                      '${tx.integrityHash!.substring(0, 16)}…${tx.integrityHash!.substring(tx.integrityHash!.length - 8)}',
                      Icons.lock_outline_rounded,
                      AppColors.primary,
                    ),
                  ],
                  if (tx.isBankImported) ...[
                    const Divider(height: 1, indent: 56),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLG,
                        vertical: AppDimensions.paddingMD,
                      ),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded,
                              size: 18, color: Color(0xFFB45309)),
                        ),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            l10n.pick('Source', 'स्रोत', 'स्रोत'),
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD97706)),
                            ),
                            child: Text(
                              l10n.pick('🏦 Bank Imported — Immutable', '🏦 बैंक से आयातित — अपरिवर्तनीय', '🏦 बँक आयातित — अपरिवर्तनीय'),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVerificationLabel(VerificationBadge badge, L10n l10n) {
    switch(badge) {
      case VerificationBadge.bankImported:
        return l10n.pick('Bank Imported', 'बैंक से आयातित', 'बँक आयातित');
      case VerificationBadge.manualEntry:
        return l10n.manual;
      case VerificationBadge.bankVerified:
        return l10n.autoVerifiedGateway;
      case VerificationBadge.upiVerified:
        return l10n.upi;
      case VerificationBadge.ocrVerified:
        return l10n.ocr;
    }
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLG,
        vertical: AppDimensions.paddingMD,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, TransactionModel tx, L10n l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        title: Text(l10n.deleteTransaction),
        content: Text(
          l10n.deleteTransactionConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<TransactionProvider>().deleteTransaction(tx.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
