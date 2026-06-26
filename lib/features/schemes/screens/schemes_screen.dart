import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/models/scheme_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../providers/scheme_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final score =
          context.read<DashboardProvider>().loanReadinessScore;
      context.read<SchemeProvider>().load(loanReadinessScore: score);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchemeProvider>();
    final l10n = L10n.of(context.watch<OnboardingProvider>().selectedLanguage);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l10n.schemesTitle),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          _buildCategoryFilter(provider, l10n),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.schemes.isEmpty
                    ? Center(child: Text(l10n.schemeNoFound))
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
                        itemCount: provider.schemes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildSchemeCard(provider.schemes[index], l10n);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ── translates the category key from SchemeProvider to the l10n label ──
  String _translateCategory(String cat, L10n l10n) {
    switch (cat) {
      case 'All':            return l10n.schemeCatAll;
      case 'Loan':           return l10n.schemeCatLoan;
      case 'Guarantee':      return l10n.schemeCatGuarantee;
      case 'Subsidy + Loan': return l10n.schemeCatSubsidy;
      default:               return cat;
    }
  }

  Widget _buildCategoryFilter(SchemeProvider provider, L10n l10n) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingH,
        vertical: AppDimensions.paddingMD,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: provider.categories.map((cat) {
            final isSelected = provider.selectedCategory == cat;
            return GestureDetector(
              onTap: () => provider.setCategory(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  _translateCategory(cat, l10n),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSchemeCard(SchemeModel scheme, L10n l10n) {
    final eligibilityColor = scheme.eligibilityPercent >= 80
        ? AppColors.success
        : scheme.eligibilityPercent >= 60
            ? AppColors.warning
            : AppColors.error;

    final name  = _schemeName(scheme.id, l10n);
    final short = _schemeShort(scheme.id, l10n);

    return AppCard(
      onTap: () => _showSchemeDetail(scheme, l10n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (scheme.isPopular) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningSurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.schemePopular,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            _translateCategory(scheme.category, l10n),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      short,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Eligibility Circle
              Column(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: scheme.eligibilityPercent / 100,
                          strokeWidth: 5,
                          backgroundColor: eligibilityColor.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            eligibilityColor,
                          ),
                        ),
                        Text(
                          '${scheme.eligibilityPercent.round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: eligibilityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.schemeMatch,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSchemeInfoChip(
                  Icons.account_balance_wallet_outlined,
                  l10n.schemeLoanRange,
                  scheme.loanRange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSchemeInfoChip(
                  Icons.percent_rounded,
                  l10n.schemeInterest,
                  scheme.interestRate,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showSchemeDetail(scheme, l10n),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.schemeDetails,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeInfoChip(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: AppColors.textTertiary),
            const SizedBox(width: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showSchemeDetail(SchemeModel scheme, L10n l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SchemeDetailSheet(scheme: scheme, l10n: l10n),
    );
  }

  // ── Helpers: map scheme.id → l10n string ──────────────────────────────────
  String _schemeName(String id, L10n l10n) {
    switch (id) {
      case 'scheme_001': return l10n.scheme001Name;
      case 'scheme_002': return l10n.scheme002Name;
      case 'scheme_003': return l10n.scheme003Name;
      case 'scheme_004': return l10n.scheme004Name;
      case 'scheme_005': return l10n.scheme005Name;
      case 'scheme_006': return l10n.scheme006Name;
      default:           return id;
    }
  }

  String _schemeShort(String id, L10n l10n) {
    switch (id) {
      case 'scheme_001': return l10n.scheme001Short;
      case 'scheme_002': return l10n.scheme002Short;
      case 'scheme_003': return l10n.scheme003Short;
      case 'scheme_004': return l10n.scheme004Short;
      case 'scheme_005': return l10n.scheme005Short;
      case 'scheme_006': return l10n.scheme006Short;
      default:           return '';
    }
  }
}

// ── Detail sheet ─────────────────────────────────────────────────────────────
class _SchemeDetailSheet extends StatelessWidget {
  final SchemeModel scheme;
  final L10n l10n;

  const _SchemeDetailSheet({required this.scheme, required this.l10n});

  String _fullDesc() {
    switch (scheme.id) {
      case 'scheme_001': return l10n.scheme001Full;
      case 'scheme_002': return l10n.scheme002Full;
      case 'scheme_003': return l10n.scheme003Full;
      case 'scheme_004': return l10n.scheme004Full;
      case 'scheme_005': return l10n.scheme005Full;
      case 'scheme_006': return l10n.scheme006Full;
      default:           return scheme.fullDescription;
    }
  }

  List<String> _benefits() {
    switch (scheme.id) {
      case 'scheme_001': return l10n.scheme001Benefits;
      case 'scheme_002': return l10n.scheme002Benefits;
      case 'scheme_003': return l10n.scheme003Benefits;
      case 'scheme_004': return l10n.scheme004Benefits;
      case 'scheme_005': return l10n.scheme005Benefits;
      case 'scheme_006': return l10n.scheme006Benefits;
      default:           return scheme.benefits;
    }
  }

  List<String> _docs() {
    switch (scheme.id) {
      case 'scheme_001': return l10n.scheme001Docs;
      case 'scheme_002': return l10n.scheme002Docs;
      case 'scheme_003': return l10n.scheme003Docs;
      case 'scheme_004': return l10n.scheme004Docs;
      case 'scheme_005': return l10n.scheme005Docs;
      case 'scheme_006': return l10n.scheme006Docs;
      default:           return scheme.requiredDocuments;
    }
  }

  List<String> _eligible() {
    switch (scheme.id) {
      case 'scheme_001': return l10n.scheme001Eligible;
      case 'scheme_002': return l10n.scheme002Eligible;
      case 'scheme_003': return l10n.scheme003Eligible;
      case 'scheme_004': return l10n.scheme004Eligible;
      case 'scheme_005': return l10n.scheme005Eligible;
      case 'scheme_006': return l10n.scheme006Eligible;
      default:           return scheme.eligibleFor;
    }
  }

  String _name() {
    switch (scheme.id) {
      case 'scheme_001': return l10n.scheme001Name;
      case 'scheme_002': return l10n.scheme002Name;
      case 'scheme_003': return l10n.scheme003Name;
      case 'scheme_004': return l10n.scheme004Name;
      case 'scheme_005': return l10n.scheme005Name;
      case 'scheme_006': return l10n.scheme006Name;
      default:           return scheme.name;
    }
  }

  Future<void> _openSchemePortal(BuildContext context) async {
    final uri = Uri.parse(scheme.applyUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open browser. URL: ${scheme.applyUrl}'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXL),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXXL,
                  ),
                  children: [
                    Text(
                      _name(),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fullDesc(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(l10n.schemeBenefits, _benefits(), Icons.check_circle_rounded, AppColors.success),
                    const SizedBox(height: 16),
                    _buildSection(l10n.schemeDocuments, _docs(), Icons.description_outlined, AppColors.secondary),
                    const SizedBox(height: 16),
                    _buildSection(l10n.schemeEligibleFor, _eligible(), Icons.people_outline_rounded, AppColors.primary),
                    const SizedBox(height: 24),
                    // ── Apply Online Button ───────────────────────────────
                    ElevatedButton.icon(
                      onPressed: () => _openSchemePortal(context),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(l10n.schemeApplyOnline),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightLG),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        scheme.applyUrl,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
