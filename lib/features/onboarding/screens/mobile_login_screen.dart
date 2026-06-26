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

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _pinFocus = FocusNode();

  bool _showPin = false;
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _phoneFocus.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _checkPhone() {
    final phone = _phoneController.text.trim();
    final l10n = L10n.of(context.read<OnboardingProvider>().selectedLanguage);
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validMobileErr),
          duration: const Duration(seconds: 10),
        ),
      );
      return;
    }
    setState(() => _showPin = true);
    _pinFocus.requestFocus();
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    // Capture context-dependent objects before any await
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final provider = context.read<OnboardingProvider>();
    final l10n = L10n.of(provider.selectedLanguage);

    if (pin.length != 4) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.validPinErr),
          duration: const Duration(seconds: 10),
        ),
      );
      return;
    }

    final success = await provider.loginWithPin(phone: phone, pin: pin);

    if (!mounted) return;

    if (success) {
      final hasProfile = provider.business != null;
      if (hasProfile) {
        // Reset all in-memory providers so they load clean data for this user
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
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.error ?? l10n.loginFailed),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final l10n = L10n.of(provider.selectedLanguage);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_showPin) {
              setState(() => _showPin = false);
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
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _showPin
                      ? l10n.pick('Enter the 4-digit PIN you set during registration', 'पंजीकरण के समय सेट किया गया 4-अंकी PIN दर्ज करें', 'नोंदणी वेळी सेट केलेला 4 अंकी PIN टाका')
                      : l10n.pick('Enter your registered mobile number to continue', 'जारी रखने के लिए अपना पंजीकृत मोबाइल नंबर दर्ज करें', 'पुढे जाण्यासाठी नोंदणीकृत मोबाइल नंबर टाका'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Phone Field
                AnimatedOpacity(
                  opacity: _showPin ? 0.55 : 1.0,
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
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
                          suffixIcon: _showPin
                              ? null
                              : (_phoneController.text.length == 10
                                  ? const Icon(Icons.check_circle_rounded,
                                      color: AppColors.success)
                                  : null),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // PIN Field - slides in after phone is entered
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: _showPin
                      ? Column(
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
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 20),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _showPin
                              ? l10n.pick('Your PIN is stored securely on your device', 'आपका PIN आपके डिवाइस पर सुरक्षित है', 'तुमचा PIN डिव्हाइसवर सुरक्षित आहे')
                              : l10n.pick('No OTP required — just your number and PIN', 'OTP की जरूरत नहीं — बस नंबर और PIN', 'OTP नको — फक्त नंबर आणि PIN'),
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

                // Action button
                GradientButton(
                  label: _showPin ? l10n.loginBtn : l10n.continueText,
                  icon: _showPin
                      ? Icons.login_rounded
                      : Icons.arrow_forward_rounded,
                  isLoading: provider.isLoading,
                  onPressed: _showPin
                      ? (_pinController.text.length == 4 ? _login : null)
                      : (_phoneController.text.length == 10
                          ? _checkPhone
                          : null),
                ),

                // Change number link
                if (_showPin) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showPin = false;
                        _pinController.clear();
                      });
                    },
                    child: Text(l10n.pick('Change mobile number', 'मोबाइल नंबर बदलें', 'मोबाइल नंबर बदला')),
                  ),
                ],

                const SizedBox(height: 24),

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
                        text: l10n.pick('New user? ', 'नया उपयोगकर्ता? ', 'नवीन वापरकर्ता? '),
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: l10n.pick('Register here', 'यहाँ रजिस्टर करें', 'येथे नोंदणी करा'),
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
