import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/business_model.dart';
import '../../shared/models/transaction_model.dart';
import '../../shared/models/document_model.dart';
import '../../shared/models/passport_model.dart';
import '../../shared/models/chat_message_model.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _keyUser = 'user';
  static const _keyBusiness = 'business';
  static const _keyTransactions = 'transactions';
  static const _keyDocuments = 'documents';
  static const _keyPassports = 'passports';
  static const _keyChatHistory = 'chat_history';
  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keySelectedLanguage = 'selected_language';
  static const _keyRegisteredPhone = 'registered_phone';
  static const _keyPinPrefix = 'pin_'; // pin_<phone> = hashed pin

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Onboarding ──────────────────────────────────────────────────────────

  bool get isOnboardingComplete =>
      _prefs.getBool(_keyOnboardingComplete) ?? false;

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(_keyOnboardingComplete, value);
  }

  String get selectedLanguage => _prefs.getString(_keySelectedLanguage) ?? 'en';

  Future<void> setSelectedLanguage(String lang) async {
    await _prefs.setString(_keySelectedLanguage, lang);
  }

  // ── PIN Auth ──────────────────────────────────────────────────────────────

  String? get registeredPhone => _prefs.getString(_keyRegisteredPhone);

  Future<void> saveRegisteredPhone(String phone) async {
    await _prefs.setString(_keyRegisteredPhone, phone);
  }

  /// Saves a 4-digit PIN for the given phone number (stored as plain string).
  Future<void> savePin(String phone, String pin) async {
    await _prefs.setString('$_keyPinPrefix$phone', pin);
  }

  /// Returns true if the PIN matches the stored PIN for the phone number.
  bool verifyPin(String phone, String pin) {
    final stored = _prefs.getString('$_keyPinPrefix$phone');
    return stored != null && stored == pin;
  }

  /// Returns true if a PIN has been set for the given phone number.
  bool hasPin(String phone) {
    return _prefs.containsKey('$_keyPinPrefix$phone');
  }

  // ── User ─────────────────────────────────────────────────────────────────


  UserModel? getUser() {
    final phone = registeredPhone;
    if (phone == null) return null;
    final json = _prefs.getString('${_keyUser}_$phone');
    if (json == null) return null;
    return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveUser(UserModel user) async {
    await _prefs.setString('${_keyUser}_${user.phone}', jsonEncode(user.toJson()));
  }

  // ── Business ─────────────────────────────────────────────────────────────

  BusinessModel? getBusiness() {
    final phone = registeredPhone;
    if (phone == null) return null;
    final json = _prefs.getString('${_keyBusiness}_$phone');
    if (json == null) return null;
    return BusinessModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveBusiness(BusinessModel business) async {
    final phone = registeredPhone;
    if (phone != null) {
      await _prefs.setString('${_keyBusiness}_$phone', jsonEncode(business.toJson()));
    }
  }

  // ── Transactions ─────────────────────────────────────────────────────────

  /// Returns saved transactions.
  /// Registered users start with an empty list (clean slate).
  /// Only the pre-login preview screen uses seed data.
  List<TransactionModel> getTransactions() {
    final phone = registeredPhone;
    if (phone == null) {
      return _getSeedTransactions();
    }
    final json = _prefs.getString('${_keyTransactions}_$phone');
    if (json == null) {
      return [];
    }
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final phone = registeredPhone;
    if (phone != null) {
      await _prefs.setString(
        '${_keyTransactions}_$phone',
        jsonEncode(transactions.map((t) => t.toJson()).toList()),
      );
    }
  }

  /// Removes all saved transactions so the next [getTransactions] call
  /// falls back to the seed data (used when disabling demo mode).
  Future<void> clearTransactions() async {
    final phone = registeredPhone;
    if (phone != null) {
      await _prefs.remove('${_keyTransactions}_$phone');
    }
  }

  // ── Documents ─────────────────────────────────────────────────────────────

  /// Returns saved documents.
  /// Registered users start with all documents in pending state (clean slate).
  /// Only the pre-login preview screen uses the pre-verified demo documents.
  List<DocumentModel> getDocuments() {
    final phone = registeredPhone;
    if (phone == null) {
      return _getDefaultDocuments();
    }
    final json = _prefs.getString('${_keyDocuments}_$phone');
    if (json == null) {
      return _getEmptyDocuments();
    }
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveDocuments(List<DocumentModel> documents) async {
    final phone = registeredPhone;
    if (phone != null) {
      await _prefs.setString(
        '${_keyDocuments}_$phone',
        jsonEncode(documents.map((d) => d.toJson()).toList()),
      );
    }
  }

  /// Removes all saved documents so the next [getDocuments] call falls back
  /// to the default seeded docs (used when disabling judge demo mode).
  Future<void> clearDocuments() async {
    final phone = registeredPhone;
    if (phone != null) {
      await _prefs.remove('${_keyDocuments}_$phone');
    }
  }

  // ── Passports ─────────────────────────────────────────────────────────────

  List<PassportModel> getPassports() {
    final phone = registeredPhone;
    if (phone == null) return [];
    final json = _prefs.getString('${_keyPassports}_$phone');
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => PassportModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePassports(List<PassportModel> passports) async {
    final phone = registeredPhone;
    if (phone != null) {
      await _prefs.setString(
        '${_keyPassports}_$phone',
        jsonEncode(passports.map((p) => p.toJson()).toList()),
      );
    }
  }

  /// Removes all saved passports (called on new registration).
  Future<void> clearPassports() async {
    final phone = registeredPhone;
    if (phone != null) {
      await _prefs.remove('${_keyPassports}_$phone');
    }
  }

  // ── Chat History ──────────────────────────────────────────────────────────

  List<ChatMessageModel> getChatHistory() {
    final phone = registeredPhone;
    if (phone == null) return [];
    final json = _prefs.getString('${_keyChatHistory}_$phone');
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveChatHistory(List<ChatMessageModel> messages) async {
    final phone = registeredPhone;
    if (phone != null) {
      final toSave = messages.length > 50
          ? messages.sublist(messages.length - 50)
          : messages;
      await _prefs.setString(
        '${_keyChatHistory}_$phone',
        jsonEncode(toSave.map((m) => m.toJson()).toList()),
      );
    }
  }

  /// Removes all saved chat history (called on new registration).
  Future<void> clearChatHistory() async {
    final phone = registeredPhone;
    if (phone != null) {
      await _prefs.remove('${_keyChatHistory}_$phone');
    }
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  Future<void> clearUser() async {
    final phone = registeredPhone;
    if (phone != null) {
      await _prefs.remove('${_keyUser}_$phone');
    }
  }

  Future<void> clearBusiness() async {
    final phone = registeredPhone;
    if (phone != null) {
      await _prefs.remove('${_keyBusiness}_$phone');
    }
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // ── Seed Data ─────────────────────────────────────────────────────────────

  List<TransactionModel> _getSeedTransactions() {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: 'tx_001',
        amount: 2500,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Vegetable sales - Morning',
        date: now.subtract(const Duration(days: 0)),
        verificationBadge: VerificationBadge.upiVerified,
      ),
      TransactionModel(
        id: 'tx_002',
        amount: 800,
        type: TransactionType.expense,
        category: 'Stock / Inventory',
        description: 'Wholesale vegetables purchase',
        date: now.subtract(const Duration(days: 1)),
        verificationBadge: VerificationBadge.manualEntry,
      ),
      TransactionModel(
        id: 'tx_003',
        amount: 3200,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Weekend market sales',
        date: now.subtract(const Duration(days: 2)),
        verificationBadge: VerificationBadge.upiVerified,
      ),
      TransactionModel(
        id: 'tx_004',
        amount: 150,
        type: TransactionType.expense,
        category: 'Transport',
        description: 'Auto to market',
        date: now.subtract(const Duration(days: 3)),
        verificationBadge: VerificationBadge.manualEntry,
      ),
      TransactionModel(
        id: 'tx_005',
        amount: 1800,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Regular daily sales',
        date: now.subtract(const Duration(days: 4)),
        verificationBadge: VerificationBadge.bankVerified,
      ),
      TransactionModel(
        id: 'tx_006',
        amount: 2100,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Fruit sales',
        date: now.subtract(const Duration(days: 5)),
        verificationBadge: VerificationBadge.upiVerified,
      ),
      TransactionModel(
        id: 'tx_007',
        amount: 500,
        type: TransactionType.expense,
        category: 'Electricity',
        description: 'Monthly electricity bill',
        date: now.subtract(const Duration(days: 7)),
        verificationBadge: VerificationBadge.bankVerified,
      ),
      TransactionModel(
        id: 'tx_008',
        amount: 2800,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Bulk order delivery',
        date: now.subtract(const Duration(days: 8)),
        verificationBadge: VerificationBadge.ocrVerified,
      ),
      TransactionModel(
        id: 'tx_009',
        amount: 1200,
        type: TransactionType.expense,
        category: 'Stock / Inventory',
        description: 'Stock replenishment',
        date: now.subtract(const Duration(days: 10)),
        verificationBadge: VerificationBadge.manualEntry,
      ),
      TransactionModel(
        id: 'tx_010',
        amount: 1950,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Daily earnings',
        date: now.subtract(const Duration(days: 11)),
        verificationBadge: VerificationBadge.upiVerified,
      ),
      TransactionModel(
        id: 'tx_011',
        amount: 2400,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Market day sales',
        date: now.subtract(const Duration(days: 14)),
        verificationBadge: VerificationBadge.bankVerified,
      ),
      TransactionModel(
        id: 'tx_012',
        amount: 3000,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Festival season boost',
        date: now.subtract(const Duration(days: 20)),
        verificationBadge: VerificationBadge.upiVerified,
      ),
      TransactionModel(
        id: 'tx_013',
        amount: 900,
        type: TransactionType.expense,
        category: 'Miscellaneous',
        description: 'Packing materials',
        date: now.subtract(const Duration(days: 22)),
        verificationBadge: VerificationBadge.manualEntry,
      ),
      TransactionModel(
        id: 'tx_014',
        amount: 2200,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Regular sales',
        date: now.subtract(const Duration(days: 25)),
        verificationBadge: VerificationBadge.upiVerified,
      ),
      TransactionModel(
        id: 'tx_015',
        amount: 1700,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Morning sales',
        date: now.subtract(const Duration(days: 30)),
        verificationBadge: VerificationBadge.bankVerified,
      ),
      TransactionModel(
        id: 'tx_016',
        amount: 2600,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Vegetable sales - Previous month',
        date: now.subtract(const Duration(days: 35)),
        verificationBadge: VerificationBadge.upiVerified,
      ),
      TransactionModel(
        id: 'tx_017',
        amount: 800,
        type: TransactionType.expense,
        category: 'Stock / Inventory',
        description: 'Monthly stock purchase',
        date: now.subtract(const Duration(days: 38)),
        verificationBadge: VerificationBadge.manualEntry,
      ),
      TransactionModel(
        id: 'tx_018',
        amount: 1900,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Daily sales',
        date: now.subtract(const Duration(days: 42)),
        verificationBadge: VerificationBadge.upiVerified,
      ),
      TransactionModel(
        id: 'tx_019',
        amount: 2300,
        type: TransactionType.income,
        category: 'Sales Revenue',
        description: 'Market sales',
        date: now.subtract(const Duration(days: 48)),
        verificationBadge: VerificationBadge.bankVerified,
      ),
      TransactionModel(
        id: 'tx_020',
        amount: 600,
        type: TransactionType.expense,
        category: 'Transport',
        description: 'Month transport costs',
        date: now.subtract(const Duration(days: 50)),
        verificationBadge: VerificationBadge.manualEntry,
      ),
    ];
  }

  /// Mock documents for demo/preview mode (no account).
  List<DocumentModel> _getDefaultDocuments() {
    return [
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
        status: DocumentStatus.verifying,
        uploadDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      const DocumentModel(
        id: 'doc_004',
        name: 'GST Certificate',
        type: DocumentType.gst,
        status: DocumentStatus.pending,
      ),
      const DocumentModel(
        id: 'doc_005',
        name: 'Bank Statement',
        type: DocumentType.bankStatement,
        status: DocumentStatus.pending,
      ),
      const DocumentModel(
        id: 'doc_006',
        name: 'Bank Passbook',
        type: DocumentType.passbook,
        status: DocumentStatus.pending,
      ),
      const DocumentModel(
        id: 'doc_007',
        name: 'Business License',
        type: DocumentType.businessLicense,
        status: DocumentStatus.pending,
      ),
    ];
  }

  /// Fresh empty document list for a newly registered account.
  /// All documents start as pending — the user has not uploaded anything yet.
  List<DocumentModel> _getEmptyDocuments() {
    return [
      const DocumentModel(
        id: 'doc_001',
        name: 'Aadhaar Card',
        type: DocumentType.aadhaar,
        status: DocumentStatus.pending,
      ),
      const DocumentModel(
        id: 'doc_002',
        name: 'PAN Card',
        type: DocumentType.pan,
        status: DocumentStatus.pending,
      ),
      const DocumentModel(
        id: 'doc_003',
        name: 'Udyam Registration',
        type: DocumentType.udyam,
        status: DocumentStatus.pending,
      ),
      const DocumentModel(
        id: 'doc_004',
        name: 'GST Certificate',
        type: DocumentType.gst,
        status: DocumentStatus.pending,
      ),
      const DocumentModel(
        id: 'doc_005',
        name: 'Bank Statement',
        type: DocumentType.bankStatement,
        status: DocumentStatus.pending,
      ),
      const DocumentModel(
        id: 'doc_006',
        name: 'Bank Passbook',
        type: DocumentType.passbook,
        status: DocumentStatus.pending,
      ),
      const DocumentModel(
        id: 'doc_007',
        name: 'Business License',
        type: DocumentType.businessLicense,
        status: DocumentStatus.pending,
      ),
    ];
  }
}
