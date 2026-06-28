import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/onboarding_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _langController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _langFade;
  late Animation<Offset> _langSlide;

  String? _selectedLang;
  bool _navigating = false;

  static const _languages = [
    {'code': 'en', 'native': 'English', 'flag': '🇬🇧'},
    {'code': 'hi', 'native': 'हिंदी',   'flag': '🇮🇳'},
    {'code': 'mr', 'native': 'मराठी',   'flag': '🇮🇳'},
  ];

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _langController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _langFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _langController, curve: Curves.easeOut),
    );
    _langSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _langController, curve: Curves.easeOut));

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) _langController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _langController.dispose();
    super.dispose();
  }

  Future<void> _onLanguageTap(String langCode) async {
    if (_navigating) return;
    setState(() {
      _selectedLang = langCode;
      _navigating = true;
    });

    final provider = context.read<OnboardingProvider>();
    await provider.selectLanguage(langCode);

    if (!mounted) return;

    // Check if returning user has biometrics enabled
    final phone = provider.user?.phone ?? '';
    final isReturning = phone.isNotEmpty &&
        provider.isOnboardingComplete &&
        provider.isBiometricEnabled(phone);

    if (isReturning) {
      // Try biometric immediately — if succeed, go home; else go to login
      final ok = await provider.authenticateWithBiometric();
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }
    }

    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // ── Logo ───────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _logoController,
                builder: (_, __) => Transform.scale(
                  scale: _logoScale.value,
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'VS',
                              style: GoogleFonts.inter(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'VyaparSetu',
                          style: GoogleFonts.inter(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your Financial Identity, Verified',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── Language chips ────────────────────────────────────────
              SlideTransition(
                position: _langSlide,
                child: FadeTransition(
                  opacity: _langFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Choose Language / भाषा चुनें',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: _languages.map((lang) {
                            final code = lang['code']!;
                            final isSelected = _selectedLang == code;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: _LanguageChip(
                                  flag: lang['flag']!,
                                  label: lang['native']!,
                                  isSelected: isSelected,
                                  onTap: () => _onLanguageTap(code),
                                ),
                              ),
                            );
                          }).toList(),
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
    );
  }
}

class _LanguageChip extends StatefulWidget {
  const _LanguageChip({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_LanguageChip> createState() => _LanguageChipState();
}

class _LanguageChipState extends State<_LanguageChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: widget.isSelected
                      ? AppColors.primary
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
