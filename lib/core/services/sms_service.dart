import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();

  /// Requests SMS reading permission.
  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Checks if SMS permission is already granted.
  Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Fetches recent SMS messages and filters for those likely to be bank / UPI alerts.
  Future<List<SmsMessage>> fetchBankSms({int maxCount = 200}) async {
    final permissionGranted = await hasPermission();
    if (!permissionGranted) {
      throw Exception('SMS permission not granted.');
    }

    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: maxCount,
    );

    debugPrint('[SmsService] Total inbox messages fetched: ${messages.length}');

    final bankMessages = <SmsMessage>[];
    final now = DateTime.now();
    
    for (final message in messages) {
      // Only parse recent messages (last 24 hours) to avoid importing years of history
      if (message.date != null && now.difference(message.date!).inHours > 24) {
        continue;
      }

      final body = (message.body ?? '').toLowerCase();
      if (body.isEmpty) continue;

      // ── Currency signals ─────────────────────────────────────────────────
      final hasCurrency = body.contains('inr') ||
          body.contains('rs.') ||
          body.contains('rs ') ||
          body.contains('₹') ||
          body.contains('rupee');

      // ── Transaction action signals ────────────────────────────────────────
      final hasAction = body.contains('debited') ||
          body.contains('credited') ||
          body.contains('sent') ||
          body.contains('received') ||
          body.contains('paid') ||
          body.contains('deducted') ||
          body.contains('transferred') ||
          body.contains('deposited') ||
          body.contains('withdrawn');

      // ── Bank/UPI platform signals (even without currency) ─────────────────
      final isBankOrUpi = body.contains('a/c') ||
          body.contains('acct') ||
          body.contains('txn') ||
          body.contains('upi') ||
          body.contains('phonepay') ||
          body.contains('phonepe') ||
          body.contains('gpay') ||
          body.contains('paytm') ||
          body.contains('google pay') ||
          body.contains('imps') ||
          body.contains('neft') ||
          body.contains('rtgs') ||
          body.contains('ref no') ||
          body.contains('reference no') ||
          body.contains('avl bal') ||
          body.contains('avail bal') ||
          body.contains('available balance') ||
          body.contains('sbi') ||
          body.contains('hdfc') ||
          body.contains('icici') ||
          body.contains('axis bank') ||
          body.contains('kotak') ||
          body.contains('boi') ||
          body.contains('pnb') ||
          body.contains('canara');

      final isMatch = (hasCurrency && hasAction) || isBankOrUpi;

      if (isMatch) {
        bankMessages.add(message);
        debugPrint('[SmsService] Captured bank SMS: ${message.body?.substring(0, (message.body!.length).clamp(0, 60))}...');
      }
    }

    debugPrint('[SmsService] Bank SMS found: ${bankMessages.length}');
    return bankMessages;
  }
}
