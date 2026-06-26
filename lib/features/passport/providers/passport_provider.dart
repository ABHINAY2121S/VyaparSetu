import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/utils/score_calculator.dart';
import '../../../shared/models/passport_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/models/document_model.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/models/user_model.dart';

class PassportProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;
  final PdfService _pdfService = PdfService.instance;
  final _uuid = const Uuid();

  List<PassportModel> _passports = [];
  PassportModel? _latestPassport;
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isExporting = false;
  String? _error;

  List<PassportModel> get passports => _passports;
  PassportModel? get latestPassport => _latestPassport;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isExporting => _isExporting;
  String? get error => _error;
  bool get hasPassport => _latestPassport != null;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _passports = _storage.getPassports();
    if (_passports.isNotEmpty) {
      _passports.sort((a, b) => b.generatedDate.compareTo(a.generatedDate));
      _latestPassport = _passports.first;
    } else {
      _latestPassport = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _passports = [];
    _latestPassport = null;
    _isLoading = false;
    _isGenerating = false;
    _isExporting = false;
    _error = null;
    notifyListeners();
  }

  Future<PassportModel?> generatePassport({
    required List<TransactionModel> transactions,
    required List<DocumentModel> documents,
    required UserModel user,
    required BusinessModel business,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate AI processing delay
      await Future.delayed(const Duration(seconds: 2));

      final healthScore =
          ScoreCalculator.calculateBusinessHealthScore(transactions);
      final loanScore =
          ScoreCalculator.calculateLoanReadinessScore(transactions);
      final confidenceScore = ScoreCalculator.calculateConfidenceScore(
        transactions,
        documents,
        user.profileSetupComplete,
      );

      final riskLevel = ScoreCalculator.getRiskLevel(
        healthScore,
        loanScore,
        confidenceScore,
      );

      final loanData =
          ScoreCalculator.getRecommendedLoan(transactions, loanScore);
      final breakdown =
          ScoreCalculator.getScoreBreakdown(transactions, documents);

      // Generate unique IDs
      final passportId = _generatePassportId();
      final reportId = _generateReportId();

      // Generate cryptographic hash
      final hash = _generateHash(
        passportId: passportId,
        healthScore: healthScore,
        loanScore: loanScore,
        confidenceScore: confidenceScore,
        timestamp: DateTime.now(),
      );

      final passport = PassportModel(
        id: _uuid.v4(),
        passportId: passportId,
        reportId: reportId,
        businessHealthScore: healthScore,
        loanReadinessScore: loanScore,
        confidenceScore: confidenceScore,
        riskLevel: riskLevel,
        recommendedLoanRange: loanData['label'] as String,
        scoreBreakdown: breakdown,
        verificationHash: hash,
        generatedDate: DateTime.now(),
        isLocked: true,
      );

      _passports.insert(0, passport);
      _latestPassport = passport;
      await _storage.savePassports(_passports);

      _isGenerating = false;
      notifyListeners();
      return passport;
    } catch (e) {
      _error = 'Failed to generate passport. Please try again.';
      _isGenerating = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> downloadPdf({
    required PassportModel passport,
    required BusinessModel business,
    required UserModel user,
    required List<TransactionModel> transactions,
    required List<DocumentModel> documents,
  }) async {
    _isExporting = true;
    _error = null;
    notifyListeners();

    try {
      final pdfBytes = await _pdfService.generatePassportPdf(
        passport: passport,
        business: business,
        user: user,
        transactions: transactions,
        documents: documents,
      );

      await _pdfService.sharePdf(
        pdfBytes,
        'VyaparSetu_${passport.passportId}.pdf',
      );
    } catch (e) {
      _error = 'Failed to export PDF. Please try again.';
    }

    _isExporting = false;
    notifyListeners();
  }

  String _generatePassportId() {
    final now = DateTime.now();
    final seq = (_passports.length + 1).toString().padLeft(3, '0');
    return 'VS-${now.year}-$seq';
  }

  String _generateReportId() {
    final now = DateTime.now();
    return 'RPT-${now.year}${now.month.toString().padLeft(2, '0')}-${_uuid.v4().substring(0, 6).toUpperCase()}';
  }

  String _generateHash({
    required String passportId,
    required double healthScore,
    required double loanScore,
    required double confidenceScore,
    required DateTime timestamp,
  }) {
    final data =
        '$passportId|${healthScore.toStringAsFixed(2)}|${loanScore.toStringAsFixed(2)}|${confidenceScore.toStringAsFixed(2)}|${timestamp.toIso8601String()}';
    final bytes = utf8.encode(data);
    return sha256.convert(bytes).toString().toUpperCase().substring(0, 24);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
