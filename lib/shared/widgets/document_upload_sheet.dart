import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/storage_service.dart';
import '../models/document_model.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import 'verification_badge_widget.dart';

class DocumentUploadSheet extends StatefulWidget {
  const DocumentUploadSheet({super.key});

  @override
  State<DocumentUploadSheet> createState() => _DocumentUploadSheetState();
}

class _DocumentUploadSheetState extends State<DocumentUploadSheet> {
  final StorageService _storage = StorageService.instance;
  List<DocumentModel> _documents = [];
  final Set<String> _uploading = {};

  @override
  void initState() {
    super.initState();
    _documents = _storage.getDocuments();
  }

  int get _verifiedCount =>
      _documents.where((d) => d.status == DocumentStatus.verified).length;

  double get _verificationPercent =>
      _documents.isEmpty ? 0 : _verifiedCount / _documents.length;

  Future<void> _uploadDocument(DocumentModel doc) async {
    if (doc.status != DocumentStatus.pending) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.single.path == null) return;

      final localPath = result.files.single.path!;

      if (!mounted) return;
      setState(() => _uploading.add(doc.id));

      final verifiedDoc = doc.copyWith(
        status: DocumentStatus.verified,
        uploadDate: DateTime.now(),
        filePath: localPath,
      );
      _updateDocument(verifiedDoc);
      _storage.saveDocuments(_documents);

      messenger.showSnackBar(
        SnackBar(
          content: Text('${doc.name} uploaded successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      final pendingDoc = doc.copyWith(status: DocumentStatus.pending);
      if (mounted) _updateDocument(pendingDoc);

      messenger.showSnackBar(
        SnackBar(content: Text('Failed to upload ${doc.name}')),
      );
    } finally {
      if (mounted) setState(() => _uploading.remove(doc.id));
    }
  }

  void _updateDocument(DocumentModel updated) {
    final idx = _documents.indexWhere((d) => d.id == updated.id);
    if (idx != -1) setState(() => _documents[idx] = updated);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingXXL,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Documents',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Improves your Confidence Score',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$_verifiedCount / ${_documents.length}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingXXL,
            ),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 500),
                  widthFactor: _verificationPercent,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Document list (scrollable)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingLG,
                8,
                AppDimensions.paddingLG,
                16,
              ),
              itemCount: _documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return _buildDocumentCard(doc);
              },
            ),
          ),

          // Done button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Refresh dashboard scores after uploads
                  context.read<DashboardProvider>().load();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel doc) {
    final isUploading = _uploading.contains(doc.id);
    final isMandatory = doc.type.isMandatory;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: doc.status == DocumentStatus.verified
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getDocIconBg(doc.status),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getDocIcon(doc.type),
                color: _getDocIconColor(doc.status),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doc.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMandatory)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorSurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Required',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  DocumentStatusBadge(status: doc.status),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (doc.status == DocumentStatus.pending)
              isUploading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: () => _uploadDocument(doc),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primarySurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Upload',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    )
            else if (doc.status == DocumentStatus.verified)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getDocIcon(DocumentType type) {
    switch (type) {
      case DocumentType.aadhaar:
        return Icons.badge_outlined;
      case DocumentType.pan:
        return Icons.credit_card_outlined;
      case DocumentType.udyam:
        return Icons.business_center_outlined;
      case DocumentType.gst:
        return Icons.receipt_long_outlined;
      case DocumentType.bankStatement:
        return Icons.account_balance_outlined;
      case DocumentType.passbook:
        return Icons.menu_book_outlined;
      case DocumentType.businessLicense:
        return Icons.verified_outlined;
    }
  }

  Color _getDocIconBg(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.verified:
        return AppColors.primarySurface;
      case DocumentStatus.verifying:
        return AppColors.warningSurface;
      case DocumentStatus.pending:
        return AppColors.surface;
    }
  }

  Color _getDocIconColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.verified:
        return AppColors.primary;
      case DocumentStatus.verifying:
        return AppColors.warning;
      case DocumentStatus.pending:
        return AppColors.textTertiary;
    }
  }
}
