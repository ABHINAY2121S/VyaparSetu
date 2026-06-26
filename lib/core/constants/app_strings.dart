class AppStrings {
  AppStrings._();

  // App Name
  static const String appName = 'VyaparSetu';
  static const String appTagline = 'Your Financial Identity, Verified';

  // Language Names
  static const String english = 'English';
  static const String hindi = 'हिंदी';
  static const String marathi = 'मराठी';

  // Onboarding
  static const String selectLanguage = 'Select Language';
  static const String continueText = 'Continue';
  static const String getStarted = 'Get Started';
  static const String welcomeBack = 'Welcome Back';
  static const String createAccount = 'Create Account';

  // Login
  static const String enterMobile = 'Enter Mobile Number';
  static const String mobileNumber = 'Mobile Number';
  static const String enterOtp = 'Enter OTP';
  static const String otpSentTo = 'OTP sent to';
  static const String sendOtp = 'Send OTP';
  static const String verifyOtp = 'Verify OTP';
  static const String resendOtp = 'Resend OTP';
  static const String mobileHint = '+91 XXXXX XXXXX';

  // Business Registration
  static const String businessRegistration = 'Business Registration';
  static const String fullName = 'Full Name';
  static const String businessName = 'Business Name';
  static const String businessType = 'Business Type';
  static const String businessAge = 'Business Age (Years)';
  static const String city = 'City';
  static const String revenueRange = 'Monthly Revenue Range';
  static const String registerBusiness = 'Register Business';

  // Business Types
  static const List<String> businessTypes = [
    'Vegetable/Fruit Vendor',
    'Kirana Store',
    'Tea Stall / Chai Shop',
    'Street Food Vendor',
    'Tailoring Shop',
    'Electronics Repair',
    'Auto Mechanic',
    'Electrician',
    'Plumber',
    'Freelancer',
    'Gig Worker',
    'Home Baker',
    'Beauty / Salon',
    'Grocery Store',
    'Other',
  ];

  // Revenue Ranges
  static const List<String> revenueRanges = [
    'Below ₹10,000/month',
    '₹10,000 – ₹25,000/month',
    '₹25,000 – ₹50,000/month',
    '₹50,000 – ₹1 Lakh/month',
    'Above ₹1 Lakh/month',
  ];

  // Documents
  static const String documents = 'Documents';
  static const String uploadDocuments = 'Upload Documents';
  static const String aadhaarCard = 'Aadhaar Card';
  static const String panCard = 'PAN Card';
  static const String udyamCertificate = 'Udyam Registration';
  static const String gstCertificate = 'GST Certificate';
  static const String bankStatement = 'Bank Statement';
  static const String passbook = 'Bank Passbook';
  static const String businessLicense = 'Business License';
  static const String uploadDocument = 'Upload';
  static const String verified = 'Verified';
  static const String verifying = 'Verifying...';
  static const String pending = 'Pending';
  static const String verificationProgress = 'Verification Progress';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String goodMorning = 'Good Morning';
  static const String goodAfternoon = 'Good Afternoon';
  static const String goodEvening = 'Good Evening';
  static const String totalRevenue = 'Total Revenue';
  static const String totalExpenses = 'Total Expenses';
  static const String netProfit = 'Net Profit';
  static const String cashFlow = 'Cash Flow';
  static const String thisMonth = 'This Month';
  static const String last30Days = 'Last 30 Days';
  static const String revenueVsExpense = 'Revenue vs Expenses';
  static const String profitTrend = 'Profit Trend';
  static const String quickActions = 'Quick Actions';
  static const String viewAll = 'View All';
  static const String recentTransactions = 'Recent Transactions';

  // Score Labels
  static const String businessHealthScore = 'Business Health';
  static const String loanReadinessScore = 'Loan Readiness';
  static const String confidenceScore = 'Confidence';
  static const String yourScores = 'Your Scores';
  static const String scoreExplanation = 'Score Explanation';

  // Transactions
  static const String transactions = 'Transactions';
  static const String addTransaction = 'Add Transaction';
  static const String income = 'Income';
  static const String expense = 'Expense';
  static const String amount = 'Amount';
  static const String description = 'Description';
  static const String category = 'Category';
  static const String date = 'Date';
  static const String manualEntry = 'Manual Entry';
  static const String voiceEntry = 'Voice Entry';
  static const String ocrScan = 'OCR Scan';
  static const String upiSimulation = 'UPI Import';
  static const String bankVerified = 'Bank Verified';
  static const String upiVerified = 'UPI Verified';
  static const String ocrVerified = 'OCR Verified';
  static const String manualVerified = 'Manual Entry';

  // Income Categories
  static const List<String> incomeCategories = [
    'Sales Revenue',
    'Service Income',
    'Commission',
    'Rental Income',
    'Other Income',
  ];

  // Expense Categories
  static const List<String> expenseCategories = [
    'Stock / Inventory',
    'Rent',
    'Electricity',
    'Transport',
    'Salary / Labour',
    'Equipment',
    'Raw Materials',
    'Marketing',
    'Miscellaneous',
  ];

  // Financial Passport
  static const String financialPassport = 'VyaparSetu Profile';
  static const String passportId = 'Passport ID';
  static const String reportId = 'Report ID';
  static const String generatedOn = 'Generated On';
  static const String validUntil = 'Valid Until';
  static const String verificationHash = 'Verification Hash';
  static const String immutableRecord = 'Immutable Record';
  static const String passportLocked = 'This passport is cryptographically sealed';
  static const String riskLevel = 'Risk Level';
  static const String recommendedLoan = 'Recommended Loan Range';
  static const String explainableAI = 'AI Score Breakdown';
  static const String generatePassport = 'Generate Passport';
  static const String downloadPdf = 'Download PDF';
  static const String shareWithBank = 'Share with Bank';
  static const String passportStatus = 'Passport Status';

  // Risk Levels
  static const String riskLow = 'Low Risk';
  static const String riskMedium = 'Medium Risk';
  static const String riskHigh = 'High Risk';

  // AI Advisor
  static const String aiAdvisor = 'AI Advisor';
  static const String askVyaparSetu = 'Ask VyaparSetu AI...';
  static const String typeMessage = 'Type your question...';
  static const String suggestedQuestions = 'Suggested Questions';
  static const String aiThinking = 'AI is analyzing...';
  static const List<String> suggestedPrompts = [
    'Can I get a loan?',
    'Which scheme should I apply for?',
    'How can I improve my score?',
    'What EMI is safe for me?',
    'Why is my profit decreasing?',
    'How to grow my business?',
    'Am I eligible for Mudra loan?',
    'What documents do I need for a loan?',
  ];

  // Schemes
  static const String schemes = 'Schemes';
  static const String governmentSchemes = 'Government Schemes';
  static const String eligibility = 'Eligibility';
  static const String benefits = 'Benefits';
  static const String requiredDocuments = 'Required Documents';
  static const String applyNow = 'Apply Now';
  static const String learnMore = 'Learn More';
  static const String youAreEligible = 'You may be eligible';
  static const String checkEligibility = 'Check Eligibility';

  // Insights
  static const String insights = 'Business Insights';
  static const String aiInsights = 'AI Insights';
  static const String revenueIncreased = 'Revenue Increased';
  static const String expensesRising = 'Expenses Rising';
  static const String profitDecreasing = 'Profit Alert';
  static const String cashFlowHealthy = 'Cash Flow Healthy';

  // Profile
  static const String profile = 'Profile';
  static const String myProfile = 'My Profile';
  static const String businessDetails = 'Business Details';
  static const String language = 'Language';
  static const String logout = 'Logout';
  static const String editProfile = 'Edit Profile';
  static const String memberSince = 'Member Since';

  // Bottom Navigation
  static const String navHome = 'Home';
  static const String navTransactions = 'Transactions';
  static const String navPassport = 'Passport';
  static const String navAdvisor = 'AI Chat';
  static const String navProfile = 'Profile';

  // Common
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String share = 'Share';
  static const String download = 'Download';
  static const String close = 'Close';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String submit = 'Submit';
  static const String loading = 'Loading...';
  static const String noData = 'No data available';
  static const String error = 'Something went wrong';
  static const String retry = 'Retry';
  static const String success = 'Success';
  static const String confirmation = 'Confirmation';

  // Multilingual greetings
  static Map<String, String> greeting(String language) {
    switch (language) {
      case 'hi':
        return {
          'welcome': 'VyaparSetu में आपका स्वागत है',
          'tagline': 'आपकी वित्तीय पहचान, सत्यापित',
        };
      case 'mr':
        return {
          'welcome': 'VyaparSetu मध्ये आपले स्वागत आहे',
          'tagline': 'तुमची आर्थिक ओळख, सत्यापित',
        };
      default:
        return {
          'welcome': 'Welcome to VyaparSetu',
          'tagline': 'Your Financial Identity, Verified',
        };
    }
  }
}
