import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of scanning a receipt image via ML Kit OCR.
class OcrResult {
  final double? amount;
  final String rawText;
  final String description;
  final bool success;
  final String? error;

  const OcrResult({
    this.amount,
    required this.rawText,
    required this.description,
    required this.success,
    this.error,
  });
}

class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  /// Scan [imageFile] with ML Kit and extract raw text for document verification.
  Future<String?> scanDocument(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognized = await textRecognizer.processImage(inputImage);
      final rawText = recognized.text;
      debugPrint('[OCR] Scanned Document Text:\n$rawText');
      if (rawText.trim().isEmpty) return null;
      return rawText;
    } catch (e) {
      debugPrint('[OCR] Failed to scan document: $e');
      return null;
    } finally {
      textRecognizer.close();
    }
  }

  /// Scan [imageFile] with ML Kit and extract amount + description from receipt.
  Future<OcrResult> scanReceipt(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognized =
          await textRecognizer.processImage(inputImage);
      final rawText = recognized.text;

      debugPrint('[OCR] Raw text:\n$rawText');

      if (rawText.trim().isEmpty) {
        return const OcrResult(
          rawText: '',
          description: '',
          success: false,
          error: 'No text found in the image. Please try a clearer photo.',
        );
      }

      final amount = _extractAmount(rawText);
      final description = _extractDescription(rawText);

      return OcrResult(
        amount: amount,
        rawText: rawText,
        description: description,
        success: true,
      );
    } catch (e) {
      return OcrResult(
        rawText: '',
        description: '',
        success: false,
        error: 'OCR failed: $e',
      );
    } finally {
      textRecognizer.close();
    }
  }

  /// Extracts the most likely "total amount" from receipt text.
  ///
  /// Strategy:
  /// 1. Look for lines with keywords like Total, Grand Total, Net Amount, etc.
  ///    followed by a number.
  /// 2. Fall back to finding all monetary values and picking the largest
  ///    (usually the total on receipts).
  double? _extractAmount(String text) {
    // ── Pass 1: look for labelled total lines ─────────────────────────────
    final totalKeywords = RegExp(
      r'(grand\s*total|net\s*(payable|amount|total)|total\s*(amount|payable|due|rs)?|amount\s*(paid|payable|due|total)?|subtotal|bill\s*(total|amount)|payable|due)',
      caseSensitive: false,
    );

    for (final line in text.split('\n')) {
      if (totalKeywords.hasMatch(line)) {
        final extracted = _parseFirstNumber(line);
        if (extracted != null && extracted > 0) return extracted;
      }
    }

    // ── Pass 2: collect all numbers, return largest ───────────────────────
    final allAmounts = _extractAllNumbers(text);
    if (allAmounts.isEmpty) return null;
    allAmounts.sort((a, b) => b.compareTo(a));
    return allAmounts.first;
  }

  double? _parseFirstNumber(String line) {
    // Match numbers like: 1,234.56 | 1234.56 | ₹1234 | Rs.1234 | 1234/-
    final pattern = RegExp(r'(?:₹|Rs\.?|INR)?\s*([\d,]+(?:\.\d{1,2})?)(?:\s*/-)?');
    final match = pattern.firstMatch(line);
    if (match == null) return null;
    final raw = match.group(1)!.replaceAll(',', '');
    return double.tryParse(raw);
  }

  List<double> _extractAllNumbers(String text) {
    final pattern = RegExp(
        r'(?:₹|Rs\.?|INR)?\s*([\d,]{1,10}(?:\.\d{1,2})?)(?:\s*/-)?',
        caseSensitive: false);
    final results = <double>[];
    for (final match in pattern.allMatches(text)) {
      final raw = match.group(1)!.replaceAll(',', '');
      final value = double.tryParse(raw);
      if (value != null && value >= 1 && value <= 10000000) {
        results.add(value);
      }
    }
    return results;
  }

  /// Tries to extract a merchant name or meaningful description from receipt.
  String _extractDescription(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Skip lines that look like amounts or dates only
    final meaningfulLines = lines.where((l) {
      final isOnlyNumber = RegExp(r'^[\d\s₹Rs.,/-]+$').hasMatch(l);
      final isDateOnly = RegExp(
              r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$')
          .hasMatch(l);
      return !isOnlyNumber && !isDateOnly && l.length > 3;
    }).toList();

    if (meaningfulLines.isEmpty) return 'Receipt scan';

    // Use first meaningful line as description (usually merchant name)
    final merchant = meaningfulLines.first.length > 40
        ? '${meaningfulLines.first.substring(0, 40)}...'
        : meaningfulLines.first;

    return 'Receipt: $merchant';
  }
}
