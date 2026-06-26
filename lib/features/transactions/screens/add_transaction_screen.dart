import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/upi_statement_parser.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/transaction_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';

enum _EntryMode { manual, voice, ocr, bankStatement }

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  TransactionType _txType = TransactionType.income;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  _EntryMode _entryMode = _EntryMode.manual;
  bool _isBusy = false;
  bool _isSaving = false;

  // Voice
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _voiceText = '';

  // OCR
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _speech.stop();
    super.dispose();
  }

  VerificationBadge get _verificationBadge {
    switch (_entryMode) {
      case _EntryMode.ocr:
        return VerificationBadge.ocrVerified;
      case _EntryMode.bankStatement:
        return VerificationBadge.bankImported;
      default:
        return VerificationBadge.manualEntry;
    }
  }

  List<String> _categories(L10n l10n) => _txType == TransactionType.income
      ? l10n.incomeCategories
      : l10n.expenseCategories;

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 10),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _save(L10n l10n) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnack(l10n.pleaseSelectCategory);
      return;
    }
    setState(() => _isSaving = true);
    await context.read<TransactionProvider>().addTransaction(
          amount: double.parse(_amountController.text),
          type: _txType,
          category: _selectedCategory!,
          description: _descController.text.trim(),
          date: _selectedDate,
          verificationBadge: _verificationBadge,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    final typeStr = _txType == TransactionType.income ? l10n.income : l10n.expense;
    _showSnack(
      '$typeStr ${l10n.ofText} ${AppFormatters.formatCurrency(double.parse(_amountController.text))} ${l10n.transactionAdded}',
      color: AppColors.success,
    );
    Navigator.of(context).pop();
  }

  // ── VOICE ──────────────────────────────────────────────────────────────────

  Future<void> _startListening(L10n l10n) async {
    if (!_speechAvailable) {
      _showSnack(l10n.pick(
        'Microphone not available on this device.',
        'इस डिवाइस पर माइक्रोफोन उपलब्ध नहीं है।',
        'या डिव्हाइसवर मायक्रोफोन उपलब्ध नाही.',
      ));
      return;
    }
    setState(() {
      _isListening = true;
      _voiceText = '';
    });
    await _speech.listen(
      onResult: (r) => setState(() => _voiceText = r.recognizedWords),
      listenOptions: stt.SpeechListenOptions(
        localeId: _localeForSpeech(
            context.read<OnboardingProvider>().selectedLanguage),
        pauseFor: const Duration(seconds: 30),
        listenFor: const Duration(minutes: 5),
      ),
    );
  }

  Future<void> _stopListeningAndParse(L10n l10n) async {
    // Capture provider before any await to avoid use_build_context_synchronously
    final provider = context.read<TransactionProvider>();
    await _speech.stop();
    setState(() => _isListening = false);
    if (_voiceText.trim().isEmpty) return;
    final parsed = provider.parseVoiceInput(_voiceText);
    if (parsed != null) {
      setState(() {
        _amountController.text =
            (parsed['amount'] as double).toStringAsFixed(0);
        _txType = parsed['type'] as TransactionType;
        _descController.text = parsed['description'] as String;
        _selectedCategory = _categories(l10n).first;
      });
    } else {
      _showSnack(l10n.voiceParseError);
    }
  }

  String _localeForSpeech(String lang) {
    switch (lang) {
      case 'hi':
        return 'hi_IN';
      case 'mr':
        return 'mr_IN';
      default:
        return 'en_IN';
    }
  }

  // ── OCR ────────────────────────────────────────────────────────────────────

  /// Let user pick from camera OR gallery so judges can use saved receipts too.
  Future<void> _pickAndScanImage(L10n l10n) async {
    // Ask user: camera or gallery?
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: Text(l10n.pick('Take a Photo', 'फ़ोटो लें', 'फोटो काढा'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: Text(l10n.pick('Choose from Gallery', 'गैलरी से चुनें', 'गॅलरीतून निवडा'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: source, imageQuality: 90);
    if (img == null) return;

    final imageFile = File(img.path);
    setState(() {
      _pickedImage = imageFile;
      _isBusy = true;
    });

    // ── Real ML Kit OCR call ──────────────────────────────────────────────────
    final result = await OcrService.instance.scanReceipt(imageFile);

    if (!mounted) return;

    if (!result.success) {
      setState(() => _isBusy = false);
      _showSnack(
        result.error ?? l10n.pick('OCR failed. Try a clearer image.', 'OCR विफल। स्पष्ट छवि आज़माएं।', 'OCR अयशस्वी. स्पष्ट प्रतिमा वापरा.'),
        color: AppColors.error,
      );
      return;
    }

    setState(() {
      _isBusy = false;
      // Fill description from receipt merchant/text
      _descController.text = result.description;
      // Auto-select first category
      _selectedCategory ??= _categories(l10n).first;
      // Fill amount only if OCR found one
      if (result.amount != null && result.amount! > 0) {
        _amountController.text = result.amount!.toStringAsFixed(2);
      }
    });

    if (result.amount != null && result.amount! > 0) {
      _showSnack(
        l10n.pick(
          'Receipt scanned! Amount: ₹${result.amount!.toStringAsFixed(2)} – verify and save.',
          'रसीद स्कैन हुई! राशि: ₹${result.amount!.toStringAsFixed(2)} – जांचें और सेव करें।',
          'पावती स्कॅन झाली! रक्कम: ₹${result.amount!.toStringAsFixed(2)} – तपासा आणि जतन करा.',
        ),
        color: AppColors.success,
      );
    } else {
      // Amount not found – ask user to enter it manually
      _showSnack(
        l10n.pick(
          'Receipt scanned but amount not detected. Please enter it manually.',
          'रसीद स्कैन हुई लेकिन राशि नहीं मिली। कृपया मैन्युअल दर्ज करें।',
          'पावती स्कॅन झाली पण रक्कम सापडली नाही. कृपया मॅन्युअली प्रविष्ट करा.',
        ),
        color: AppColors.warning,
      );
    }
  }


  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();
    final l10n = L10n.of(onboarding.selectedLanguage);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.addTransaction),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingXXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(l10n),
              const SizedBox(height: 20),
              _buildEntryModeSelector(l10n),
              const SizedBox(height: 20),
              if (_entryMode == _EntryMode.voice) _buildVoiceEntry(l10n),
              if (_entryMode == _EntryMode.ocr) _buildOcrEntry(l10n),
              if (_entryMode == _EntryMode.bankStatement)
                _buildBankStatementEntry(l10n)
              else ...[
                _buildLabel(l10n.amount),
                const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text('₹',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ),
                  hintText: '0',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.enterAmount;
                  if (double.tryParse(v) == null) return l10n.invalidAmount;
                  if (double.parse(v) <= 0) return l10n.amountPositive;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildLabel(l10n.descriptionLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(hintText: l10n.descHint),
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.enterDescription : null,
              ),
              const SizedBox(height: 20),
              _buildLabel(l10n.categoryLabel),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories(l10n).map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(cat,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _buildLabel(l10n.dateLabel),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingLG,
                      vertical: AppDimensions.paddingMD),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(AppFormatters.formatDate(_selectedDate),
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textPrimary)),
                  ]),
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: l10n.saveTransaction,
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: () => _save(l10n),
              ),
              ], // end of non-bankStatement fields
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(L10n l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        _buildTypeButton(TransactionType.income, l10n.income,
            Icons.arrow_downward_rounded, AppColors.primary),
        _buildTypeButton(TransactionType.expense, l10n.expense,
            Icons.arrow_upward_rounded, AppColors.error),
      ]),
    );
  }

  Widget _buildTypeButton(
      TransactionType type, String label, IconData icon, Color color) {
    final isSelected = _txType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _txType = type;
          _selectedCategory = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textTertiary)),
          ]),
        ),
      ),
    );
  }

  Widget _buildEntryModeSelector(L10n l10n) {
    final modes = [
      (_EntryMode.manual, '✏️', l10n.manual),
      (_EntryMode.voice, '🎤', l10n.voice),
      (_EntryMode.ocr, '📸', l10n.ocr),
      (_EntryMode.bankStatement, '🏦', l10n.pick('Bank\nStmt', 'बैंक\nस्टेटमेंट', 'बँक\nस्टेटमेंट')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.entryMethod),
        const SizedBox(height: 8),
        Row(
          children: modes.map((m) {
            final isSelected = _entryMode == m.$1;
            final isBank = m.$1 == _EntryMode.bankStatement;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _entryMode = m.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isBank ? const Color(0xFFFFFBEB) : AppColors.primarySurface)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? (isBank ? const Color(0xFFD97706) : AppColors.primary)
                          : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(children: [
                    Text(m.$2, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      m.$3,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? (isBank ? const Color(0xFFB45309) : AppColors.primary)
                            : AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── VOICE WIDGET ───────────────────────────────────────────────────────────
  Widget _buildVoiceEntry(L10n l10n) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
              color: _isListening ? AppColors.primary : AppColors.border,
              width: _isListening ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.mic_rounded,
                color: _isListening ? Colors.red : AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Text(l10n.voiceEntryTitle,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
            if (_isListening) ...[
              const SizedBox(width: 8),
              const _PulsingDot(),
            ],
          ]),
          const SizedBox(height: 8),
          Text(l10n.voiceEntryHint,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic)),
          if (_voiceText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_voiceText,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textPrimary)),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isListening
                    ? () => _stopListeningAndParse(l10n)
                    : () => _startListening(l10n),
                icon: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 16),
                label: Text(_isListening
                    ? l10n.pick('Stop & Parse', 'रोकें और पार्स करें', 'थांबा आणि पार्स करा')
                    : l10n.pick('Start Speaking', 'बोलना शुरू करें', 'बोलणे सुरू करा')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isListening ? Colors.red : AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 42),
                ),
              ),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
    ]);
  }

  // ── OCR WIDGET ─────────────────────────────────────────────────────────────
  Widget _buildOcrEntry(L10n l10n) {
    return Column(children: [
      GestureDetector(
        onTap: _isBusy ? null : () => _pickAndScanImage(l10n),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            if (_pickedImage != null && !_isBusy)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_pickedImage!,
                    height: 120, width: double.infinity, fit: BoxFit.cover),
              )
            else if (_isBusy)
              const CircularProgressIndicator(color: Color(0xFF7C3AED))
            else
              const Icon(Icons.document_scanner_rounded,
                  size: 48, color: Color(0xFF7C3AED)),
            const SizedBox(height: 8),
            Text(
              _isBusy
                  ? l10n.scanningReceipt
                  : (_pickedImage != null
                      ? l10n.pick('Tap to scan again', 'फिर से स्कैन करें', 'पुन्हा स्कॅन करा')
                      : l10n.tapToScanReceipt),
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7C3AED)),
            ),
            Text(l10n.aiExtractAmount,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
      ),
      const SizedBox(height: 16),
    ]);
  }


  // ── BANK STATEMENT WIDGET ──────────────────────────────────────────────────

  File? _statementImage;
  StatementParseResult? _lastParseResult;

  Future<void> _pickAndParseStatement(L10n l10n) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFFD97706)),
              title: Text(
                l10n.pick('Take Photo of Statement', 'स्टेटमेंट का फ़ोटो लें', 'स्टेटमेंटचा फोटो काढा'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFFD97706)),
              title: Text(
                l10n.pick('Choose from Gallery', 'गैलरी से चुनें', 'गॅलरीतून निवडा'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: source, imageQuality: 90);
    if (img == null) return;

    final imageFile = File(img.path);
    setState(() {
      _statementImage = imageFile;
      _isBusy = true;
      _lastParseResult = null;
    });

    final result = await UpiStatementParser.instance.parseStatementImage(imageFile);

    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _lastParseResult = result;
    });

    if (!result.success || result.transactions.isEmpty) {
      _showSnack(
        result.error ?? l10n.pick(
          'Could not read transactions from this image.',
          'इस छवि से लेनदेन नहीं पढ़ सके।',
          'या प्रतिमेतून व्यवहार वाचता आले नाहीत.',
        ),
        color: AppColors.error,
      );
      return;
    }

    // Show confirmation sheet
    if (!mounted) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatementConfirmSheet(
        result: result,
        l10n: l10n,
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    final provider = context.read<TransactionProvider>();
    final added = await provider.addBankImportedTransactions(result.transactions);
    if (!mounted) return;
    setState(() => _isSaving = false);

    _showSnack(
      l10n.pick(
        '$added transactions imported with 🏦 Bank Imported badge!',
        '$added लेनदेन 🏦 Bank Imported बैज के साथ आयात हुए!',
        '$added व्यवहार 🏦 Bank Imported बॅजसह आयात झाले!',
      ),
      color: AppColors.success,
    );
    Navigator.of(context).pop();
  }

  Widget _buildBankStatementEntry(L10n l10n) {
    return Column(children: [
      // Trust explanation banner
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(children: [
          const Text('🏦', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pick('Highest Trust Level', 'सर्वोच्च विश्वास स्तर', 'सर्वोच्च विश्वास पातळी'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
                Text(
                  l10n.pick(
                    'Transactions parsed from your actual bank statement — not manually typed.',
                    'आपके बैंक स्टेटमेंट से पार्स हुए लेनदेन — मैन्युअल नहीं।',
                    'तुमच्या बँक स्टेटमेंटमधून पार्स केलेले व्यवहार — मॅन्युअल नाही.',
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFB45309),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
      // Scan area
      GestureDetector(
        onTap: _isBusy ? null : () => _pickAndParseStatement(l10n),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
          ),
          child: Column(children: [
            if (_statementImage != null && !_isBusy)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_statementImage!,
                    height: 140, width: double.infinity, fit: BoxFit.cover),
              )
            else if (_isBusy)
              const CircularProgressIndicator(color: Color(0xFFD97706))
            else
              const Icon(Icons.account_balance_rounded, size: 48, color: Color(0xFFD97706)),
            const SizedBox(height: 8),
            Text(
              _isBusy
                  ? l10n.pick('AI is reading your statement…', 'AI स्टेटमेंट पढ़ रही है…', 'AI स्टेटमेंट वाचत आहे…')
                  : (_lastParseResult != null
                      ? l10n.pick('Tap to scan again', 'फिर से स्कैन करें', 'पुन्हा स्कॅन करा')
                      : l10n.pick('Tap to scan bank statement', 'बैंक स्टेटमेंट स्कैन करें', 'बँक स्टेटमेंट स्कॅन करा')),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD97706),
              ),
            ),
            if (_lastParseResult == null)
              Text(
                l10n.pick(
                  'PhonePe • Google Pay • Paytm • Bank passbook',
                  'PhonePe • Google Pay • Paytm • बैंक पासबुक',
                  'PhonePe • Google Pay • Paytm • बँक पासबुक',
                ),
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
            if (_lastParseResult != null && _lastParseResult!.success) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_lastParseResult!.transactions.length} transactions found',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 16),
    ]);
  }

  Widget _buildLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary));
}

// Small animated pulsing dot for recording indicator
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Statement Confirmation Sheet ───────────────────────────────────────────────

class _StatementConfirmSheet extends StatelessWidget {
  final StatementParseResult result;
  final L10n l10n;

  const _StatementConfirmSheet({
    required this.result,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final preview = result.transactions.take(5).toList();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Row(children: [
            const Text('🏦', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.pick('Ready to Import', 'आयात करने के लिए तैयार', 'आयात करण्यासाठी तयार'),
                    style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (result.bankName != null)
                    Text(
                      result.bankName!,
                      style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // Stats
          Row(children: [
            Expanded(
              child: _StatCard(
                label: l10n.pick('Credits', 'क्रेडिट', 'क्रेडिट'),
                value: '₹${result.totalCredits.toStringAsFixed(0)}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: l10n.pick('Debits', 'डेबिट', 'डेबिट'),
                value: '₹${result.totalDebits.toStringAsFixed(0)}',
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: l10n.pick('Transactions', 'लेनदेन', 'व्यवहार'),
                value: '${result.transactions.length}',
                color: const Color(0xFFD97706),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // Preview
          Text(
            l10n.pick('Preview (first 5)', 'पूर्वावलोकन (पहले 5)', 'पूर्वावलोकन (पहिले 5)'),
            style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...preview.map((tx) {
            final isExpense = tx['isExpense'] as bool? ?? false;
            final amount = (tx['amount'] as double);
            final desc = tx['description'] as String? ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: isExpense ? AppColors.errorSurface : AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 14,
                    color: isExpense ? AppColors.error : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    desc.length > 40 ? '${desc.substring(0, 40)}…' : desc,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${isExpense ? '-' : '+'}₹${amount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: isExpense ? AppColors.error : AppColors.primary,
                  ),
                ),
              ]),
            );
          }),
          if (result.transactions.length > 5)
            Text(
              '+ ${result.transactions.length - 5} more…',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
            ),
          const SizedBox(height: 20),
          // Buttons
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.pick('Cancel', 'रद्द करें', 'रद्द करा')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.download_done_rounded, size: 18),
                label: Text(
                  l10n.pick(
                    'Import All ${result.transactions.length}',
                    'सभी ${result.transactions.length} आयात करें',
                    'सर्व ${result.transactions.length} आयात करा',
                  ),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w800, color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10, color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
