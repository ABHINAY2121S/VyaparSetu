import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/identity_verification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/models/document_model.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/verification_badge_widget.dart';
import '../providers/onboarding_provider.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
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

    // Capture messenger before any await to avoid deactivated widget errors
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final localPath = result.files.single.path!;
      final imageFile = File(localPath);

      if (!mounted) return;
      setState(() => _uploading.add(doc.id));

      // Update to verifying status
      final verifyingDoc = doc.copyWith(status: DocumentStatus.verifying);
      _updateDocument(verifyingDoc);

      // 1. Call Identity Verification Service
      final provider = context.read<OnboardingProvider>();
      final userPhone = provider.user?.phone ?? '9999999999';
      
      final verificationResult = await IdentityVerificationService.instance.verifyDocument(
        imageFile,
        doc.type,
        userPhone,
      );

      if (!mounted) return;
      
      if (!verificationResult.success) {
        throw Exception(verificationResult.message);
      }

      // 2. Accept & Save Directly (No Dialog Pop-up)
      // Mark as verified with local file path (offline-first)
      final verifiedDoc = doc.copyWith(
        status: DocumentStatus.verified,
        uploadDate: DateTime.now(),
        filePath: localPath,
      );
      _updateDocument(verifiedDoc);

      // Save locally
      await _storage.saveDocuments(_documents);

      messenger.showSnackBar(
        SnackBar(content: Text('${doc.name} uploaded successfully!')),
      );
    } catch (e) {
      // Revert status to pending on error
      final pendingDoc = doc.copyWith(status: DocumentStatus.pending);
      if (mounted) _updateDocument(pendingDoc);

      String errorMsg = 'Failed to upload ${doc.name}';
      if (e is Exception) {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading.remove(doc.id));
      }
    }
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60, 
            child: Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13))
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary))
          ),
        ],
      ),
    );
  }

  void _updateDocument(DocumentModel updated) {
    final idx = _documents.indexWhere((d) => d.id == updated.id);
    if (idx != -1) {
      setState(() => _documents[idx] = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Upload Documents'),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await provider.completeOnboarding();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            },
            child: Text(
              'Skip',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Card
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(AppDimensions.paddingXXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Verification Progress',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$_verifiedCount / ${_documents.length} Verified',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 500),
                      widthFactor: _verificationPercent,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload more documents to increase your Confidence Score',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Document List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              itemCount: _documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return _buildDocumentCard(doc);
              },
            ),
          ),
          // Bottom action
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(AppDimensions.paddingXXL),
            child: GradientButton(
              label: 'Continue to Dashboard',
              icon: Icons.arrow_forward_rounded,
              onPressed: () async {
                await provider.completeOnboarding();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: doc.status == DocumentStatus.verified
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getDocIconBg(doc.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getDocIcon(doc.type),
                color: _getDocIconColor(doc.status),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Info
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isMandatory)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
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
                  const SizedBox(height: 2),
                  Text(
                    doc.type.description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DocumentStatusBadge(status: doc.status),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Upload button
            if (doc.status == DocumentStatus.pending)
              isUploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
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
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
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
                size: 24,
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
