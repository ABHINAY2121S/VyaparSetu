enum TransactionType { income, expense }

// bankImported = parsed directly from a real bank/UPI statement PDF — highest trust
enum VerificationBadge { bankImported, bankVerified, upiVerified, ocrVerified, manualEntry }

extension TransactionTypeExt on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
    }
  }

  String get jsonValue {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
    }
  }

  static TransactionType fromJson(String value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        return TransactionType.income;
    }
  }
}

extension VerificationBadgeExt on VerificationBadge {
  String get label {
    switch (this) {
      case VerificationBadge.bankImported:
        return 'Bank Imported';
      case VerificationBadge.bankVerified:
        return 'Bank Verified';
      case VerificationBadge.upiVerified:
        return 'UPI Verified';
      case VerificationBadge.ocrVerified:
        return 'OCR Verified';
      case VerificationBadge.manualEntry:
        return 'Manual Entry';
    }
  }

  String get jsonValue {
    switch (this) {
      case VerificationBadge.bankImported:
        return 'bankImported';
      case VerificationBadge.bankVerified:
        return 'bankVerified';
      case VerificationBadge.upiVerified:
        return 'upiVerified';
      case VerificationBadge.ocrVerified:
        return 'ocrVerified';
      case VerificationBadge.manualEntry:
        return 'manualEntry';
    }
  }

  static VerificationBadge fromJson(String value) {
    switch (value) {
      case 'bankImported':
        return VerificationBadge.bankImported;
      case 'bankVerified':
        return VerificationBadge.bankVerified;
      case 'upiVerified':
        return VerificationBadge.upiVerified;
      case 'ocrVerified':
        return VerificationBadge.ocrVerified;
      default:
        return VerificationBadge.manualEntry;
    }
  }

  bool get isVerified => this != VerificationBadge.manualEntry;

  /// Highest trust: parsed from a real bank / UPI statement PDF.
  bool get isBankImported => this == VerificationBadge.bankImported;
}

class TransactionModel {
  final String id;
  final double amount;
  final TransactionType type;
  final String category;
  final String description;
  final DateTime date;
  final VerificationBadge verificationBadge;
  final String? note;

  /// SHA-256 hash of (id + amount + date + description) generated at save time.
  /// If this is non-null and doesn't match re-computed hash, data was tampered.
  final String? integrityHash;

  /// True when this transaction was auto-parsed from a bank/UPI statement PDF.
  /// These transactions cannot be edited by the user.
  final bool isBankImported;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    required this.verificationBadge,
    this.note,
    this.integrityHash,
    this.isBankImported = false,
  });

  /// Bank-imported transactions are immutable — their amount cannot be changed.
  bool get isImmutable => isBankImported || verificationBadge.isBankImported;

  TransactionModel copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? category,
    String? description,
    DateTime? date,
    VerificationBadge? verificationBadge,
    String? note,
    String? integrityHash,
    bool? isBankImported,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      verificationBadge: verificationBadge ?? this.verificationBadge,
      note: note ?? this.note,
      integrityHash: integrityHash ?? this.integrityHash,
      isBankImported: isBankImported ?? this.isBankImported,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type.jsonValue,
    'category': category,
    'description': description,
    'date': date.toIso8601String(),
    'verificationBadge': verificationBadge.jsonValue,
    'note': note,
    'integrityHash': integrityHash,
    'isBankImported': isBankImported,
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: TransactionTypeExt.fromJson(json['type'] as String),
        category: json['category'] as String,
        description: json['description'] as String,
        date: DateTime.parse(json['date'] as String),
        verificationBadge: VerificationBadgeExt.fromJson(
          json['verificationBadge'] as String? ?? 'manualEntry',
        ),
        note: json['note'] as String?,
        integrityHash: json['integrityHash'] as String?,
        isBankImported: json['isBankImported'] as bool? ?? false,
      );
}
