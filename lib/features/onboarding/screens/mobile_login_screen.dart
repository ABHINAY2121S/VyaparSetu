import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/onboarding_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../passport/providers/passport_provider.dart';
import '../../ai_advisor/providers/ai_advisor_provider.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Shake animation for wrong PIN
  late AnimationController _shakeController;

  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _pinFocus = FocusNode();

  bool _showPin = false;
  bool _obscurePin = true;
  bool _phoneError = false;
  bool _pinError = false;
  String? _phoneErrorMsg;
  String? _pinErrorMsg;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Try biometric immediately if returning user has it enabled
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometricIfAvailable());
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _phoneFocus.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  // ── Biometric auto-trigger ──────────────────────────────────────────────
  Future<void> _tryBiometricIfAvailable() async {
    final provider = context.read<OnboardingProvider>();
    final phone = provider.user?.phone ??
        provider.business?.id.replaceAll('biz_', '') ?? '';
    final storedPhone = StorageService.instance.registeredPhone ?? '';
    final activePhone = storedPhone.isNotEmpty ? storedPhone : phone;
    if (activePhone.isEmpty) return;
    if (!provider.biometricAvailable) return;
    if (!provider.isBiometricEnabled(activePhone)) return;

    // Pre-fill phone for UX clarity
    _phoneController.text = activePhone;

    final ok = await provider.authenticateWithBiometric();
    if (!mounted) return;
    if (ok) {
      await provider.setActivePhone(activePhone);
      if (!mounted) return;
      await _finishLogin(provider, activePhone);
    }
  }

  // ── After phone typed — check if registered ────────────────────────────
  void _checkPhone() {
    final phone = _phoneController.text.trim();
    final l10n = L10n.of(context.read<OnboardingProvider>().selectedLanguage);
    if (phone.length != 10) {
      setState(() {
        _phoneError = true;
        _phoneErrorMsg = l10n.validMobileErr;
      });
      return;
    }
    setState(() {
      _phoneError = false;
      _phoneErrorMsg = null;
      _showPin = true;
    });
    _pinFocus.requestFocus();
  }

  // ── PIN auto-submits when 4 digits typed ───────────────────────────────
  void _onPinChanged(String value) {
    setState(() {
      _pinError = false;
      _pinErrorMsg = null;
    });
    if (value.length == 4) {
      _login();
    }
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    final provider = context.read<OnboardingProvider>();
    final l10n = L10n.of(provider.selectedLanguage);

    if (pin.length != 4) return;

    final success = await provider.loginWithPin(phone: phone, pin: pin);

    if (!mounted) return;

    if (success) {
      // Offer biometric opt-in after first successful PIN login
      final biometricAvailable = provider.biometricAvailable;
      final alreadyEnabled = provider.isBiometricEnabled(phone);
      if (biometricAvailable && !alreadyEnabled) {
        await _showBiometricOptIn(phone, provider);
        if (!mounted) return;
      }
      await _finishLogin(provider, phone);
    } else {
      // Shake + inline error
      _pinController.clear();
      setState(() {
        _pinError = true;
        _pinErrorMsg = provider.error ?? l10n.loginFailed;
      });
      _shakeController.forward(from: 0);
    }
  }

  Future<void> _finishLogin(OnboardingProvider provider, String phone) async {
    final nav = Navigator.of(context);
    if (provider.business != null) {
      if (mounted) {
        context.read<DashboardProvider>().reset();
        context.read<TransactionProvider>().reset();
        context.read<PassportProvider>().reset();
        context.read<AiAdvisorProvider>().reset();
      }
      await provider.completeOnboarding();
      if (!mounted) return;
      nav.pushReplacementNamed('/home');
    } else {
      nav.pushNamed('/register');
    }
  }

  // ── Biometric opt-in bottom sheet ──────────────────────────────────────
  Future<void> _showBiometricOptIn(
    String phone,
    OnboardingProvider provider,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BiometricOptInSheet(
        onEnable: () async {
          Navigator.pop(context);
          await provider.setBiometricEnabled(phone, true);
        },
        onSkip: () => Navigator.pop(context),
      ),
    );
  }

  // ── Fingerprint manual button (if not auto-triggered) ─────────────────
  Future<void> _triggerBiometric() async {
    final provider = context.read<OnboardingProvider>();
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() {
        _phoneError = true;
        _phoneErrorMsg = 'Enter your mobile number first';
      });
      return;
    }
    final ok = await provider.authenticateWithBiometric();
    if (!mounted) return;
    if (ok) {
      // Load the user profile for this phone then go home
      final hasAccount = provider.isRegistered(phone);
      if (!hasAccount) {
        setState(() {
          _pinError = true;
          _pinErrorMsg = 'No account found for this number';
        });
        return;
      }
      // Set registered phone session so getUser/getBusiness work
      await provider.setActivePhone(phone);
      if (!mounted) return;
      await _finishLogin(provider, phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final l10n = L10n.of(provider.selectedLanguage);
    final hasBiometric = provider.biometricAvailable;
    final phone = _phoneController.text.trim();
    final biometricEnabled = phone.length == 10
        ? provider.isBiometricEnabled(phone)
        : false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_showPin) {
              setState(() {
                _showPin = false;
                _pinController.clear();
                _pinError = false;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingXXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Title
                Text(
                  _showPin ? l10n.enterPin : l10n.enterMobile,
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _showPin
                      ? l10n.pick(
                          'Enter your 4-digit PIN',
                          '4-अंकी PIN दर्ज करें',
                          '4 अंकी PIN टाका',
                        )
                      : l10n.pick(
                          'Enter your registered mobile number',
                          'अपना पंजीकृत मोबाइल नंबर दर्ज करें',
                          'नोंदणीकृत मोबाइल नंबर टाका',
                        ),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Phone Field ───────────────────────────────────────
                AnimatedOpacity(
                  opacity: _showPin ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mobileNumber,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        enabled: !_showPin,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {
                          _phoneError = false;
                        }),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          hintText: '98765 43210',
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
                          counterText: '',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _phoneError
                                  ? AppColors.error
                                  : AppColors.border,
                              width: _phoneError ? 2 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _phoneError
                                  ? AppColors.error
                                  : AppColors.primary,
                              width: 2,
                            ),
                          ),
                          suffixIcon: _phoneController.text.length == 10
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.success)
                              : null,
                        ),
                      ),
                      if (_phoneErrorMsg != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _phoneErrorMsg!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── PIN Field (4-digit auto-submit) ───────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: _showPin
                      ? AnimatedBuilder(
                          animation: _shakeController,
                          builder: (context, child) {
                            final dx = _shakeController.isAnimating
                                ? (8 *
                                    (0.5 -
                                        (_shakeController.value * 6 % 1)
                                            .abs()
                                            .clamp(0.0, 1.0)))
                                : 0.0;
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: child,
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.enterPin,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _pinController,
                                focusNode: _pinFocus,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                obscureText: _obscurePin,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: '• • • •',
                                  counterText: '',
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _pinError
                                          ? AppColors.error
                                          : AppColors.border,
                                      width: _pinError ? 2 : 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _pinError
                                          ? AppColors.error
                                          : AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePin
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscurePin = !_obscurePin),
                                  ),
                                ),
                                onChanged: _onPinChanged,
                              ),
                              if (_pinErrorMsg != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    _pinErrorMsg!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.pick(
                            'No OTP required — just your number and PIN',
                            'OTP की जरूरत नहीं — बस नंबर और PIN',
                            'OTP नको — फक्त नंबर आणि PIN',
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Action button + Biometric button ──────────────────
                if (!_showPin)
                  GradientButton(
                    label: l10n.continueText,
                    icon: Icons.arrow_forward_rounded,
                    isLoading: provider.isLoading,
                    onPressed: _phoneController.text.length == 10
                        ? _checkPhone
                        : null,
                  ),

                if (_showPin) ...[
                  GradientButton(
                    label: l10n.loginBtn,
                    icon: Icons.login_rounded,
                    isLoading: provider.isLoading,
                    onPressed:
                        _pinController.text.length == 4 ? _login : null,
                  ),
                  // Fingerprint button
                  if (hasBiometric && biometricEnabled) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: _triggerBiometric,
                        icon: const Icon(Icons.fingerprint_rounded,
                            color: AppColors.primary, size: 28),
                        label: Text(
                          l10n.pick(
                            'Use Fingerprint',
                            'फिंगरप्रिंट उपयोग करें',
                            'फिंगरप्रिंट वापरा',
                          ),
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showPin = false;
                        _pinController.clear();
                        _pinError = false;
                      });
                    },
                    child: Text(
                      l10n.pick(
                        'Change mobile number',
                        'मोबाइल नंबर बदलें',
                        'मोबाइल नंबर बदला',
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Register link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      context.read<DashboardProvider>().reset();
                      context.read<TransactionProvider>().reset();
                      context.read<PassportProvider>().reset();
                      context.read<AiAdvisorProvider>().reset();
                      Navigator.of(context).pushNamed('/register');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: l10n.pick(
                          'New user? ',
                          'नया उपयोगकर्ता? ',
                          'नवीन वापरकर्ता? ',
                        ),
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: l10n.pick(
                              'Register here',
                              'यहाँ रजिस्टर करें',
                              'येथे नोंदणी करा',
                            ),
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Biometric Opt-In Bottom Sheet ──────────────────────────────────────────

class _BiometricOptInSheet extends StatelessWidget {
  const _BiometricOptInSheet({
    required this.onEnable,
    required this.onSkip,
  });

  final VoidCallback onEnable;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Enable Fingerprint Login?',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Next time, open VyaparSetu with just one touch. No PIN needed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onEnable,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text('Enable Fingerprint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Maybe later',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
