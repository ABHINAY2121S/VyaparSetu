import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/business_model.dart';

class OnboardingProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isOnboardingComplete = false;
  String _selectedLanguage = 'en';
  UserModel? _user;
  BusinessModel? _business;
  bool _isLoading = false;
  String? _error;
  bool _biometricAvailable = false;

  bool get isOnboardingComplete => _isOnboardingComplete;
  String get selectedLanguage => _selectedLanguage;
  UserModel? get user => _user;
  BusinessModel? get business => _business;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get biometricAvailable => _biometricAvailable;

  Future<void> init() async {
    _isOnboardingComplete = _storage.isOnboardingComplete;
    _selectedLanguage = _storage.selectedLanguage;
    _user = _storage.getUser();
    _business = _storage.getBusiness();
    // Check hardware biometric support once at startup
    try {
      _biometricAvailable = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {
      _biometricAvailable = false;
    }
    notifyListeners();
  }

  /// Returns true if this phone number has biometric login enabled.
  bool isBiometricEnabled(String phone) =>
      _storage.isBiometricEnabled(phone);

  /// Persists the user's choice to use (or not use) biometric login.
  Future<void> setBiometricEnabled(String phone, bool enabled) async {
    await _storage.setBiometricEnabled(phone, enabled);
    notifyListeners();
  }

  /// Triggers the system biometric prompt.
  /// Returns true if the user authenticated successfully.
  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Use fingerprint to access VyaparSetu',
        options: const AuthenticationOptions(
          biometricOnly: false, // falls back to device PIN/pattern if needed
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> selectLanguage(String lang) async {
    _selectedLanguage = lang;
    await _storage.setSelectedLanguage(lang);
    notifyListeners();
  }

  /// Returns true if there is a registered account for this phone number.
  bool isRegistered(String phone) => _storage.hasPin(phone);

  /// Sets this phone as the active session and loads its user/business data.
  /// Used after biometric authentication where we skip PIN verification.
  Future<void> setActivePhone(String phone) async {
    await _storage.saveRegisteredPhone(phone);
    _user = _storage.getUser();
    _business = _storage.getBusiness();
    notifyListeners();
  }

  /// Login: verify phone + PIN locally.
  Future<bool> loginWithPin({
    required String phone,
    required String pin,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    if (!_storage.hasPin(phone)) {
      _error = _pick('No account found for this number. Please register first.',
          'इस नंबर के लिए कोई खाता नहीं मिला। कृपया पहले रजिस्टर करें।',
          'या नंबरसाठी खाते सापडले नाही. कृपया आधी नोंदणी करा.');
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final valid = _storage.verifyPin(phone, pin);
    if (!valid) {
      _error = _pick('Incorrect PIN. Please try again.',
          'गलत PIN। कृपया पुनः प्रयास करें।',
          'चुकीचा PIN. कृपया पुन्हा प्रयत्न करा.');
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Save active phone session
    await _storage.saveRegisteredPhone(phone);

    // Load saved profile
    _user = _storage.getUser();
    _business = _storage.getBusiness();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Registration Step 1: save phone + PIN locally.
  Future<bool> registerPin({
    required String phone,
    required String pin,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));

    if (_storage.hasPin(phone)) {
      _error = _pick('An account already exists for this number. Please login.',
          'इस नंबर के लिए पहले से खाता है। कृपया लॉगिन करें।',
          'या नंबरसाठी आधीच खाते अस्तित्वात आहे. कृपया लॉगिन करा.');
      _isLoading = false;
      notifyListeners();
      return false;
    }

    await _storage.savePin(phone, pin);
    await _storage.saveRegisteredPhone(phone);

    // Wipe ALL data from any previous session or judge demo mode.
    // Every new account must start completely fresh — no leakage.
    await _storage.clearUser();
    await _storage.clearBusiness();
    await _storage.clearTransactions();
    await _storage.clearDocuments();
    await _storage.clearPassports();
    await _storage.clearChatHistory();

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Registration Step 2: save business details locally.
  Future<void> registerBusiness({
    required String phone,
    required String ownerName,
    required String businessName,
    required String businessType,
    required int businessAge,
    required String city,
    required String revenueRange,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    // Ensure no stale data bleeds into the new account.
    await _storage.clearTransactions();
    await _storage.clearDocuments();

    final uid = 'user_${phone}_${DateTime.now().millisecondsSinceEpoch}';

    _user = UserModel(
      id: uid,
      name: ownerName,
      phone: phone,
      language: _selectedLanguage,
      createdAt: DateTime.now(),
      profileSetupComplete: true,
    );
    await _storage.saveUser(_user!);

    _business = BusinessModel(
      id: 'biz_$phone',
      businessName: businessName,
      businessType: businessType,
      businessAge: businessAge,
      city: city,
      revenueRange: revenueRange,
      registeredAt: DateTime.now(),
    );
    await _storage.saveBusiness(_business!);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isOnboardingComplete = true;
    await _storage.setOnboardingComplete(true);
    notifyListeners();
  }

  Future<void> logout() async {
    _isOnboardingComplete = false;
    _user = null;
    _business = null;
    await _storage.clearAll();
    await _storage.init();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Picks the correct translation based on the current selected language.
  String _pick(String en, String hi, String mr) {
    switch (_selectedLanguage) {
      case 'hi':
        return hi;
      case 'mr':
        return mr;
      default:
        return en;
    }
  }
}
