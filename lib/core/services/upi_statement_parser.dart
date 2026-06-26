import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Parsed result from a bank/UPI statement scan.
class StatementParseResult {
  final bool success;
  final String? error;

  /// Detected bank or app name (e.g. "PhonePe", "SBI Bank").
  final String? bankName;

  /// Raw OCR text from the document.
  final String rawText;

  /// Structured list of transactions extracted by Gemini AI.
  final List<Map<String, dynamic>> transactions;

  /// Total credit amount detected across all transactions.
  final double totalCredits;

  /// Total debit amount detected across all transactions.
  final double totalDebits;

  const StatementParseResult({
    required this.success,
    this.error,
    this.bankName,
    required this.rawText,
    required this.transactions,
    this.totalCredits = 0,
    this.totalDebits = 0,
  });
}

/// Parses a bank or UPI statement image/PDF page using ML Kit OCR + Gemini AI.
///
/// Flow:
///   1. ML Kit OCR extracts raw text from the image.
///   2. Gemini AI parses the raw text into structured transaction records.
///   3. Result is returned as [StatementParseResult] with full transaction list.
class UpiStatementParser {
  UpiStatementParser._();
  static final UpiStatementParser instance = UpiStatementParser._();

  // Gemini API key — must be set at startup or via env.
  static String _apiKey = '';
  static void configure(String apiKey) => _apiKey = apiKey;

  // ── Public entry point ─────────────────────────────────────────────────────

  /// Scan [imageFile] (a photo of a bank/UPI statement page) and return
  /// structured transaction data.
  Future<StatementParseResult> parseStatementImage(File imageFile) async {
    // Step 1: OCR
    String rawText;
    try {
      rawText = await _extractTextFromImage(imageFile);
    } catch (e) {
      return StatementParseResult(
        success: false,
        error: 'OCR failed: $e',
        rawText: '',
        transactions: [],
      );
    }

    if (rawText.trim().isEmpty) {
      return const StatementParseResult(
        success: false,
        error: 'No text found in image. Please try a clearer photo of your bank statement.',
        rawText: '',
        transactions: [],
      );
    }

    // Step 2: Gemini AI parse
    return _parseWithGemini(rawText);
  }

  // ── OCR ───────────────────────────────────────────────────────────────────

  Future<String> _extractTextFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(inputImage);
      debugPrint('[UpiStatementParser] OCR raw text:\n${result.text}');
      return result.text;
    } finally {
      recognizer.close();
    }
  }

  // ── Gemini AI ─────────────────────────────────────────────────────────────

  Future<StatementParseResult> _parseWithGemini(String rawText) async {
    if (_apiKey.isEmpty) {
      // Fallback: regex-based extraction when API key not configured
      debugPrint('[UpiStatementParser] No API key — using regex fallback');
      return _regexFallback(rawText);
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = '''
You are a financial data extraction AI. I will give you raw OCR text from a bank statement or UPI payment app statement (PhonePe, Google Pay, Paytm, SBI, HDFC, etc.).

Extract ALL transactions from the text. For each transaction return a JSON object with these exact fields:
- "date": ISO 8601 date string (e.g. "2024-06-15") — if year is missing assume current year
- "description": short merchant or payment description (max 60 chars)
- "amount": number (positive, no currency symbol)
- "isExpense": boolean — true if money went OUT (debit/paid/withdrawn), false if money came IN (credit/received/deposited)
- "category": one of ["Sales", "Purchase", "Transfer", "Utility", "Salary", "Rent", "Food", "Transport", "Other"]

Return ONLY a valid JSON object with this structure:
{
  "bankName": "detected bank or app name or null",
  "transactions": [ ...array of transaction objects... ]
}

Do NOT include any explanation, markdown, or extra text. Only pure JSON.

RAW OCR TEXT:
$rawText
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      debugPrint('[UpiStatementParser] Gemini response:\n$responseText');

      return _parseGeminiResponse(responseText, rawText);
    } catch (e) {
      debugPrint('[UpiStatementParser] Gemini error: $e — falling back to regex');
      return _regexFallback(rawText);
    }
  }

  StatementParseResult _parseGeminiResponse(String responseText, String rawText) {
    // Strip markdown code fences if present
    String cleaned = responseText.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```[a-z]*\n?', multiLine: true), '')
          .replaceFirst(RegExp(r'\n?```$', multiLine: true), '')
          .trim();
    }

    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final bankName = json['bankName'] as String?;
      final rawList = json['transactions'] as List<dynamic>? ?? [];

      final transactions = rawList
          .whereType<Map<String, dynamic>>()
          .where((t) =>
              t['amount'] != null && (t['amount'] as num) > 0)
          .map((t) => {
                'date': t['date'] ?? DateTime.now().toIso8601String(),
                'description': (t['description'] ?? 'Bank Transaction').toString(),
                'amount': (t['amount'] as num).toDouble(),
                'isExpense': t['isExpense'] as bool? ?? false,
                'category': t['category'] as String? ?? 'Sales',
              })
          .toList();

      double credits = 0;
      double debits = 0;
      for (final t in transactions) {
        if (t['isExpense'] == true) {
          debits += (t['amount'] as double);
        } else {
          credits += (t['amount'] as double);
        }
      }

      return StatementParseResult(
        success: true,
        bankName: bankName,
        rawText: rawText,
        transactions: transactions,
        totalCredits: credits,
        totalDebits: debits,
      );
    } catch (e) {
      debugPrint('[UpiStatementParser] JSON parse error: $e');
      return _regexFallback(rawText);
    }
  }

  // ── Regex fallback (no Gemini) ─────────────────────────────────────────────

  /// Simple regex-based extraction for when Gemini is unavailable.
  /// Looks for lines with amounts and date-like patterns.
  StatementParseResult _regexFallback(String rawText) {
    final transactions = <Map<String, dynamic>>[];

    // Amount pattern: ₹1,234.56 or 1234.56 Cr/Dr
    final linePattern = RegExp(
      r'([\d]{1,2}[-/][\d]{1,2}[-/][\d]{2,4})?.*?([\d,]+\.?\d{0,2})\s*(Cr|Dr|CR|DR)?',
      caseSensitive: false,
    );

    double credits = 0;
    double debits = 0;

    for (final line in rawText.split('\n')) {
      final match = linePattern.firstMatch(line);
      if (match == null) continue;

      final amountStr = match.group(2)?.replaceAll(',', '');
      final amount = double.tryParse(amountStr ?? '');
      if (amount == null || amount < 1 || amount > 10000000) continue;

      // Skip obvious non-transaction lines (phone numbers, pin codes etc.)
      if (amount < 10) continue;

      final crDr = match.group(3)?.toUpperCase();
      final isExpense = crDr == 'DR';

      final description = line
          .replaceAll(RegExp(r'[\d,./₹]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (description.length < 3) continue;

      transactions.add({
        'date': DateTime.now().toIso8601String(),
        'description': description.length > 60
            ? description.substring(0, 60)
            : description,
        'amount': amount,
        'isExpense': isExpense,
        'category': isExpense ? 'Purchase' : 'Sales',
      });

      if (isExpense) {
        debits += amount;
      } else {
        credits += amount;
      }
    }

    return StatementParseResult(
      success: transactions.isNotEmpty,
      error: transactions.isEmpty
          ? 'Could not extract transactions from this image. Please try a clearer photo of your bank statement.'
          : null,
      rawText: rawText,
      transactions: transactions,
      totalCredits: credits,
      totalDebits: debits,
    );
  }
}
