import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../shared/models/transaction_model.dart';

class AccountAggregatorService {
  AccountAggregatorService._();
  static final AccountAggregatorService instance = AccountAggregatorService._();

  static String _apiKey = '';
  static void configure(String apiKey) => _apiKey = apiKey;

  static const _batchSize = 15; // SMS per Gemini call — keeps tokens low

  /// Uses offline Regex to parse SMS messages into structured transactions.
  /// This completely bypasses Gemini quota limits and works instantly.
  Future<List<Map<String, dynamic>>> parseTransactionsFromSms(List<dynamic> smsMessagesRaw) async {
    if (smsMessagesRaw.isEmpty) return [];

    // Cast the dynamic list to the expected type to avoid importing flutter_sms_inbox directly here if we don't have to,
    // actually let's just assume they have .body and .date properties via dynamic or import it
    
    final allResults = <Map<String, dynamic>>[];

    // Regex patterns for common Indian bank SMS formats
    final amountRegExp = RegExp(r'(?:Rs\.?|INR)\s*([0-9,]+\.[0-9]{1,2}|[0-9,]+)', caseSensitive: false);
    final debitedAmountRegExp = RegExp(r'debited by\s*(?:Rs\.?)?\s*([0-9,]+\.[0-9]{1,2}|[0-9,]+)', caseSensitive: false);
    
    final debitKeywords = ['debited', 'paid', 'sent', 'deducted', 'withdrawn'];
    final creditKeywords = ['credited', 'received', 'added', 'refunded'];

    for (final smsObj in smsMessagesRaw) {
      final sms = (smsObj.body ?? '') as String;
      final smsDate = smsObj.date as DateTime?;
      final lowerSms = sms.toLowerCase();
      
      // Determine transaction type
      bool isExpense = false;
      bool isIncome = false;
      
      for (final kw in debitKeywords) {
        if (lowerSms.contains(kw)) isExpense = true;
      }
      for (final kw in creditKeywords) {
        if (lowerSms.contains(kw)) isIncome = true;
      }
      
      // Skip if it doesn't look like a clear transaction
      if (!isExpense && !isIncome) continue;
      
      // Extract amount
      String? amountStr;
      if (isExpense) {
        final match = debitedAmountRegExp.firstMatch(sms) ?? amountRegExp.firstMatch(sms);
        if (match != null) amountStr = match.group(1);
      } else {
        final match = amountRegExp.firstMatch(sms);
        if (match != null) amountStr = match.group(1);
      }
      
      if (amountStr == null) continue;
      
      final amount = double.tryParse(amountStr.replaceAll(',', ''));
      if (amount == null || amount <= 0) continue;
      
      final txDate = smsDate ?? DateTime.now();
      
      allResults.add({
        "date": txDate.toIso8601String(),
        "description": isExpense ? "Bank Debit" : "Bank Credit",
        "amount": amount,
        "isExpense": isExpense,
        "category": isExpense ? "Other" : "Sales",
      });
    }

    debugPrint('[AccountAggregatorService] Regex extracted: ${allResults.length} transactions from ${smsMessagesRaw.length} SMS');
    return allResults;
  }
}
