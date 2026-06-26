import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../models/transaction_model.dart';
import '../models/document_model.dart';

class VerificationBadgeWidget extends StatelessWidget {
  final VerificationBadge badge;
  final bool compact;

  const VerificationBadgeWidget({
    super.key,
    required this.badge,
    this.compact = false,
  });

  Color get _backgroundColor {
    switch (badge) {
      case VerificationBadge.bankImported:
        return const Color(0xFFFFFBEB); // amber-50
      case VerificationBadge.bankVerified:
        return AppColors.secondarySurface;
      case VerificationBadge.upiVerified:
        return AppColors.primarySurface;
      case VerificationBadge.ocrVerified:
        return const Color(0xFFEDE9FE);
      case VerificationBadge.manualEntry:
        return AppColors.surface;
    }
  }

  Color get _textColor {
    switch (badge) {
      case VerificationBadge.bankImported:
        return const Color(0xFFB45309); // amber-700
      case VerificationBadge.bankVerified:
        return AppColors.secondary;
      case VerificationBadge.upiVerified:
        return AppColors.primary;
      case VerificationBadge.ocrVerified:
        return const Color(0xFF7C3AED);
      case VerificationBadge.manualEntry:
        return AppColors.textTertiary;
    }
  }

  IconData get _icon {
    switch (badge) {
      case VerificationBadge.bankImported:
        return Icons.account_balance_wallet_rounded; // gold wallet icon
      case VerificationBadge.bankVerified:
        return Icons.account_balance_rounded;
      case VerificationBadge.upiVerified:
        return Icons.phone_android_rounded;
      case VerificationBadge.ocrVerified:
        return Icons.document_scanner_rounded;
      case VerificationBadge.manualEntry:
        return Icons.edit_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 10, color: _textColor),
            const SizedBox(width: 3),
            Text(
              badge.label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _textColor),
          const SizedBox(width: 4),
          Text(
            badge.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentStatusBadge extends StatelessWidget {
  final DocumentStatus status;

  const DocumentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case DocumentStatus.verified:
        bgColor = AppColors.primarySurface;
        textColor = AppColors.primary;
        icon = Icons.verified_rounded;
      case DocumentStatus.verifying:
        bgColor = AppColors.warningSurface;
        textColor = AppColors.warning;
        icon = Icons.hourglass_top_rounded;
      case DocumentStatus.pending:
        bgColor = AppColors.surface;
        textColor = AppColors.textTertiary;
        icon = Icons.upload_file_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == DocumentStatus.verifying)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          else
            Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
