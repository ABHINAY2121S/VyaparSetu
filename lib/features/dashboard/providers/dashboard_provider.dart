import 'package:flutter/material.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/score_calculator.dart';
import '../../../core/utils/trust_tier.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/models/document_model.dart';
import '../../../shared/models/insight_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/business_model.dart';

class DashboardProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  List<TransactionModel> _transactions = [];
  List<DocumentModel> _documents = [];
  UserModel? _user;
  BusinessModel? _business;

  double _businessHealthScore = 0;
  double _loanReadinessScore = 0;
  double _confidenceScore = 0;
  List<InsightModel> _insights = [];
  TrustTier _trustTier = TrustTier.bronze;
  double _trustScore = 0;

  bool _isLoading = false;
  bool _isDemoModeActive = false;

  List<TransactionModel> get transactions => _transactions;
  List<DocumentModel> get documents => _documents;
  UserModel? get user => _user;
  BusinessModel? get business => _business;
  double get businessHealthScore => _businessHealthScore;
  double get loanReadinessScore => _loanReadinessScore;
  double get confidenceScore => _confidenceScore;
  List<InsightModel> get insights => _insights;
  bool get isLoading => _isLoading;
  bool get isDemoModeActive => _isDemoModeActive;

  /// Current trust tier for this business.
  TrustTier get trustTier => _trustTier;

  /// Raw 0–100 trust score behind the tier.
  double get trustScore => _trustScore;

  List<TransactionModel> get recentTransactions =>
      _transactions.take(5).toList();

  List<TransactionModel> get incomeTransactions =>
      _transactions.where((t) => t.type == TransactionType.income).toList();

  List<TransactionModel> get expenseTransactions =>
      _transactions.where((t) => t.type == TransactionType.expense).toList();

  double get totalRevenue =>
      incomeTransactions.fold(0, (s, t) => s + t.amount);

  double get totalExpenses =>
      expenseTransactions.fold(0, (s, t) => s + t.amount);

  double get netProfit => totalRevenue - totalExpenses;

  double get cashFlow => totalRevenue - totalExpenses;

  List<Map<String, double>> get monthlyChartData {
    final now = DateTime.now();
    final data = <Map<String, double>>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';

      final income = _transactions
          .where(
            (t) =>
                t.type == TransactionType.income &&
                '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}' ==
                    monthKey,
          )
          .fold<double>(0, (s, t) => s + t.amount);

      final expense = _transactions
          .where(
            (t) =>
                t.type == TransactionType.expense &&
                '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}' ==
                    monthKey,
          )
          .fold<double>(0, (s, t) => s + t.amount);

      data.add({
        'income': income,
        'expense': expense,
        'profit': income - expense,
      });
    }

    return data;
  }

  int get verifiedDocCount =>
      _documents.where((d) => d.status == DocumentStatus.verified).length;

  double get documentVerificationPercent =>
      _documents.isEmpty ? 0 : verifiedDocCount / _documents.length;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _transactions = _storage.getTransactions();
    _documents = _storage.getDocuments();
    _user = _storage.getUser() ?? UserModel.defaultUser;
    _business = _storage.getBusiness() ?? BusinessModel.defaultBusiness;
    _isDemoModeActive = false;

    _recalculateScores();
    _generateInsights();

    _isLoading = false;
    notifyListeners();
  }

  void _recalculateScores() {
    _businessHealthScore =
        ScoreCalculator.calculateBusinessHealthScore(_transactions);
    _loanReadinessScore =
        ScoreCalculator.calculateLoanReadinessScore(_transactions);
    _confidenceScore = ScoreCalculator.calculateConfidenceScore(
      _transactions,
      _documents,
      _user?.profileSetupComplete ?? false,
    );

    // Trust Tier — computed after confidence score is ready
    _trustScore = TrustTierCalculator.computeScore(
      transactions: _transactions,
      documents: _documents,
      confidenceScore: _confidenceScore,
    );
    _trustTier = TrustTierCalculator.fromScore(_trustScore);
  }

  void _generateInsights() {
    final data = monthlyChartData;
    double revenueChange = 0;
    double expenseChange = 0;

    if (data.length >= 2) {
      final prev = data[data.length - 2];
      final curr = data[data.length - 1];
      if ((prev['income'] ?? 0) > 0) {
        revenueChange =
            ((curr['income'] ?? 0) - (prev['income'] ?? 0)) /
            (prev['income'] ?? 1) *
            100;
      }
      if ((prev['expense'] ?? 0) > 0) {
        expenseChange =
            ((curr['expense'] ?? 0) - (prev['expense'] ?? 0)) /
            (prev['expense'] ?? 1) *
            100;
      }
    }

    final profitMargin =
        totalRevenue > 0 ? netProfit / totalRevenue : 0.0;

    _insights = InsightModel.generateInsights(
      healthScore: _businessHealthScore,
      loanScore: _loanReadinessScore,
      confidenceScore: _confidenceScore,
      revenueChangePercent: revenueChange,
      expenseChangePercent: expenseChange,
      profitMargin: profitMargin,
      verifiedDocCount: verifiedDocCount,
      totalDocCount: _documents.length,
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void refresh() {
    load();
  }

  void reset() {
    _transactions = [];
    _documents = [];
    _user = null;
    _business = null;
    _businessHealthScore = 0;
    _loanReadinessScore = 0;
    _confidenceScore = 0;
    _insights = [];
    _trustTier = TrustTier.bronze;
    _trustScore = 0;
    _isDemoModeActive = false;
    notifyListeners();
  }

  Future<void> disableDemoMode() async {
    _isLoading = true;
    notifyListeners();

    // Wipe demo transactions and documents
    await _storage.clearTransactions();
    await _storage.clearDocuments();

    // Restore the real user and business from storage
    _user = _storage.getUser() ?? UserModel.defaultUser;
    _business = _storage.getBusiness() ?? BusinessModel.defaultBusiness;
    _transactions = [];
    _documents = _storage.getDocuments();
    _isDemoModeActive = false;

    _recalculateScores();
    _generateInsights();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> enableDemoMode() async {
    _isLoading = true;
    notifyListeners();

    final demoUser = UserModel.defaultUser;
    
    final demoBusiness = BusinessModel(
      id: 'biz_demo',
      businessName: 'Ramesh Vegetable Store',
      businessType: 'Retail Trade',
      businessAge: 3,
      city: 'Pune',
      revenueRange: '₹25,000 – ₹50,000/month',
      registeredAt: DateTime.now().subtract(const Duration(days: 365)),
    );

    final demoDocs = [
      DocumentModel(
        id: 'doc_001',
        name: 'Aadhaar Card',
        type: DocumentType.aadhaar,
        status: DocumentStatus.verified,
        uploadDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
      DocumentModel(
        id: 'doc_002',
        name: 'PAN Card',
        type: DocumentType.pan,
        status: DocumentStatus.verified,
        uploadDate: DateTime.now().subtract(const Duration(days: 4)),
      ),
      DocumentModel(
        id: 'doc_003',
        name: 'Udyam Registration',
        type: DocumentType.udyam,
        status: DocumentStatus.verified,
        uploadDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
      DocumentModel(
        id: 'doc_004',
        name: 'GST Certificate',
        type: DocumentType.gst,
        status: DocumentStatus.verified,
        uploadDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      DocumentModel(
        id: 'doc_005',
        name: 'Bank Statement',
        type: DocumentType.bankStatement,
        status: DocumentStatus.verified,
        uploadDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    final now = DateTime.now();
    final demoTxs = [
      TransactionModel(
        id: 'tx_demo_001',
        amount: 4500,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Bank Import: GPay Settlement Ref 283819',
        date: now.subtract(const Duration(days: 1)),
        verificationBadge: VerificationBadge.bankImported,
        isBankImported: true,
        integrityHash: 'A5B3C2D1E0F9',
      ),
      TransactionModel(
        id: 'tx_demo_002',
        amount: 3200,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Bank Import: PhonePe Settlement Ref 902831',
        date: now.subtract(const Duration(days: 2)),
        verificationBadge: VerificationBadge.bankImported,
        isBankImported: true,
        integrityHash: '8C7D6E5F4B3A',
      ),
      TransactionModel(
        id: 'tx_demo_003',
        amount: 1500,
        type: TransactionType.expense,
        category: 'Stock / Inventory',
        description: 'Bank Import: Transfer to Pune Mandi Wholesale',
        date: now.subtract(const Duration(days: 3)),
        verificationBadge: VerificationBadge.bankImported,
        isBankImported: true,
        integrityHash: '1A2B3C4D5E6F',
      ),
      TransactionModel(
        id: 'tx_demo_004',
        amount: 2800,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Weekly bulk catering sale',
        date: now.subtract(const Duration(days: 4)),
        verificationBadge: VerificationBadge.ocrVerified,
      ),
      TransactionModel(
        id: 'tx_demo_005',
        amount: 500,
        type: TransactionType.expense,
        category: 'Transport',
        description: 'Auto delivery charges',
        date: now.subtract(const Duration(days: 5)),
        verificationBadge: VerificationBadge.manualEntry,
      ),
      TransactionModel(
        id: 'tx_demo_006',
        amount: 3900,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Bank Import: UPI GPay QR Receive',
        date: now.subtract(const Duration(days: 6)),
        verificationBadge: VerificationBadge.bankImported,
        isBankImported: true,
        integrityHash: 'F9E8D7C6B5A4',
      ),
      TransactionModel(
        id: 'tx_demo_007',
        amount: 1200,
        type: TransactionType.expense,
        category: 'Stock / Inventory',
        description: 'Purchase of fresh onions & potatoes',
        date: now.subtract(const Duration(days: 8)),
        verificationBadge: VerificationBadge.ocrVerified,
      ),
      TransactionModel(
        id: 'tx_demo_008',
        amount: 4100,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Bank Import: Paytm QR Settlement',
        date: now.subtract(const Duration(days: 10)),
        verificationBadge: VerificationBadge.bankImported,
        isBankImported: true,
        integrityHash: 'D3C2B1A0F9E8',
      ),
      TransactionModel(
        id: 'tx_demo_009',
        amount: 250,
        type: TransactionType.expense,
        category: 'Electricity',
        description: 'Shop lighting electricity',
        date: now.subtract(const Duration(days: 12)),
        verificationBadge: VerificationBadge.upiVerified,
      ),
      TransactionModel(
        id: 'tx_demo_010',
        amount: 3500,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Vegetable delivery to Hotel Royal',
        date: now.subtract(const Duration(days: 15)),
        verificationBadge: VerificationBadge.upiVerified,
      ),
      TransactionModel(
        id: 'tx_demo_011',
        amount: 4800,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Bank Import: NEFT Inward GPay',
        date: now.subtract(const Duration(days: 20)),
        verificationBadge: VerificationBadge.bankImported,
        isBankImported: true,
        integrityHash: '9E8D7C6B5A4F',
      ),
      TransactionModel(
        id: 'tx_demo_012',
        amount: 1800,
        type: TransactionType.expense,
        category: 'Stock / Inventory',
        description: 'Mandi wholesale vendor advance',
        date: now.subtract(const Duration(days: 25)),
        verificationBadge: VerificationBadge.bankImported,
        isBankImported: true,
        integrityHash: '3D2C1B0A9F8E',
      ),
    ];

    // Only save demo transactions and documents — do NOT overwrite the real
    // user/business in storage so they can be restored when demo is disabled.
    await _storage.saveDocuments(demoDocs);
    await _storage.saveTransactions(demoTxs);

    _transactions = demoTxs;
    _documents = demoDocs;
    _user = demoUser;
    _business = demoBusiness;

    _recalculateScores();
    _generateInsights();

    _isDemoModeActive = true;
    _isLoading = false;
    notifyListeners();
  }
}
