import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/sms_service.dart';
import '../../core/services/account_aggregator_service.dart';
import '../../features/transactions/providers/transaction_provider.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';

class AccountSyncSheet extends StatefulWidget {
  const AccountSyncSheet({super.key});

  @override
  State<AccountSyncSheet> createState() => _AccountSyncSheetState();
}

class _AccountSyncSheetState extends State<AccountSyncSheet> {
  final SmsService _smsService = SmsService();
  bool _isProcessing = false;
  String _statusMessage = 'Connect your bank via SMS sync';
  IconData _statusIcon = Icons.account_balance;
  Color _statusColor = Colors.blue;

  Future<void> _startSync() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Requesting SMS permissions...';
      _statusIcon = Icons.security;
      _statusColor = Colors.orange;
    });

    try {
      final hasPerm = await _smsService.requestPermission();
      if (!hasPerm) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'SMS permission denied.';
          _statusIcon = Icons.error;
          _statusColor = Colors.red;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Scanning for bank alerts...';
        _statusIcon = Icons.sms;
      });

      final bankSms = await _smsService.fetchBankSms(maxCount: 200);

      if (bankSms.isEmpty) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'No recent bank alerts found.';
          _statusIcon = Icons.info;
          _statusColor = Colors.grey;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Found ${bankSms.length} bank alert(s). Analyzing with AI...';
        _statusIcon = Icons.auto_awesome;
        _statusColor = Colors.purple;
      });

      final parsedTransactions = await AccountAggregatorService.instance
          .parseTransactionsFromSms(bankSms);

      if (parsedTransactions.isEmpty) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'AI found no transactions in the ${bankSms.length} SMS(es). Check debug console for details.';
          _statusIcon = Icons.warning;
          _statusColor = Colors.amber;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Saving ${parsedTransactions.length} transactions...';
      });

      if (!mounted) return;
      
      final txProvider = Provider.of<TransactionProvider>(context, listen: false);
      await txProvider.addBankImportedTransactions(parsedTransactions);
      
      // Trigger dashboard recalculation
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      await dashboardProvider.load();

      setState(() {
        _isProcessing = false;
        _statusMessage = 'Sync Complete! Added ${parsedTransactions.length} txns.';
        _statusIcon = Icons.check_circle;
        _statusColor = Colors.green;
      });

      // Close sheet after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error during sync: \$e';
        _statusIcon = Icons.error;
        _statusColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon, size: 64, color: _statusColor),
          const SizedBox(height: 16),
          Text(
            'Account Aggregator Sync',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          if (_isProcessing)
            const CircularProgressIndicator()
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _startSync,
                icon: const Icon(Icons.sync),
                label: const Text('Start Secure Sync'),
              ),
            ),
        ],
      ),
    );
  }
}
