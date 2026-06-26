import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/onboarding_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../passport/providers/passport_provider.dart';
import '../../ai_advisor/providers/ai_advisor_provider.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  const BusinessRegistrationScreen({super.key});

  @override
  State<BusinessRegistrationScreen> createState() =>
      _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState
    extends State<BusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  String? _selectedBusinessType;
  String? _selectedRevenueRange;
  int _currentStep = 0; // 0=Personal, 1=Business, 2=Set PIN

  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _businessNameController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  bool get _canProceedStep1 =>
      _ownerNameController.text.isNotEmpty &&
      _businessNameController.text.isNotEmpty &&
      _selectedBusinessType != null;

  bool get _canProceedStep2 =>
      _ageController.text.isNotEmpty &&
      _cityController.text.isNotEmpty &&
      _selectedRevenueRange != null;

  bool get _canProceedStep3 =>
      _phoneController.text.length == 10 &&
      _pinController.text.length == 4 &&
      _confirmPinController.text.length == 4 &&
      _pinController.text == _confirmPinController.text;

  Future<void> _submit() async {
    // Capture context-dependent objects before any await
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<OnboardingProvider>();
    final l10n = L10n.of(provider.selectedLanguage);
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    // Check PINs match
    if (_pinController.text != _confirmPinController.text) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.pick('PINs do not match. Please re-enter.', 'PIN मेल नहीं खाते। कृपया फिर से दर्ज करें।', 'PIN जुळत नाहीत. कृपया पुन्हा टाका.'))),
      );
      return;
    }

    // Save PIN
    final pinSaved = await provider.registerPin(phone: phone, pin: pin);
    if (!mounted) return;
    if (!pinSaved) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.error ?? l10n.pick('Registration failed', 'पंजीकरण विफल', 'नोंदणी अयशस्वी'))),
      );
      return;
    }

    // Save business details
    await provider.registerBusiness(
      phone: phone,
      ownerName: _ownerNameController.text.trim(),
      businessName: _businessNameController.text.trim(),
      businessType: _selectedBusinessType!,
      businessAge: int.parse(_ageController.text),
      city: _cityController.text.trim(),
      revenueRange: _selectedRevenueRange!,
    );

    // Reset in-memory providers so that the new account starts fresh
    if (mounted) {
      context.read<DashboardProvider>().reset();
      context.read<TransactionProvider>().reset();
      context.read<PassportProvider>().reset();
      context.read<AiAdvisorProvider>().reset();
    }

    if (!mounted) return;
    // Use pushReplacementNamed so /register is removed from the back stack.
    // Pressing back from /documents will go to /login, not back to PIN step.
    Navigator.of(context).pushReplacementNamed('/documents');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final l10n = L10n.of(provider.selectedLanguage);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.businessRegistration),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_currentStep > 0) {
              // Go to previous step within the form
              setState(() => _currentStep--);
            } else {
              // On first step: go back to the mobile login screen
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepper(l10n),
            const Divider(height: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentStep == 0
                    ? _buildStep1(l10n)
                    : _currentStep == 1
                        ? _buildStep2(provider, l10n)
                        : _buildStep3(provider, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(L10n l10n) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingXXL,
        vertical: AppDimensions.paddingMD,
      ),
      child: Row(
        children: [
          _buildStepIndicator(0, l10n.stepPersonal),
          _buildStepLine(0),
          _buildStepIndicator(1, l10n.stepBusiness),
          _buildStepLine(1),
          _buildStepIndicator(2, l10n.stepPin),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: _currentStep > afterStep ? AppColors.primaryGradient : null,
          color: _currentStep > afterStep ? null : AppColors.border,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? AppColors.primary
                : AppColors.surface,
            border: Border.all(
              color: isCompleted || isActive
                  ? AppColors.primary
                  : AppColors.border,
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.textTertiary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(L10n l10n) {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(AppDimensions.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pick('Tell us about yourself', 'अपने बारे में बताएं', 'स्वतःबद्दल सांगा'),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.pick('This information will appear on your VyaparSetu', 'यह जानकारी आपके VyaparSetu पर दिखेगी', 'ही माहिती तुमच्या VyaparSetu वर दिसेल'),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel('${l10n.fullName} *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ownerNameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.pick('e.g. Ramesh Kumar', 'उदा. रमेश कुमार', 'उदा. रमेश कुमार'),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel('${l10n.businessName} *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _businessNameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.pick('e.g. Ramesh Vegetables', 'उदा. रमेश सब्जियां', 'उदा. रमेश भाजीपाला'),
              prefixIcon: const Icon(Icons.store_outlined),
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel('${l10n.businessType} *'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedBusinessType,
            decoration: InputDecoration(
              hintText: l10n.pick('Select business type', 'व्यापार का प्रकार चुनें', 'व्यवसायाचा प्रकार निवडा'),
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            items: l10n.businessTypes
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type, style: GoogleFonts.inter(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedBusinessType = v),
          ),
          const SizedBox(height: 32),
          GradientButton(
            label: l10n.pick('Next: Business Details', 'आगे: व्यापार विवरण', 'पुढे: व्यवसाय तपशील'),
            icon: Icons.arrow_forward_rounded,
            onPressed: _canProceedStep1
                ? () => setState(() => _currentStep = 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(OnboardingProvider provider, L10n l10n) {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(AppDimensions.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.businessDetails,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.pick('Help us understand your business better', 'अपने व्यापार के बारे में बताएं', 'तुमच्या व्यवसायाबद्दल सांगा'),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('${l10n.businessAge} *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: l10n.pick('e.g. 3', 'उदा. 3', 'उदा. 3'),
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('${l10n.city} *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cityController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: l10n.pick('e.g. Mumbai', 'उदा. मुंबई', 'उदा. मुंबई'),
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLabel('${l10n.revenueRange} *'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedRevenueRange,
            decoration: InputDecoration(
              hintText: l10n.pick('Select monthly revenue', 'मासिक राजस्व चुनें', 'मासिक महसूल निवडा'),
              prefixIcon: const Icon(Icons.currency_rupee_outlined),
            ),
            items: l10n.revenueRanges
                .map(
                  (range) => DropdownMenuItem(
                    value: range,
                    child: Text(range, style: GoogleFonts.inter(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedRevenueRange = v),
          ),
          const SizedBox(height: 32),
          GradientButton(
            label: l10n.pick('Next: Set Your PIN', 'आगे: PIN सेट करें', 'पुढे: PIN सेट करा'),
            icon: Icons.arrow_forward_rounded,
            onPressed: _canProceedStep2
                ? () => setState(() => _currentStep = 2)
                : null,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back_rounded, size: 16),
                const SizedBox(width: 4),
                Text(l10n.pick('Back to Personal Info', 'वापस व्यक्तिगत जानकारी', 'वैयक्तिक माहितीकडे परत')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(OnboardingProvider provider, L10n l10n) {
    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(AppDimensions.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.setPin,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.pick('You\'ll use your mobile number + this PIN to log in every time', 'आप हर बार लॉगिन करने के लिए मोबाइल नंबर + PIN का उपयोग करेंगे', 'तुम्ही प्रत्येक वेळी मोबाइल नंबर + PIN वापरून लॉगिन कराल'),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Phone number
          _buildLabel('${l10n.mobileNumber} *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '98765 43210',
              counterText: '',
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Text(
                  '+91',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // PIN
          _buildLabel('${l10n.setPin} *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: _obscurePin,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 12,
            ),
            decoration: InputDecoration(
              hintText: '• • • •',
              counterText: '',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePin
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Confirm PIN
          _buildLabel('${l10n.confirmPin} *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: _obscureConfirm,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 12,
            ),
            decoration: InputDecoration(
              hintText: '• • • •',
              counterText: '',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              errorText: _confirmPinController.text.length == 4 &&
                      _pinController.text != _confirmPinController.text
                  ? 'PINs do not match'
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.pick('Your PIN is stored securely on your device. No internet needed to login.', 'आपका PIN आपके डिवाइस पर सुरक्षित रूप से संग्रहीत है। लॉगिन के लिए इंटरनेट की जरूरत नहीं।', 'तुमचा PIN तुमच्या डिव्हाइसवर सुरक्षितपणे साठवला आहे. लॉगिनसाठी इंटरनेट लागत नाही.'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          GradientButton(
            label: l10n.pick('Complete Registration', 'पंजीकरण पूरा करें', 'नोंदणी पूर्ण करा'),
            icon: Icons.check_circle_outline_rounded,
            isLoading: provider.isLoading,
            onPressed: _canProceedStep3 ? _submit : null,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _currentStep = 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back_rounded, size: 16),
                const SizedBox(width: 4),
                Text(l10n.pick('Back to Business Details', 'वापस व्यापार विवरण', 'व्यवसाय तपशीलाकडे परत')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
