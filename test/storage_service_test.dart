import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vyaparsetu/core/services/storage_service.dart';
import 'package:vyaparsetu/shared/models/user_model.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();
  });

  test('Should isolate user profiles by registered phone number', () async {
    final storage = StorageService.instance;

    // Register User A
    final userA = UserModel(
      id: 'user_A',
      name: 'User A Name',
      phone: '1111111111',
      language: 'en',
      createdAt: DateTime.now(),
      profileSetupComplete: true,
    );
    await storage.savePin('1111111111', '1111');
    await storage.saveRegisteredPhone('1111111111');
    await storage.saveUser(userA);

    // Register User B
    final userB = UserModel(
      id: 'user_B',
      name: 'User B Name',
      phone: '2222222222',
      language: 'en',
      createdAt: DateTime.now(),
      profileSetupComplete: true,
    );
    await storage.savePin('2222222222', '2222');
    await storage.saveRegisteredPhone('2222222222');
    await storage.saveUser(userB);

    // Now log in as User A
    await storage.saveRegisteredPhone('1111111111');
    final loadedUserA = storage.getUser();
    expect(loadedUserA?.name, 'User A Name');

    // Now log in as User B
    await storage.saveRegisteredPhone('2222222222');
    final loadedUserB = storage.getUser();
    expect(loadedUserB?.name, 'User B Name');
  });

  test('Should migrate legacy global profile to phone-scoped profile on login', () async {
    final storage = StorageService.instance;
    final prefs = await SharedPreferences.getInstance();

    // Setup legacy global data in SharedPreferences
    final legacyUser = UserModel(
      id: 'legacy_user',
      name: 'Legacy Ramesh',
      phone: '9876543210',
      language: 'en',
      createdAt: DateTime.now(),
      profileSetupComplete: true,
    );
    await prefs.setString('user', jsonEncode(legacyUser.toJson()));
    await prefs.setString('business', jsonEncode({
      'id': 'biz_legacy',
      'businessName': 'Legacy Store',
      'businessType': 'Retail',
      'businessAge': 3,
      'city': 'Mumbai',
      'revenueRange': '₹25,000 – ₹50,000/month',
      'registeredAt': DateTime.now().toIso8601String(),
    }));

    // Log in with phone 9876543210
    await storage.saveRegisteredPhone('9876543210');

    // Get user should trigger migration
    final user = storage.getUser();
    expect(user?.name, 'Legacy Ramesh');

    // Verify it is now saved under phone-scoped key
    final scopedUserJson = prefs.getString('user_9876543210');
    expect(scopedUserJson, isNotNull);

    final business = storage.getBusiness();
    expect(business?.businessName, 'Legacy Store');

    final scopedBizJson = prefs.getString('business_9876543210');
    expect(scopedBizJson, isNotNull);
  });
}
