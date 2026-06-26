import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/transactions/providers/transaction_provider.dart';
import 'features/passport/providers/passport_provider.dart';
import 'features/ai_advisor/providers/ai_advisor_provider.dart';
import 'features/schemes/providers/scheme_provider.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/screens/splash_screen.dart';
import 'features/onboarding/screens/language_selection_screen.dart';
import 'features/onboarding/screens/mobile_login_screen.dart';
import 'features/onboarding/screens/business_registration_screen.dart';
import 'features/onboarding/screens/document_upload_screen.dart';
import 'features/transactions/screens/add_transaction_screen.dart';
import 'features/transactions/screens/transaction_detail_screen.dart';

import 'core/services/upi_statement_parser.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize local storage
  await StorageService.instance.init();

  // Configure Gemini AI for bank statement parsing
  // Pass key via: flutter run --dart-define=GEMINI_API_KEY=your_key_here
  const geminiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  UpiStatementParser.configure(geminiKey);

  runApp(const VyaparSetuApp());
}

class VyaparSetuApp extends StatelessWidget {
  const VyaparSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()..init()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => PassportProvider()),
        ChangeNotifierProvider(create: (_) => AiAdvisorProvider()),
        ChangeNotifierProvider(create: (_) => SchemeProvider()),
      ],
      child: Consumer<OnboardingProvider>(
        builder: (context, onboarding, _) {
          return MaterialApp(
            title: 'VyaparSetu',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            initialRoute: '/splash',
            routes: {
              '/splash': (_) => const SplashScreen(),
              '/onboarding': (_) => const LanguageSelectionScreen(),
              '/login': (_) => const MobileLoginScreen(),
              '/register': (_) => const BusinessRegistrationScreen(),
              '/documents': (_) => const DocumentUploadScreen(),
              '/home': (_) => const HomeScreen(),
              '/add-transaction': (_) => const AddTransactionScreen(),
              '/transaction-detail': (_) => const TransactionDetailScreen(),
            },
            onGenerateRoute: (settings) {
              // Handle unknown routes
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
