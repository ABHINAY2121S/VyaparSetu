import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;
  final _uuid = const Uuid();

  List<TransactionModel> _transactions = [];
  TransactionType _filterType = TransactionType.income;
  bool _showAll = true;
  bool _isLoading = false;

  List<TransactionModel> get allTransactions => _transactions;
  TransactionType get filterType => _filterType;
  bool get showAll => _showAll;
  bool get isLoading => _isLoading;

  List<TransactionModel> get filteredTransactions {
    if (_showAll) return _transactions;
    return _transactions.where((t) => t.type == _filterType).toList();
  }

  List<TransactionModel> get incomeTransactions =>
      _transactions.where((t) => t.type == TransactionType.income).toList();

  List<TransactionModel> get expenseTransactions =>
      _transactions.where((t) => t.type == TransactionType.expense).toList();

  double get totalIncome =>
      incomeTransactions.fold(0, (s, t) => s + t.amount);

  double get totalExpense =>
      expenseTransactions.fold(0, (s, t) => s + t.amount);

  /// Number of bank-imported (highest-trust) transactions.
  int get bankImportedCount =>
      _transactions.where((t) => t.isBankImported).length;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _transactions = _storage.getTransactions();
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _transactions = [];
    _filterType = TransactionType.income;
    _showAll = true;
    _isLoading = false;
    notifyListeners();
  }

  void setFilter(TransactionType type) {
    _filterType = type;
    _showAll = false;
    notifyListeners();
  }

  void showAllTransactions() {
    _showAll = true;
    notifyListeners();
  }

  // ── Integrity Hash ─────────────────────────────────────────────────────────

  /// Generate a SHA-256 fingerprint for a transaction.
  /// Input = id|amount|date|description — any post-save edit breaks this hash.
  String _generateHash({
    required String id,
    required double amount,
    required DateTime date,
    required String description,
  }) {
    final payload =
        '$id|${amount.toStringAsFixed(2)}|${date.toIso8601String()}|$description';
    final bytes = utf8.encode(payload);
    return sha256.convert(bytes).toString();
  }

  /// Verify whether a stored transaction's hash matches its current fields.
  /// Returns true if intact, false if tampered / null hash.
  bool verifyIntegrity(TransactionModel tx) {
    if (tx.integrityHash == null) return false;
    final expected = _generateHash(
      id: tx.id,
      amount: tx.amount,
      date: tx.date,
      description: tx.description,
    );
    return tx.integrityHash == expected;
  }

  // ── Add / Delete ───────────────────────────────────────────────────────────

  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required String category,
    required String description,
    required DateTime date,
    required VerificationBadge verificationBadge,
    String? note,
  }) async {
    final id = _uuid.v4();
    final hash = _generateHash(
      id: id,
      amount: amount,
      date: date,
      description: description,
    );
    final transaction = TransactionModel(
      id: id,
      amount: amount,
      type: type,
      category: category,
      description: description,
      date: date,
      verificationBadge: verificationBadge,
      note: note,
      integrityHash: hash,
      isBankImported: false,
    );

    _transactions.insert(0, transaction);
    await _storage.saveTransactions(_transactions);
    notifyListeners();
  }

  /// Batch-insert transactions parsed from a bank / UPI statement PDF.
  /// These are stamped as [VerificationBadge.bankImported] and are immutable.
  Future<int> addBankImportedTransactions(
    List<Map<String, dynamic>> parsed,
  ) async {
    int added = 0;
    for (final entry in parsed) {
      final amount = (entry['amount'] as num?)?.toDouble();
      final description =
          entry['description'] as String? ?? 'Bank Transaction';
      final dateRaw = entry['date'];
      final isExpense = entry['isExpense'] as bool? ?? false;
      final type =
          isExpense ? TransactionType.expense : TransactionType.income;
      final category = entry['category'] as String? ?? 'Sales';

      if (amount == null || amount <= 0) continue;

      DateTime date;
      try {
        date = dateRaw is DateTime
            ? dateRaw
            : DateTime.parse(dateRaw.toString());
      } catch (_) {
        date = DateTime.now();
      }

      final id = _uuid.v4();
      final hash = _generateHash(
        id: id,
        amount: amount,
        date: date,
        description: description,
      );

      _transactions.insert(
        0,
        TransactionModel(
          id: id,
          amount: amount,
          type: type,
          category: category,
          description: description,
          date: date,
          verificationBadge: VerificationBadge.bankImported,
          integrityHash: hash,
          isBankImported: true,
        ),
      );
      added++;
    }

    if (added > 0) {
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      await _storage.saveTransactions(_transactions);
      notifyListeners();
    }
    return added;
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _storage.saveTransactions(_transactions);
    notifyListeners();
  }

  Map<String, double> getCategoryBreakdown(TransactionType type) {
    final txs = _transactions.where((t) => t.type == type).toList();
    final breakdown = <String, double>{};
    for (final tx in txs) {
      breakdown[tx.category] = (breakdown[tx.category] ?? 0) + tx.amount;
    }
    return breakdown;
  }

  // ── Voice entry parsing ────────────────────────────────────────────────────

  Map<String, dynamic>? parseVoiceInput(String input) {
    final lower = input.toLowerCase();

    double? amount;
    TransactionType? type;

    final amountPattern =
        RegExp(r'(\d+(?:,\d+)*(?:\.\d+)?)\s*(?:rupees?|rs\.?|₹)?');
    final amountMatch = amountPattern.firstMatch(lower);
    if (amountMatch != null) {
      final amountStr = amountMatch.group(1)!.replaceAll(',', '');
      amount = double.tryParse(amountStr);
    }

    if (lower.contains('sold') ||
        lower.contains('received') ||
        lower.contains('earned') ||
        lower.contains('income') ||
        lower.contains('sale') ||
        lower.contains('बिक्री') ||
        lower.contains('कमाई')) {
      type = TransactionType.income;
    } else if (lower.contains('bought') ||
        lower.contains('paid') ||
        lower.contains('purchased') ||
        lower.contains('expense') ||
        lower.contains('spent') ||
        lower.contains('खर्च')) {
      type = TransactionType.expense;
    } else {
      type = TransactionType.income;
    }

    if (amount != null) {
      return {
        'amount': amount,
        'type': type,
        'description': input,
      };
    }

    return null;
  }
}
