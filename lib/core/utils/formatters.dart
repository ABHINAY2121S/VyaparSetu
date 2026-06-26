import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _currencyFormatterDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _dateFormatter = DateFormat('dd MMM yyyy');
  static final _dateTimeFormatter = DateFormat('dd MMM yyyy, hh:mm a');
  static final _shortDateFormatter = DateFormat('dd MMM');
  static final _monthYearFormatter = DateFormat('MMM yyyy');
  static final _timeFormatter = DateFormat('hh:mm a');

  /// Format amount as Indian Rupee
  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }

  /// Format amount as Indian Rupee with decimal
  static String formatCurrencyDecimal(double amount) {
    return _currencyFormatterDecimal.format(amount);
  }

  /// Format large numbers in K/L format
  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatCurrency(amount);
  }

  /// Format date as "15 Jan 2024"
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Format date time as "15 Jan 2024, 02:30 PM"
  static String formatDateTime(DateTime date) {
    return _dateTimeFormatter.format(date);
  }

  /// Format date as "15 Jan"
  static String formatShortDate(DateTime date) {
    return _shortDateFormatter.format(date);
  }

  /// Format as "Jan 2024"
  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }

  /// Format time as "02:30 PM"
  static String formatTime(DateTime date) {
    return _timeFormatter.format(date);
  }

  /// Format phone number
  static String formatPhone(String phone) {
    if (phone.length == 10) {
      return '${phone.substring(0, 5)} ${phone.substring(5)}';
    }
    return phone;
  }

  /// Format score as percentage string
  static String formatScore(double score) {
    return '${score.round()}';
  }

  /// Format percentage
  static String formatPercent(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  /// Get relative time string
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) {
      return formatDate(date);
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Format number with Indian numbering system
  static String formatIndian(double number) {
    final formatter = NumberFormat('#,##,###', 'en_IN');
    return formatter.format(number);
  }

  /// Truncate string with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Format hash for display (show first 8 + ... + last 4)
  static String formatHash(String hash) {
    if (hash.length <= 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 4)}';
  }
}
