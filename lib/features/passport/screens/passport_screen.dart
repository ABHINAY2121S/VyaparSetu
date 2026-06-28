import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/passport_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/score_ring_widget.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/passport_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../../core/utils/trust_tier.dart';
import '../../../shared/widgets/trust_tier_badge_widget.dart';

class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PassportProvider>().load();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passportProvider = context.watch<PassportProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final onboarding = context.watch<OnboardingProvider>();
    final l10n = L10n.of(onboarding.selectedLanguage);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l10n.pick('Financial Passport', 'वित्तीय पासपोर्ट', 'वित्तीय पासपोर्ट')),
        backgroundColor: AppColors.background,
        actions: [
          if (passportProvider.hasPassport)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              color: AppColors.primary,
              onPressed: passportProvider.isExporting
                  ? null
                  : () => _downloadPdf(context, passportProvider, dashboardProvider),
              tooltip: l10n.pick('Download PDF', 'पीडीएफ डाउनलोड करें', 'पीडीएफ डाउनलोड करा'),
            ),
        ],
      ),
      body: passportProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
              child: Column(
                children: [
                  if (!passportProvider.hasPassport) ...[
                    _buildGenerateSection(passportProvider, dashboardProvider, l10n),
                  ] else ...[
                    _buildPassportCard(
                      passportProvider.latestPassport!,
                      dashboardProvider,
                      l10n,
                    ),
                    const SizedBox(height: 16),
                    _buildTrustTierSection(dashboardProvider, l10n),
                    const SizedBox(height: 16),
                    _buildScoreBreakdown(passportProvider.latestPassport!, l10n),
                    const SizedBox(height: 16),
                    _buildActions(passportProvider, dashboardProvider, l10n),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildGenerateSection(
    PassportProvider provider,
    DashboardProvider dashProvider,
    L10n l10n,
  ) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.primaryShadow,
          ),
          child: const Icon(Icons.credit_score_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.pick(
            'Generate Your\nFinancial Passport',
            'अपना वित्तीय\nपासपोर्ट बनाएं',
            'आपला वित्तीय\nपासपोर्ट बनवा',
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.pick(
            'Your passport is a verified document showing your\nbusiness health and loan eligibility',
            'आपका पासपोर्ट एक सत्यापित दस्तावेज़ है जो आपके\nव्यवसाय के स्वास्थ्य और ऋण पात्रता को दर्शाता है',
            'तुमचा पासपोर्ट हा एक सत्यापित दस्तऐवज आहे जो तुमच्या\nव्यवसायाचे आरोग्य आणि कर्ज पात्रता दर्शवतो',
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        // Preview scores
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPreviewScore(
              l10n.pick('Health', 'स्वास्थ्य', 'आरोग्य'),
              dashProvider.businessHealthScore,
              AppColors.primary,
            ),
            const SizedBox(width: 24),
            _buildPreviewScore(
              l10n.pick('Loan Ready', 'ऋण तैयार', 'कर्ज तयार'),
              dashProvider.loanReadinessScore,
              AppColors.secondary,
            ),
            const SizedBox(width: 24),
            _buildPreviewScore(
              l10n.pick('Confidence', 'आत्मविश्वास', 'आत्मविश्वास'),
              dashProvider.confidenceScore,
              const Color(0xFF7C3AED),
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (provider.isGenerating)
          Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                l10n.pick(
                  'AI is analyzing your financial data...',
                  'एआई आपके वित्तीय डेटा का विश्लेषण कर रहा है...',
                  'एआय तुमच्या वित्तीय डेटाचे विश्लेषण करत आहे...',
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          )
        else
          GradientButton(
            label: l10n.pick('Generate Passport', 'पासपोर्ट बनाएं', 'पासपोर्ट बनवा'),
            icon: Icons.auto_awesome_rounded,
            onPressed: () => _generate(provider, dashProvider),
          ),
      ],
    );
  }

  Widget _buildPreviewScore(String label, double score, Color color) {
    return Column(
      children: [
        ScoreRingWidget(
          score: score,
          label: label,
          color: color,
          size: 72,
          strokeWidth: 6,
          sublabel: '/100',
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPassportCard(
    PassportModel passport,
    DashboardProvider dashProvider,
    L10n l10n,
  ) {
    final business = dashProvider.business;
    final user = dashProvider.user;
    final tier = dashProvider.trustTier;

    final trustScore = TrustTierCalculator.computeScore(
      transactions: dashProvider.transactions,
      documents: dashProvider.documents,
      confidenceScore: passport.confidenceScore,
    );
    final trustTier = TrustTierCalculator.fromScore(trustScore);

    final verificationUrl = Uri.https(
      'abhinay2121s.github.io',
      '/VyaparSetu-Web/',
      {
        'id': passport.passportId,
        'hash': passport.verificationHash,
        'name': business?.businessName ?? '',
        'owner': user?.name ?? '',
        'city': business?.city ?? '',
        'health': passport.businessHealthScore.round().toString(),
        'loan': passport.loanReadinessScore.round().toString(),
        'confidence': passport.confidenceScore.round().toString(),
        'range': passport.recommendedLoanRange,
        'tier': trustTier.label,
      },
    ).toString();

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.padding24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.pick('FINANCIAL PASSPORT', 'वित्तीय पासपोर्ट', 'वित्तीय पासपोर्ट'),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'VyaparSetu',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tier == TrustTier.bronze
                            ? Colors.orange.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tier == TrustTier.bronze
                              ? Colors.orange.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            tier == TrustTier.bronze
                                ? Icons.warning_amber_rounded
                                : Icons.verified_rounded,
                            size: 12,
                            color: tier == TrustTier.bronze
                                ? Colors.orangeAccent
                                : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tier == TrustTier.bronze
                                ? l10n.pick('UNVERIFIED', 'असत्यापित', 'असत्यापित')
                                : l10n.pick('VERIFIED', 'सत्यापित', 'सत्यापित'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: tier == TrustTier.bronze
                                  ? Colors.orangeAccent
                                  : Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.white.withValues(alpha: 0.7), height: 1),
                const SizedBox(height: 20),
                // Business Info + QR Code Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business?.businessName ?? 'Your Business',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                user?.name ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              if (business?.city != null) ...[
                                Text(
                                  '  •  ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                Text(
                                  business!.city,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _showVerificationDialog(context, passport, l10n),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: 'passport_qr',
                          child: QrImageView(
                            data: verificationUrl,
                            version: QrVersions.auto,
                            size: 44.0,
                            gapless: false,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF064E3B),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF064E3B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Scores Row
                Row(
                  children: [
                    _buildPassportScore(
                      l10n.pick('Business\nHealth', 'व्यवसाय\nस्वास्थ्य', 'व्यवसाय\nआरोग्य'),
                      passport.businessHealthScore,
                      Colors.white,
                    ),
                    const SizedBox(width: 16),
                    _buildPassportScore(
                      l10n.pick('Loan\nReady', 'ऋण\nतैयार', 'कर्ज\nतयार'),
                      passport.loanReadinessScore,
                      AppColors.primaryLight,
                    ),
                    const SizedBox(width: 16),
                    _buildPassportScore(
                      l10n.pick('Confidence', 'आत्मविश्वास', 'आत्मविश्वास'),
                      passport.confidenceScore,
                      const Color(0xFFA78BFA),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.white.withValues(alpha: 0.7), height: 1),
                const SizedBox(height: 16),
                // Trust Tier Indicator Row
                Row(
                  children: [
                    Text(
                      '${tier.emoji} ',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      l10n.pick('Trust Level: ', 'ट्रस्ट स्तर: ', 'ट्रस्ट पातळी: '),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      l10n.pick(
                        '${tier.label} Trust',
                        '${tier.label} ट्रस्ट',
                        '${tier.label} ट्रस्ट',
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.pick(
                          'Tier ${4 - tier.index}',
                          'स्तर ${4 - tier.index}',
                          'स्तर ${4 - tier.index}',
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Loan Range
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_rounded,
                      size: 14,
                      color: Color(0xFF6EE7B7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.pick('Loan Eligibility: ', 'ऋण पात्रता: ', 'कर्ज पात्रता: '),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      passport.recommendedLoanRange,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6EE7B7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passport.passportId,
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          AppFormatters.formatDate(passport.generatedDate),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        passport.riskLevel.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassportScore(String label, double score, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            score.round().toString(),
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(PassportModel passport, L10n l10n) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.pick('Score Breakdown', 'स्कोर विवरण', 'स्कोअर तपशील')),
          const SizedBox(height: 16),
          ...passport.scoreBreakdown.map((item) {
            final label = item['label'] as String? ?? '';
            final points = item['points'] as String? ?? '0';
            final isPositive = item['positive'] as bool? ?? true;
            final description = item['description'] as String? ?? '';
            
            // Translate the breakdown labels
            String displayLabel = label;
            if (label == 'Business Health') {
              displayLabel = l10n.pick('Business Health', 'व्यवसाय स्वास्थ्य', 'व्यवसाय आरोग्य');
            } else if (label == 'Loan Readiness') {
              displayLabel = l10n.pick('Loan Readiness', 'ऋण तत्परता', 'कर्ज तत्परता');
            } else if (label == 'Confidence Score') {
              displayLabel = l10n.pick('Confidence Score', 'आत्मविश्वास स्कोर', 'आत्मविश्वास स्कोअर');
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isPositive
                          ? AppColors.primarySurface
                          : AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 16,
                      color: isPositive ? AppColors.primary : AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayLabel,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    points,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isPositive ? AppColors.primary : AppColors.error,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(),
          const SizedBox(height: 8),
          // Hash
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.pick('Verification: ', 'सत्यापन: ', 'पडताळणी: '),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                passport.verificationHash.substring(0, 16),
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustTierSection(
    DashboardProvider dashProvider,
    L10n l10n,
  ) {
    final tier = dashProvider.trustTier;
    final score = dashProvider.trustScore;
    final breakdown = TrustTierCalculator.getBreakdown(
      transactions: dashProvider.transactions,
      documents: dashProvider.documents,
      confidenceScore: dashProvider.confidenceScore,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.pick('Trust Verification', 'विश्वास सत्यापन', 'विश्वास सत्यापन'),
          ),
          const SizedBox(height: 16),
          TrustTierBadgeWidget(
            tier: tier,
            size: TrustBadgeSize.large,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.pick('Trust Tier Progress', 'ट्रस्ट टियर प्रगति', 'ट्रस्ट टियर प्रगती'),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TrustTierProgressBar(
            currentTier: tier,
            trustScore: score,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            l10n.pick('Verification Breakdown', 'सत्यापन विवरण', 'सत्यापन तपशील'),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...breakdown.map((item) {
            final label = item['label'] as String;
            final points = item['points'] as int;
            final maxPoints = item['maxPoints'] as int;
            final value = item['value'] as String;
            final positive = item['positive'] as bool;
            final tip = item['tip'] as String?;

            // Translate labels to support Hindi and Marathi
            String displayLabel = label;
            if (label == 'Bank-Imported Transactions') {
              displayLabel = l10n.pick('Bank-Imported Transactions', 'बैंक-आयातित लेनदेन', 'बँक-आयातित व्यवहार');
            } else if (label == 'OCR / UPI Verified') {
              displayLabel = l10n.pick('OCR / UPI Verified', 'ओसीआर / यूपीआई सत्यापित', 'ओसीआर / युपीआय सत्यापित');
            } else if (label == 'Verified Documents') {
              displayLabel = l10n.pick('Verified Documents', 'सत्यापित दस्तावेज़', 'सत्यापित कागदपत्रे');
            } else if (label == 'Confidence Score') {
              displayLabel = l10n.pick('Confidence Score', 'आत्मविश्वास स्कोर', 'आत्मविश्वास स्कोअर');
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayLabel,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        l10n.pick(
                          '$points/$maxPoints pts ($value)',
                          '$points/$maxPoints अंक ($value)',
                          '$points/$maxPoints गुण ($value)',
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: positive ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: maxPoints > 0 ? (points / maxPoints).clamp(0.0, 1.0) : 0.0,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: positive ? AppColors.primary : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (tip != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tip,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActions(
    PassportProvider provider,
    DashboardProvider dashProvider,
    L10n l10n,
  ) {
    return Column(
      children: [
        GradientButton(
          label: provider.isExporting
              ? l10n.pick('Exporting...', 'निर्यात किया जा रहा है...', 'निर्यात करत आहे...')
              : l10n.pick('Download PDF Passport', 'पीडीएफ पासपोर्ट डाउनलोड करें', 'पीडीएफ पासपोर्ट डाउनलोड करा'),
          icon: Icons.download_rounded,
          isLoading: provider.isExporting,
          onPressed: () => _downloadPdf(context, provider, dashProvider),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _generate(provider, dashProvider),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.pick('Regenerate', 'पुनर्जनित करें', 'पुन्हा निर्माण करा')),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, AppDimensions.buttonHeightLG),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generate(
    PassportProvider provider,
    DashboardProvider dashProvider,
  ) async {
    await dashProvider.load();
    await provider.generatePassport(
      transactions: dashProvider.transactions,
      documents: dashProvider.documents,
      user: dashProvider.user!,
      business: dashProvider.business!,
    );
  }

  void _showVerificationDialog(
    BuildContext context,
    PassportModel passport,
    L10n l10n,
  ) {
    final dashProvider = context.read<DashboardProvider>();
    final business = dashProvider.business;
    final user = dashProvider.user;
    final transactions = dashProvider.transactions;
    final documents = dashProvider.documents;

    final trustScore = TrustTierCalculator.computeScore(
      transactions: transactions,
      documents: documents,
      confidenceScore: passport.confidenceScore,
    );
    final trustTier = TrustTierCalculator.fromScore(trustScore);

    final verificationUrl = Uri.https(
      'abhinay2121s.github.io',
      '/VyaparSetu-Web/',
      {
        'id': passport.passportId,
        'hash': passport.verificationHash,
        'name': business?.businessName ?? '',
        'owner': user?.name ?? '',
        'city': business?.city ?? '',
        'health': passport.businessHealthScore.round().toString(),
        'loan': passport.loanReadinessScore.round().toString(),
        'confidence': passport.confidenceScore.round().toString(),
        'range': passport.recommendedLoanRange,
        'tier': trustTier.label,
      },
    ).toString();

    showDialog(
      context: context,
      builder: (context) {

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.padding24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.pick('Verify Passport', 'पासपोर्ट सत्यापित करें', 'पासपोर्ट सत्यापित करा'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: QrImageView(
                      data: verificationUrl,
                      version: QrVersions.auto,
                      size: 180.0,
                      gapless: false,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF064E3B),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.pick(
                      'Scan to Verify Authenticity',
                      'सत्यता सत्यापित करने के लिए स्कैन करें',
                      'सत्यता सत्यापित करण्यासाठी स्कॅन करा',
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.pick(
                      'Lenders and banks can scan this QR code to view your verified live credit score on our official portal, protecting against document tampering.',
                      'ऋणदाता और बैंक आपके सत्यापित लाइव क्रेडिट स्कोर को हमारे आधिकारिक पोर्टल पर देखने के लिए इस क्यूआर कोड को स्कैन कर सकते हैं, जिससे दस्तावेज़ के साथ छेड़छाड़ से सुरक्षा मिलती है।',
                      'कर्जदार आणि बँका तुमच्या सत्यापित लाइव्ह क्रेडिट स्कोअरला आमच्या अधिकृत पोर्टलवर पाहण्यासाठी हा क्यूआर कोड स्कॅन करू शकतात, ज्यामुळे दस्तऐवजातील छेडछाडीपासून संरक्षण मिळते.',
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: verificationUrl));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.pick(
                                'Verification link copied!',
                                'सत्यापन लिंक कॉपी की गई!',
                                'सत्यापन लिंक कॉपी केली!',
                              ),
                            ),
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(l10n.pick('Copy Verification Link', 'सत्यापन लिंक कॉपी करें', 'सत्यापन लिंक कॉपी करा')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadPdf(
    BuildContext context,
    PassportProvider provider,
    DashboardProvider dashProvider,
  ) async {
    await provider.downloadPdf(
      passport: provider.latestPassport!,
      business: dashProvider.business!,
      user: dashProvider.user!,
      transactions: dashProvider.transactions,
      documents: dashProvider.documents,
    );
  }

}

