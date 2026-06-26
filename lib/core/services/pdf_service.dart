import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../constants/app_strings.dart';
import '../../shared/models/passport_model.dart';
import '../../shared/models/business_model.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/transaction_model.dart';
import '../../shared/models/document_model.dart';

class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  Future<Uint8List> generatePassportPdf({
    required PassportModel passport,
    required BusinessModel business,
    required UserModel user,
    required List<TransactionModel> transactions,
    required List<DocumentModel> documents,
  }) async {
    final pdf = pw.Document(
      title: 'VyaparSetu — Financial Passport',
      author: 'VyaparSetu',
    );

    final primaryColor = PdfColor.fromHex('#059669');
    final blueColor = PdfColor.fromHex('#2563EB');
    final darkColor = PdfColor.fromHex('#111827');
    final grayColor = PdfColor.fromHex('#6B7280');
    final lightGray = PdfColor.fromHex('#F9FAFB');
    final borderColor = PdfColor.fromHex('#E5E7EB');

    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final totalIncome = income.fold<double>(0, (s, t) => s + t.amount);
    final totalExpense = expenses.fold<double>(0, (s, t) => s + t.amount);
    final netProfit = totalIncome - totalExpense;

    final verifiedDocs =
        documents.where((d) => d.status == DocumentStatus.verified).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(primaryColor, darkColor, blueColor),
          pw.SizedBox(height: 16),

          // Passport ID banner
          _buildPassportBanner(
            passport,
            primaryColor,
            lightGray,
            borderColor,
          ),
          pw.SizedBox(height: 20),

          // Business Profile
          _buildSectionTitle('Business Profile', darkColor),
          pw.SizedBox(height: 8),
          _buildBusinessProfile(business, user, lightGray, grayColor, darkColor),
          pw.SizedBox(height: 20),

          // Scores
          _buildSectionTitle('AI Score Summary', darkColor),
          pw.SizedBox(height: 8),
          _buildScoreCards(passport, primaryColor, blueColor, lightGray),
          pw.SizedBox(height: 20),

          // Financial Summary
          _buildSectionTitle('Financial Summary', darkColor),
          pw.SizedBox(height: 8),
          _buildFinancialSummary(
            totalIncome,
            totalExpense,
            netProfit,
            primaryColor,
            lightGray,
            borderColor,
          ),
          pw.SizedBox(height: 20),

          // Documents
          _buildSectionTitle(
            'Document Verification ($verifiedDocs/${documents.length} Verified)',
            darkColor,
          ),
          pw.SizedBox(height: 8),
          _buildDocumentStatus(documents, primaryColor, lightGray),
          pw.SizedBox(height: 20),

          // AI Explanation
          _buildSectionTitle('Score Breakdown (Explainable AI)', darkColor),
          pw.SizedBox(height: 8),
          _buildScoreBreakdown(passport.scoreBreakdown, primaryColor, lightGray),
          pw.SizedBox(height: 20),

          // Loan Recommendation
          _buildLoanRecommendation(passport, primaryColor, blueColor, lightGray),
          pw.SizedBox(height: 20),

          // Immutable Record
          _buildImmutableRecord(passport, borderColor, grayColor, primaryColor),
          pw.SizedBox(height: 16),

          // Footer
          _buildFooter(grayColor, darkColor),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    PdfColor primary,
    PdfColor dark,
    PdfColor blue,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColor.fromHex('#059669'), PdfColor.fromHex('#10B981')],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'VyaparSetu',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                AppStrings.appTagline,
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColor.fromHex('#D1FAE5'),
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'FINANCIAL PASSPORT',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Official Document',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromHex('#D1FAE5'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPassportBanner(
    PassportModel passport,
    PdfColor primary,
    PdfColor light,
    PdfColor border,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: light,
        border: pw.Border.all(color: border),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoChip('Passport ID', passport.passportId, primary),
          _buildInfoChip('Report ID', passport.reportId, primary),
          _buildInfoChip(
            'Generated',
            _formatDate(passport.generatedDate),
            primary,
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#D1FAE5'),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              '🔒 SEALED',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoChip(String label, String value, PdfColor primary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColor.fromHex('#9CA3AF'),
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#111827'),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title, PdfColor dark) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 18,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#059669'),
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: dark,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildBusinessProfile(
    BusinessModel business,
    UserModel user,
    PdfColor light,
    PdfColor gray,
    PdfColor dark,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: light,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              _buildProfileField('Business Name', business.businessName, dark, gray),
              pw.SizedBox(width: 20),
              _buildProfileField('Owner Name', user.name, dark, gray),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _buildProfileField('Business Type', business.businessType, dark, gray),
              pw.SizedBox(width: 20),
              _buildProfileField('City', business.city, dark, gray),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _buildProfileField(
                'Business Age',
                '${business.businessAge} Years',
                dark,
                gray,
              ),
              pw.SizedBox(width: 20),
              _buildProfileField(
                'Revenue Range',
                business.revenueRange,
                dark,
                gray,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProfileField(
    String label,
    String value,
    PdfColor dark,
    PdfColor gray,
  ) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 8,
              color: gray,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: dark,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildScoreCards(
    PassportModel passport,
    PdfColor primary,
    PdfColor blue,
    PdfColor light,
  ) {
    return pw.Row(
      children: [
        _buildScoreCard(
          'Business Health',
          passport.businessHealthScore,
          primary,
        ),
        pw.SizedBox(width: 12),
        _buildScoreCard('Loan Readiness', passport.loanReadinessScore, blue),
        pw.SizedBox(width: 12),
        _buildScoreCard(
          'Confidence',
          passport.confidenceScore,
          PdfColor.fromHex('#7C3AED'),
        ),
      ],
    );
  }

  pw.Widget _buildScoreCard(String label, double score, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              score.round().toString(),
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '/100',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey300),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              label,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildFinancialSummary(
    double income,
    double expense,
    double profit,
    PdfColor primary,
    PdfColor light,
    PdfColor border,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: border),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          _buildFinanceCell('Total Revenue', income, primary, true),
          _buildFinanceCell(
            'Total Expenses',
            expense,
            PdfColor.fromHex('#EF4444'),
            false,
          ),
          _buildFinanceCell(
            'Net Profit',
            profit,
            profit >= 0 ? primary : PdfColor.fromHex('#EF4444'),
            false,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFinanceCell(
    String label,
    double amount,
    PdfColor color,
    bool first,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: first
              ? null
              : const pw.Border(
                  left: pw.BorderSide(color: PdfColors.grey300),
                ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColor.fromHex('#6B7280'),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '₹${_formatAmount(amount)}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildDocumentStatus(
    List<DocumentModel> documents,
    PdfColor primary,
    PdfColor light,
  ) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: documents.map((doc) {
        final isVerified = doc.status == DocumentStatus.verified;
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: isVerified
                ? PdfColor.fromHex('#D1FAE5')
                : PdfColor.fromHex('#F3F4F6'),
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(
              color: isVerified
                  ? PdfColor.fromHex('#059669')
                  : PdfColor.fromHex('#D1D5DB'),
            ),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                isVerified ? '✓ ' : '○ ',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: isVerified
                      ? PdfColor.fromHex('#059669')
                      : PdfColor.fromHex('#9CA3AF'),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                doc.name,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: isVerified
                      ? PdfColor.fromHex('#059669')
                      : PdfColor.fromHex('#6B7280'),
                  fontWeight: isVerified
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildScoreBreakdown(
    List<Map<String, dynamic>> breakdown,
    PdfColor primary,
    PdfColor light,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: light,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: breakdown.map((item) {
          final isPositive = item['positive'] as bool;
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  item['label'] as String,
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColor.fromHex('#111827'),
                  ),
                ),
                pw.Text(
                  item['points'] as String,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: isPositive
                        ? PdfColor.fromHex('#059669')
                        : PdfColor.fromHex('#EF4444'),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _buildLoanRecommendation(
    PassportModel passport,
    PdfColor primary,
    PdfColor blue,
    PdfColor light,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            PdfColor.fromHex('#1D4ED8'),
            PdfColor.fromHex('#3B82F6'),
          ],
        ),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Recommended Loan Range',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromHex('#BFDBFE'),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                passport.recommendedLoanRange,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Risk Level',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromHex('#BFDBFE'),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: passport.riskLevel == 'Low'
                      ? PdfColor.fromHex('#059669')
                      : passport.riskLevel == 'Medium'
                      ? PdfColor.fromHex('#F59E0B')
                      : PdfColor.fromHex('#EF4444'),
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  '${passport.riskLevel} Risk',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildImmutableRecord(
    PassportModel passport,
    PdfColor border,
    PdfColor gray,
    PdfColor primary,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: border, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                '🔒 Immutable Record — This document is cryptographically sealed',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#374151'),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Verification Hash: ${passport.verificationHash}',
            style: pw.TextStyle(
              fontSize: 8,
              color: gray,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(PdfColor gray, PdfColor dark) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by VyaparSetu — vyaparsetu.app',
              style: pw.TextStyle(fontSize: 8, color: gray),
            ),
            pw.Text(
              'This document is for financial reference only.',
              style: pw.TextStyle(fontSize: 8, color: gray),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
