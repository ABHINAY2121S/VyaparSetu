/// Result of parsing a UPI transaction reference.
class UpiParseResult {
  /// Extracted amount if encoded in the reference (e.g. deep-link).
  final double? amount;

  /// Cleaned / normalized transaction ID / reference number.
  final String transactionId;

  /// Human readable description for the transaction.
  final String description;

  /// Whether parsing was successful (even if amount is null).
  final bool success;

  /// Error message when success == false.
  final String? error;

  /// Whether the user must manually enter the amount
  /// (true when no amount could be decoded from the ref string).
  final bool requiresManualAmount;

  const UpiParseResult({
    this.amount,
    required this.transactionId,
    required this.description,
    required this.success,
    this.error,
    this.requiresManualAmount = false,
  });
}

/// Service that parses UPI Transaction IDs / deep-links to extract details.
///
/// UPI transaction IDs (UTR numbers) are purely reference strings – they do NOT
/// publicly encode the transaction amount.  The real way to get the amount is:
///   a) Parse a UPI deep-link (upi://pay?…) which sometimes contains `am=`.
///   b) Ask the user to enter it manually (what most apps do).
///   c) Call a bank / payment-gateway API with proper credentials.
///
/// This service handles (a) and falls back gracefully to (b).
class UpiService {
  UpiService._();
  static final UpiService instance = UpiService._();

  /// Parse a raw UPI reference string.
  ///
  /// Accepts:
  ///   • Plain UTR / transaction IDs  (e.g. `T2506251234567`)
  ///   • UPI deep-links  (e.g. `upi://pay?pa=someone@upi&am=500&tn=Order123`)
  ///   • Google Pay / PhonePe share text  (e.g. "₹500 paid to XYZ Txn ID: 412…")
  UpiParseResult parse(String raw) {
    final input = raw.trim();

    if (input.isEmpty) {
      return const UpiParseResult(
        transactionId: '',
        description: '',
        success: false,
        error: 'Empty input. Please paste your UPI transaction ID or deep-link.',
      );
    }

    // ── 1. Try UPI deep-link ──────────────────────────────────────────────
    if (input.toLowerCase().startsWith('upi://') ||
        input.toLowerCase().startsWith('intent://') ||
        input.contains('pa=') ||
        input.contains('am=')) {
      return _parseDeepLink(input);
    }

    // ── 2. Try payment app share text ────────────────────────────────────
    final shareResult = _parseShareText(input);
    if (shareResult != null) return shareResult;

    // ── 3. Plain UTR / reference number ──────────────────────────────────
    return _parsePlainRef(input);
  }

  // ── Deep-link parser ──────────────────────────────────────────────────────

  UpiParseResult _parseDeepLink(String input) {
    try {
      // Normalize upi:// to https:// for Uri.parse
      final normalized = input
          .replaceFirst(RegExp(r'^upi://', caseSensitive: false), 'https://upi/')
          .replaceFirst(RegExp(r'^intent://', caseSensitive: false), 'https://intent/');

      final uri = Uri.tryParse(normalized);

      final am = uri?.queryParameters['am'];
      final tn = uri?.queryParameters['tn'] ?? uri?.queryParameters['note'];
      final pa = uri?.queryParameters['pa']; // payee address
      final pn = uri?.queryParameters['pn']; // payee name
      final tr = uri?.queryParameters['tr']; // transaction ref

      final amount = am != null ? double.tryParse(am) : null;
      final txId = tr ?? _extractUtrFromText(input) ?? input;
      final payee = pn ?? pa ?? 'UPI Payee';
      final note = tn ?? 'UPI Payment';
      final desc = 'Payment to $payee – $note (Ref: $txId)';

      return UpiParseResult(
        amount: amount,
        transactionId: txId,
        description: desc,
        success: true,
        requiresManualAmount: amount == null,
      );
    } catch (_) {
      return _parsePlainRef(input);
    }
  }

  // ── Payment app share-text parser ────────────────────────────────────────

  UpiParseResult? _parseShareText(String text) {
    // Patterns like:
    //   "₹500 paid to XYZ Store | Txn ID: T2506251234"
    //   "You paid Rs. 1,200 to ABC | UPI Ref: 412345678"
    //   "Payment of ₹350.00 successful. Transaction ID: 9876543210"

    final amountPattern = RegExp(
      r'(?:₹|Rs\.?|INR|paid|payment\s+of|you\s+paid)\s*[\s:]*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );

    final txnPattern = RegExp(
      r'(?:txn(?:\s*id)?|transaction\s*id|upi\s*ref(?:erence)?|ref(?:erence)?(?:\s*no)?)[:\s#]*([\w\d]+)',
      caseSensitive: false,
    );

    final amMatch = amountPattern.firstMatch(text);
    final txMatch = txnPattern.firstMatch(text);

    if (amMatch == null && txMatch == null) return null;

    final amountStr = amMatch?.group(1)?.replaceAll(',', '');
    final amount = amountStr != null ? double.tryParse(amountStr) : null;
    final txId = txMatch?.group(1) ?? _extractUtrFromText(text) ?? text;

    // Extract name if possible
    final namePattern = RegExp(
        r'(?:to|paid to|payment to)\s+([A-Za-z][A-Za-z\s]{2,30})',
        caseSensitive: false);
    final nameMatch = namePattern.firstMatch(text);
    final name = nameMatch?.group(1)?.trim() ?? 'UPI Payee';

    return UpiParseResult(
      amount: amount,
      transactionId: txId,
      description: 'Payment to $name (Ref: $txId)',
      success: true,
      requiresManualAmount: amount == null,
    );
  }

  // ── Plain UTR / transaction ID ────────────────────────────────────────────

  UpiParseResult _parsePlainRef(String input) {
    // Validate UTR format: typically 12-23 alphanumeric characters
    final cleanRef = input.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final isValidUtR = RegExp(r'^[A-Z0-9]{8,25}$').hasMatch(cleanRef);

    if (!isValidUtR) {
      return UpiParseResult(
        transactionId: input,
        description: '',
        success: false,
        error:
            'Invalid UPI ID format. Please enter a valid UTR number or paste the transaction details.',
      );
    }

    return UpiParseResult(
      transactionId: cleanRef,
      description: 'UPI Payment – Ref: $cleanRef',
      success: true,
      requiresManualAmount: true, // UTR alone never contains amount
    );
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String? _extractUtrFromText(String text) {
    // UTR numbers: 12-22 digit numbers or alphanumeric refs
    final utrPattern = RegExp(r'\b([A-Z0-9]{10,22})\b');
    final match = utrPattern.firstMatch(text.toUpperCase());
    return match?.group(1);
  }
}
