/// Complete localization system for VyaparSetu
/// Supports: English (en), Hindi (hi), Marathi (mr)
class L10n {
  final String code;
  const L10n._(this.code);

  static const L10n en = L10n._('en');
  static const L10n hi = L10n._('hi');
  static const L10n mr = L10n._('mr');

  static L10n of(String code) {
    switch (code) {
      case 'hi': return hi;
      case 'mr': return mr;
      default:   return en;
    }
  }

  // ── App ──────────────────────────────────────────────────────────────────
  String get appName => 'VyaparSetu';
  String get appTagline => pick(
    'Your Financial Identity, Verified',
    'आपकी वित्तीय पहचान, सत्यापित',
    'तुमची आर्थिक ओळख, सत्यापित',
  );

  // ── Onboarding ───────────────────────────────────────────────────────────
  String get selectLanguage => pick('Select Language', 'भाषा चुनें', 'भाषा निवडा');
  String get continueText   => pick('Continue', 'आगे बढ़ें', 'पुढे जा');
  String get getStarted     => pick('Get Started', 'शुरू करें', 'सुरू करा');
  String get welcomeBack    => pick('Welcome Back', 'वापस स्वागत है', 'परत स्वागत आहे');
  String get welcome        => pick('Welcome to VyaparSetu', 'VyaparSetu में स्वागत है', 'VyaparSetu मध्ये स्वागत आहे');

  // ── Login ────────────────────────────────────────────────────────────────
  String get enterMobile    => pick('Enter Mobile Number', 'मोबाइल नंबर दर्ज करें', 'मोबाइल नंबर टाका');
  String get mobileNumber   => pick('Mobile Number', 'मोबाइल नंबर', 'मोबाइल नंबर');
  String get mobileHint     => pick('+91 XXXXX XXXXX', '+91 XXXXX XXXXX', '+91 XXXXX XXXXX');
  String get enterPin       => pick('Enter 4-digit PIN', '4 अंकों का PIN दर्ज करें', '4 अंकी PIN टाका');
  String get loginBtn       => pick('Login', 'लॉगिन करें', 'लॉगिन करा');
  String get newUserRegister=> pick('New user? Register', 'नया उपयोगकर्ता? रजिस्टर करें', 'नवीन वापरकर्ता? नोंदणी करा');
  String get nextBtn        => pick('Next', 'आगे', 'पुढे');
  String get validMobileErr => pick('Please enter a valid 10-digit number', 'कृपया 10 अंकों का वैध नंबर दर्ज करें', 'कृपया 10 अंकी वैध नंबर टाका');
  String get validPinErr    => pick('Please enter your 4-digit PIN', 'कृपया अपना 4 अंकों का PIN दर्ज करें', 'कृपया तुमचा 4 अंकी PIN टाका');
  String get loginFailed    => pick('Login failed', 'लॉगिन विफल', 'लॉगिन अयशस्वी');

  // ── Registration ─────────────────────────────────────────────────────────
  String get businessRegistration => pick('Business Registration', 'व्यापार पंजीकरण', 'व्यवसाय नोंदणी');
  String get fullName          => pick('Full Name', 'पूरा नाम', 'पूर्ण नाव');
  String get businessName      => pick('Business Name', 'व्यापार का नाम', 'व्यवसायाचे नाव');
  String get businessType      => pick('Business Type', 'व्यापार का प्रकार', 'व्यवसायाचा प्रकार');
  String get businessAge       => pick('Business Age (Years)', 'व्यापार की उम्र (वर्ष)', 'व्यवसायाचे वय (वर्षे)');
  String get city              => pick('City', 'शहर', 'शहर');
  String get revenueRange      => pick('Monthly Revenue Range', 'मासिक आय सीमा', 'मासिक उत्पन्न श्रेणी');
  String get registerBusiness  => pick('Register Business', 'व्यापार पंजीकृत करें', 'व्यवसाय नोंदवा');
  String get stepPersonal      => pick('Personal', 'व्यक्तिगत', 'वैयक्तिक');
  String get stepBusiness      => pick('Business', 'व्यापार', 'व्यवसाय');
  String get stepPin           => pick('Set PIN', 'PIN सेट करें', 'PIN सेट करा');
  String get setPin            => pick('Set 4-digit PIN', '4 अंकों का PIN सेट करें', '4 अंकी PIN सेट करा');
  String get confirmPin        => pick('Confirm PIN', 'PIN की पुष्टि करें', 'PIN पुष्टी करा');
  String get pinMismatch       => pick('PINs do not match. Please re-enter.', 'PIN मेल नहीं खाते। कृपया पुनः दर्ज करें।', 'PIN जुळत नाही. कृपया पुन्हा टाका.');
  String get registrationFailed=> pick('Registration failed', 'पंजीकरण विफल', 'नोंदणी अयशस्वी');
  String get alreadyHaveAccount=> pick('Already have account? Login', 'खाता है? लॉगिन करें', 'खाते आहे? लॉगिन करा');

  List<String> get businessTypes => _pickList(
    ['Vegetable/Fruit Vendor','Kirana Store','Tea Stall / Chai Shop','Street Food Vendor','Tailoring Shop','Electronics Repair','Auto Mechanic','Electrician','Plumber','Freelancer','Gig Worker','Home Baker','Beauty / Salon','Grocery Store','Other'],
    ['सब्जी/फल विक्रेता','किराना स्टोर','चाय की दुकान','स्ट्रीट फूड विक्रेता','दर्जी की दुकान','इलेक्ट्रॉनिक्स मरम्मत','ऑटो मैकेनिक','इलेक्ट्रीशियन','प्लंबर','फ्रीलांसर','गिग वर्कर','होम बेकर','ब्यूटी / सैलून','किराना स्टोर','अन्य'],
    ['भाजी/फळ विक्रेता','किराणा स्टोर','चहाची टपरी','स्ट्रीट फूड विक्रेता','शिवणकाम दुकान','इलेक्ट्रॉनिक्स दुरुस्ती','ऑटो मेकॅनिक','इलेक्ट्रिशियन','प्लंबर','फ्रीलान्सर','गिग वर्कर','होम बेकर','सौंदर्य / सलून','किराणा दुकान','इतर'],
  );

  List<String> get revenueRanges => _pickList(
    ['Below ₹10,000/month','₹10,000 – ₹25,000/month','₹25,000 – ₹50,000/month','₹50,000 – ₹1 Lakh/month','Above ₹1 Lakh/month'],
    ['₹10,000/माह से कम','₹10,000 – ₹25,000/माह','₹25,000 – ₹50,000/माह','₹50,000 – ₹1 लाख/माह','₹1 लाख/माह से अधिक'],
    ['₹10,000/महिन्यापेक्षा कमी','₹10,000 – ₹25,000/महिना','₹25,000 – ₹50,000/महिना','₹50,000 – ₹1 लाख/महिना','₹1 लाखापेक्षा जास्त/महिना'],
  );

  // ── Documents ────────────────────────────────────────────────────────────
  String get uploadDocuments  => pick('Upload Documents', 'दस्तावेज़ अपलोड करें', 'कागदपत्रे अपलोड करा');
  String get verificationProgress => pick('Verification Progress', 'सत्यापन प्रगति', 'पडताळणी प्रगती');
  String get uploadBtn        => pick('Upload', 'अपलोड', 'अपलोड');
  String get verified         => pick('Verified', 'सत्यापित', 'पडताळलेले');
  String get verifying        => pick('Verifying...', 'सत्यापित हो रहा है...', 'पडताळत आहे...');
  String get pending          => pick('Pending', 'लंबित', 'प्रलंबित');
  String get continueToHome   => pick('Continue to Home', 'होम पर जाएं', 'मुख्यपृष्ठावर जा');
  String get aadhaarCard      => pick('Aadhaar Card', 'आधार कार्ड', 'आधार कार्ड');
  String get panCard          => pick('PAN Card', 'PAN कार्ड', 'PAN कार्ड');
  String get udyamCertificate => pick('Udyam Registration', 'उद्यम पंजीकरण', 'उद्यम नोंदणी');
  String get gstCertificate   => pick('GST Certificate', 'GST प्रमाण पत्र', 'GST प्रमाणपत्र');
  String get bankStatement    => pick('Bank Statement', 'बैंक स्टेटमेंट', 'बँक विवरण');
  String get bankPassbook     => pick('Bank Passbook', 'बैंक पासबुक', 'बँक पासबुक');

  // ── Dashboard ────────────────────────────────────────────────────────────
  String get dashboard        => pick('Dashboard', 'डैशबोर्ड', 'डॅशबोर्ड');
  String get goodMorning      => pick('Good Morning', 'सुप्रभात', 'शुभ सकाळ');
  String get goodAfternoon    => pick('Good Afternoon', 'नमस्ते', 'नमस्कार');
  String get goodEvening      => pick('Good Evening', 'शुभ संध्या', 'शुभ संध्याकाळ');
  String get totalRevenue     => pick('Total Revenue', 'कुल आय', 'एकूण उत्पन्न');
  String get totalExpenses    => pick('Total Expenses', 'कुल खर्च', 'एकूण खर्च');
  String get netProfit        => pick('Net Profit', 'शुद्ध लाभ', 'निव्वळ नफा');
  String get recentTransactions=> pick('Recent Transactions', 'हाल के लेनदेन', 'अलीकडील व्यवहार');
  String get viewAll          => pick('View All', 'सभी देखें', 'सर्व पहा');
  String get quickActions     => pick('Quick Actions', 'त्वरित क्रियाएं', 'त्वरित क्रिया');

  // ── Transactions ─────────────────────────────────────────────────────────
  String get transactions     => pick('Transactions', 'लेनदेन', 'व्यवहार');
  String get addTransaction   => pick('Add Transaction', 'लेनदेन जोड़ें', 'व्यवहार जोडा');
  String get income           => pick('Income', 'आय', 'उत्पन्न');
  String get expense          => pick('Expense', 'खर्च', 'खर्च');
  String get amount           => pick('Amount (₹) *', 'राशि (₹) *', 'रक्कम (₹) *');
  String get descriptionLabel => pick('Description *', 'विवरण *', 'वर्णन *');
  String get categoryLabel    => pick('Category *', 'श्रेणी *', 'श्रेणी *');
  String get dateLabel        => pick('Date', 'तारीख', 'तारीख');
  String get entryMethod      => pick('Entry Method', 'प्रविष्टि विधि', 'नोंदणी पद्धत');
  String get manual           => pick('Manual', 'मैनुअल', 'मॅन्युअल');
  String get voice            => pick('Voice', 'आवाज़', 'आवाज');
  String get ocr              => pick('OCR', 'ओसीआर (OCR)', 'ओसीआर (OCR)');
  String get upi              => pick('UPI', 'यूपीआई (UPI)', 'यूपीआय (UPI)');
  String get saveTransaction  => pick('Save Transaction', 'लेनदेन सहेजें', 'व्यवहार जतन करा');
  
  String get pleaseSelectCategory => pick('Please select a category', 'कृपया श्रेणी चुनें', 'कृपया श्रेणी निवडा');
  String get enterAmount => pick('Enter amount', 'राशि दर्ज करें', 'रक्कम टाका');
  String get invalidAmount => pick('Invalid amount', 'अवैध राशि', 'अवैध रक्कम');
  String get amountPositive => pick('Amount must be positive', 'राशि सकारात्मक होनी चाहिए', 'रक्कम सकारात्मक असणे आवश्यक आहे');
  String get enterDescription => pick('Enter description', 'विवरण दर्ज करें', 'वर्णन टाका');
  String get descHint => pick('e.g. Vegetable sales - Morning batch', 'उदा. सब्जी की बिक्री - सुबह का बैच', 'उदा. भाजी विक्री - सकाळची बॅच');
  String get transactionAdded => pick('added!', 'जोड़ा गया!', 'जोडले!');
  String get ofText => pick('of', 'का', 'चे');
  
  String get voiceEntryTitle => pick('Voice Entry', 'आवाज़ प्रविष्टि', 'आवाज नोंदणी');
  String get voiceEntryHint => pick('Try: "Today I sold vegetables worth ₹2500"', 'कोशिश करें: "आज मैंने ₹2500 की सब्जियां बेचीं"', 'प्रयत्न करा: "आज मी ₹2500 ची भाजी विकली"');
  String get voiceInputHint => pick('Type or say your transaction...', 'अपना लेनदेन टाइप करें या बोलें...', 'तुमचा व्यवहार टाईप करा किंवा बोला...');
  String get parseVoiceInput => pick('Parse Voice Input', 'वॉइस इनपुट पार्स करें', 'व्हॉइस इनपुट पार्स करा');
  String get processing => pick('Processing...', 'प्रसंस्करण...', 'प्रक्रिया करत आहे...');
  String get voiceParseError => pick('Could not parse. Please include amount like "₹2500"', 'पार्स नहीं कर सका। कृपया "₹2500" जैसी राशि शामिल करें', 'पार्स करू शकलो नाही. कृपया "₹2500" सारखी रक्कम समाविष्ट करा');
  
  String get tapToScanReceipt => pick('Tap to Scan Receipt', 'रसीद स्कैन करने के लिए टैप करें', 'पावती स्कॅन करण्यासाठी टॅप करा');
  String get scanningReceipt => pick('Scanning receipt...', 'रसीद स्कैन हो रही है...', 'पावती स्कॅन करत आहे...');
  String get aiExtractAmount => pick('AI will extract amount automatically', 'AI स्वचालित रूप से राशि निकालेगा', 'AI स्वयंचलितपणे रक्कम काढेल');
  
  String get importUpiTransaction => pick('Import UPI Transaction', 'UPI लेनदेन आयात करें', 'UPI व्यवहार आयात करा');
  String get fetchingUpi => pick('Fetching UPI...', 'UPI प्राप्त कर रहा है...', 'UPI प्राप्त करत आहे...');
  String get autoVerifiedGateway => pick('Auto-verified from payment gateway', 'भुगतान गेटवे से स्वतः-सत्यापित', 'पेमेंट गेटवेवरून स्वयं-सत्यापित');

  String get all              => pick('All', 'सभी', 'सर्व');
  String get net              => pick('Net', 'शुद्ध', 'निव्वळ');
  String get noTransactionsYet => pick('No transactions yet', 'अभी तक कोई लेनदेन नहीं', 'अद्याप कोणतेही व्यवहार नाहीत');
  String get tapToAddFirst    => pick('Tap + to add your first transaction', 'अपना पहला लेनदेन जोड़ने के लिए + टैप करें', 'तुमचा पहिला व्यवहार जोडण्यासाठी + टॅप करा');
  
  String get transactionDetail => pick('Transaction Detail', 'लेनदेन विवरण', 'व्यवहार तपशील');
  String get deleteTransaction => pick('Delete Transaction', 'लेनदेन हटाएं', 'व्यवहार हटवा');
  String get deleteTransactionConfirm => pick('This transaction will be permanently deleted. Your scores may be affected.', 'यह लेनदेन स्थायी रूप से हटा दिया जाएगा। आपके स्कोर प्रभावित हो सकते हैं।', 'हा व्यवहार कायमचा हटवला जाईल. तुमच्या स्कोअरवर परिणाम होऊ शकतो.');
  String get delete => pick('Delete', 'हटाएं', 'हटवा');
  String get typeLabel => pick('Type', 'प्रकार', 'प्रकार');
  String get verificationLabel => pick('Verification', 'सत्यापन', 'पडताळणी');
  String get noteLabel => pick('Note', 'नोट', 'नोंद');

  List<String> get incomeCategories => _pickList(
    ['Sales Revenue', 'Service Income', 'Commission', 'Rental Income', 'Other Income'],
    ['बिक्री से आय', 'सेवा से आय', 'कमीशन', 'किराए से आय', 'अन्य आय'],
    ['विक्रीतून उत्पन्न', 'सेवेतून उत्पन्न', 'कमिशन', 'भाड्याचे उत्पन्न', 'इतर उत्पन्न'],
  );

  List<String> get expenseCategories => _pickList(
    ['Stock / Inventory', 'Rent', 'Electricity', 'Transport', 'Salary / Labour', 'Equipment', 'Raw Materials', 'Marketing', 'Miscellaneous'],
    ['स्टॉक / इन्वेंटरी', 'किराया', 'बिजली', 'परिवहन', 'वेतन / मजदूरी', 'उपकरण', 'कच्चा माल', 'मार्केटिंग', 'विविध'],
    ['स्टॉक / इन्व्हेंटरी', 'भाडे', 'वीज', 'वाहतूक', 'पगार / मजुरी', 'उपकरणे', 'कच्चा माल', 'मार्केटिंग', 'विविध'],
  );

  // ── Profile ──────────────────────────────────────────────────────────────
  String get profile          => pick('Profile', 'प्रोफ़ाइल', 'प्रोफाइल');
  String get language         => pick('Language', 'भाषा', 'भाषा');
  String get logout           => pick('Logout', 'लॉगआउट', 'लॉगआउट');
  String get businessDetails  => pick('Business Details', 'व्यापार विवरण', 'व्यवसाय तपशील');

  // ── Bottom Nav ───────────────────────────────────────────────────────────
  String get navHome          => pick('Home', 'होम', 'मुख्यपृष्ठ');
  String get navTransactions  => pick('Transactions', 'लेनदेन', 'व्यवहार');
  String get navPassport      => pick('Passport', 'पासपोर्ट', 'पासपोर्ट');
  String get navAdvisor       => pick('AI Chat', 'AI चैट', 'AI चॅट');
  String get navProfile       => pick('Profile', 'प्रोफ़ाइल', 'प्रोफाइल');

  // ── Schemes ──────────────────────────────────────────────────────────────
  String get schemesTitle      => pick('Government Schemes', 'सरकारी योजनाएं', 'शासकीय योजना');
  String get schemeNoFound     => pick('No schemes found', 'कोई योजना नहीं मिली', 'कोणतीही योजना सापडली नाही');
  String get schemeMatch       => pick('Match', 'मेल', 'जुळणी');
  String get schemePopular     => pick('⭐ Popular', '⭐ लोकप्रिय', '⭐ लोकप्रिय');
  String get schemeApplyOnline => pick('Apply Online', 'ऑनलाइन आवेदन करें', 'ऑनलाइन अर्ज करा');
  String get schemeDetails     => pick('Details', 'विवरण', 'तपशील');
  String get schemeLoanRange   => pick('Loan Range', 'ऋण सीमा', 'कर्ज श्रेणी');
  String get schemeInterest    => pick('Interest', 'ब्याज', 'व्याज');
  String get schemeBenefits    => pick('Key Benefits', 'मुख्य लाभ', 'मुख्य फायदे');
  String get schemeDocuments   => pick('Required Documents', 'आवश्यक दस्तावेज़', 'आवश्यक कागदपत्रे');
  String get schemeEligibleFor => pick('Eligible For', 'के लिए पात्र', 'पात्र');
  String get schemeCatAll      => pick('All', 'सभी', 'सर्व');
  String get schemeCatLoan     => pick('Loan', 'ऋण', 'कर्ज');
  String get schemeCatGuarantee=> pick('Guarantee', 'गारंटी', 'हमी');
  String get schemeCatSubsidy  => pick('Subsidy + Loan', 'सब्सिडी + ऋण', 'अनुदान + कर्ज');

  // Scheme data — name, shortDesc, fullDesc per scheme
  // scheme_001 — PM Mudra Yojana Kishore
  String get scheme001Name => pick(
    'PM Mudra Yojana — Kishore',
    'पीएम मुद्रा योजना — किशोर',
    'पीएम मुद्रा योजना — किशोर',
  );
  String get scheme001Short => pick(
    'Micro loans for growing small businesses without collateral',
    'बिना जमानत के छोटे व्यवसायों के लिए माइक्रो लोन',
    'तारण न घेता वाढत्या लघु व्यवसायांसाठी सूक्ष्म कर्ज',
  );
  String get scheme001Full => pick(
    'Pradhan Mantri Mudra Yojana (PMMY) under the Kishore category provides loans from ₹50,000 to ₹5 Lakh for micro-enterprises that have already established their businesses and need funds for expansion. No collateral required. Banks, MFIs, and NBFCs participate in this scheme.',
    'प्रधानमंत्री मुद्रा योजना (PMMY) के किशोर श्रेणी में ₹50,000 से ₹5 लाख तक का लोन उन सूक्ष्म उद्यमों के लिए दिया जाता है जो पहले से स्थापित हैं और विस्तार के लिए धन चाहते हैं। कोई जमानत नहीं चाहिए। बैंक, MFI और NBFC इस योजना में भाग लेते हैं।',
    'प्रधानमंत्री मुद्रा योजना (PMMY) च्या किशोर श्रेणीअंतर्गत आधीच स्थापित असलेल्या सूक्ष्म उद्योगांना विस्तारासाठी ₹50,000 ते ₹5 लाख पर्यंत कर्ज दिले जाते. कोणतेही तारण नाही. बँक, MFI आणि NBFC या योजनेत सहभागी आहेत.',
  );
  List<String> get scheme001Benefits => _pickList(
    ['No collateral required','Low interest rate','Easy repayment tenure (3-5 years)','Available at all banks and NBFCs','No processing fee'],
    ['कोई जमानत नहीं','कम ब्याज दर','आसान पुनर्भुगतान अवधि (3-5 वर्ष)','सभी बैंकों और NBFC में उपलब्ध','कोई प्रसंस्करण शुल्क नहीं'],
    ['कोणतेही तारण नाही','कमी व्याजदर','सोपी परतफेड मुदत (3-5 वर्षे)','सर्व बँका आणि NBFC मध्ये उपलब्ध','कोणताही प्रक्रिया शुल्क नाही'],
  );
  List<String> get scheme001Docs => _pickList(
    ['Aadhaar Card','PAN Card','Business proof (Udyam/License)','Bank statement (6 months)','Passport-size photographs'],
    ['आधार कार्ड','पैन कार्ड','व्यापार प्रमाण (उद्यम/लाइसेंस)','बैंक स्टेटमेंट (6 महीने)','पासपोर्ट आकार की फ़ोटो'],
    ['आधार कार्ड','PAN कार्ड','व्यवसाय प्रमाण (उद्यम/परवाना)','बँक विवरण (6 महिने)','पासपोर्ट आकाराचे छायाचित्र'],
  );
  List<String> get scheme001Eligible => _pickList(
    ['All micro-businesses','Vegetable vendors','Shop owners','Service providers'],
    ['सभी सूक्ष्म व्यवसाय','सब्जी विक्रेता','दुकान मालिक','सेवा प्रदाता'],
    ['सर्व सूक्ष्म व्यवसाय','भाजी विक्रेते','दुकानदार','सेवा प्रदाते'],
  );

  // scheme_002 — PM SVANidhi
  String get scheme002Name => pick('PM SVANidhi Scheme', 'पीएम स्वनिधि योजना', 'पीएम स्वनिधी योजना');
  String get scheme002Short => pick(
    'Micro-credit for street vendors to resume livelihoods',
    'फेरीवालों के लिए आजीविका फिर से शुरू करने हेतु माइक्रो-क्रेडिट',
    'फेरीवाल्यांना उपजीविका पुन्हा सुरू करण्यासाठी सूक्ष्म-क्रेडिट',
  );
  String get scheme002Full => pick(
    'PM Street Vendor\'s AtmaNirbhar Nidhi (PM SVANidhi) provides affordable working capital loans to street vendors. The scheme provides initial loans of ₹10,000 with enhanced credit of ₹20,000 and ₹50,000 on timely repayment. Digital transactions are incentivized with cashback rewards.',
    'पीएम स्ट्रीट वेंडर\'s आत्मनिर्भर निधि (PM SVANidhi) फेरीवालों को किफायती कार्यशील पूंजी ऋण प्रदान करती है। यह योजना ₹10,000 का प्रारंभिक ऋण और समय पर पुनर्भुगतान पर ₹20,000 और ₹50,000 का बढ़ा हुआ क्रेडिट देती है।',
    'पीएम स्ट्रीट वेंडर\'स आत्मनिर्भर निधी (PM SVANidhi) फेरीवाल्यांना परवडणारे भांडवली कर्ज देते. या योजनेत ₹10,000 चे प्रारंभिक कर्ज आणि वेळेवर परतफेड केल्यावर ₹20,000 व ₹50,000 पर्यंत वाढीव क्रेडिट मिळते.',
  );
  List<String> get scheme002Benefits => _pickList(
    ['Collateral-free loan','Interest subsidy up to 7%','Digital payment rewards','Enhanced credit on repayment','Social security scheme access'],
    ['बिना जमानत ऋण','7% तक ब्याज सब्सिडी','डिजिटल भुगतान पुरस्कार','पुनर्भुगतान पर बढ़ा हुआ क्रेडिट','सामाजिक सुरक्षा योजना तक पहुंच'],
    ['तारण-मुक्त कर्ज','7% पर्यंत व्याज अनुदान','डिजिटल पेमेंट बक्षीस','परतफेडीवर वाढीव क्रेडिट','सामाजिक सुरक्षा योजनेचा लाभ'],
  );
  List<String> get scheme002Docs => _pickList(
    ['Aadhaar Card','Vending certificate (if available)','Survey list by urban local body','Bank account details'],
    ['आधार कार्ड','विक्रय प्रमाण पत्र (यदि उपलब्ध हो)','शहरी स्थानीय निकाय की सर्वेक्षण सूची','बैंक खाता विवरण'],
    ['आधार कार्ड','विक्री प्रमाणपत्र (उपलब्ध असल्यास)','नगरपालिकेची सर्वेक्षण यादी','बँक खाते तपशील'],
  );
  List<String> get scheme002Eligible => _pickList(
    ['Street vendors','Hawkers','Roadside stall owners','Cart vendors'],
    ['फेरीवाले','हॉकर','सड़क किनारे स्टॉल मालिक','ठेला विक्रेता'],
    ['फेरीवाले','हॉकर','रस्त्याकडील दुकानदार','ठेलाधारक'],
  );

  // scheme_003 — Mudra Shishu
  String get scheme003Name => pick('Mudra Shishu Loan', 'मुद्रा शिशु लोन', 'मुद्रा शिशू कर्ज');
  String get scheme003Short => pick(
    'Seed capital for new and very small businesses',
    'नए और बहुत छोटे व्यवसायों के लिए बीज पूंजी',
    'नवीन आणि अत्यंत लहान व्यवसायांसाठी बीज भांडवल',
  );
  String get scheme003Full => pick(
    'The Shishu category under PM Mudra Yojana covers loans up to ₹50,000 for new or very small businesses. Ideal for first-time entrepreneurs who need working capital or to purchase equipment. Processed quickly with minimal documentation.',
    'पीएम मुद्रा योजना के शिशु श्रेणी में नए या बहुत छोटे व्यवसायों के लिए ₹50,000 तक के ऋण शामिल हैं। पहली बार उद्यमियों के लिए आदर्श। न्यूनतम दस्तावेजों के साथ जल्दी प्रोसेस किया जाता है।',
    'पीएम मुद्रा योजनेच्या शिशू श्रेणीअंतर्गत नवीन किंवा अत्यंत लहान व्यवसायांसाठी ₹50,000 पर्यंत कर्ज दिले जाते. प्रथमच उद्योजकांसाठी आदर्श. कमीत कमी कागदपत्रांसह लवकर प्रक्रिया.',
  );
  List<String> get scheme003Benefits => _pickList(
    ['Quickest approval (3-7 days)','Minimal documentation','No collateral','Flexible repayment'],
    ['सबसे तेज़ मंजूरी (3-7 दिन)','न्यूनतम दस्तावेज़','कोई जमानत नहीं','लचीला पुनर्भुगतान'],
    ['सर्वात जलद मंजुरी (3-7 दिवस)','किमान कागदपत्रे','कोणतेही तारण नाही','लवचिक परतफेड'],
  );
  List<String> get scheme003Docs => _pickList(
    ['Aadhaar Card','PAN Card','Proof of business identity'],
    ['आधार कार्ड','पैन कार्ड','व्यापार पहचान का प्रमाण'],
    ['आधार कार्ड','PAN कार्ड','व्यवसाय ओळखीचा पुरावा'],
  );
  List<String> get scheme003Eligible => _pickList(
    ['New businesses (< 2 years)','Home-based businesses','Artisans','Small traders'],
    ['नए व्यवसाय (< 2 वर्ष)','घर-आधारित व्यवसाय','कारीगर','छोटे व्यापारी'],
    ['नवीन व्यवसाय (< 2 वर्षे)','घर-आधारित व्यवसाय','कारागीर','लहान व्यापारी'],
  );

  // scheme_004 — MSME Credit Guarantee Fund
  String get scheme004Name => pick('MSME Credit Guarantee Fund', 'MSME क्रेडिट गारंटी फंड', 'MSME क्रेडिट गॅरंटी फंड');
  String get scheme004Short => pick(
    'Guarantee-backed loans for MSME businesses up to ₹2 Crore',
    'MSME व्यवसायों के लिए ₹2 करोड़ तक गारंटी समर्थित ऋण',
    'MSME व्यवसायांसाठी ₹2 कोटी पर्यंत हमी-समर्थित कर्ज',
  );
  String get scheme004Full => pick(
    'The Credit Guarantee Fund Trust for Micro and Small Enterprises (CGTMSE) provides guarantee coverage to banks for loans given to MSMEs without collateral. This enables MSMEs to get larger loans for business growth.',
    'सूक्ष्म और लघु उद्यमों के लिए क्रेडिट गारंटी फंड ट्रस्ट (CGTMSE) बैंकों को बिना जमानत के MSME को दिए गए ऋणों के लिए गारंटी कवरेज प्रदान करता है।',
    'सूक्ष्म आणि लघु उद्योगांसाठी क्रेडिट गॅरंटी फंड ट्रस्ट (CGTMSE) बँकांना तारणाशिवाय MSME ला दिलेल्या कर्जांसाठी हमी कव्हरेज देतो.',
  );
  List<String> get scheme004Benefits => _pickList(
    ['No collateral for loans up to ₹2 Cr','Credit guarantee from government','Covers multiple loan types','Available at all scheduled banks'],
    ['₹2 करोड़ तक के ऋण के लिए कोई जमानत नहीं','सरकार से क्रेडिट गारंटी','कई ऋण प्रकारों को कवर करता है','सभी अनुसूचित बैंकों में उपलब्ध'],
    ['₹2 कोटी पर्यंत कर्जासाठी तारण नाही','सरकारकडून क्रेडिट हमी','अनेक कर्ज प्रकारांसाठी लागू','सर्व अनुसूचित बँकांमध्ये उपलब्ध'],
  );
  List<String> get scheme004Docs => _pickList(
    ['Udyam Registration Certificate','Aadhaar + PAN','Business financial statements','Bank statement (12 months)','IT returns (if applicable)'],
    ['उद्यम पंजीकरण प्रमाण पत्र','आधार + पैन','व्यापार वित्तीय विवरण','बैंक स्टेटमेंट (12 महीने)','आयकर रिटर्न (यदि लागू हो)'],
    ['उद्यम नोंदणी प्रमाणपत्र','आधार + PAN','व्यवसाय आर्थिक विवरण','बँक विवरण (12 महिने)','आयकर विवरणपत्र (लागू असल्यास)'],
  );
  List<String> get scheme004Eligible => _pickList(
    ['Registered MSMEs (Udyam)','Manufacturing businesses','Service businesses'],
    ['पंजीकृत MSME (उद्यम)','विनिर्माण व्यवसाय','सेवा व्यवसाय'],
    ['नोंदणीकृत MSME (उद्यम)','उत्पादन व्यवसाय','सेवा व्यवसाय'],
  );

  // scheme_005 — Stand-Up India
  String get scheme005Name => pick('Stand-Up India Scheme', 'स्टैंड-अप इंडिया योजना', 'स्टँड-अप इंडिया योजना');
  String get scheme005Short => pick(
    'Bank loans for SC/ST and women entrepreneurs for new ventures',
    'नए उद्यमों के लिए SC/ST और महिला उद्यमियों के लिए बैंक ऋण',
    'नवीन उद्योगांसाठी SC/ST आणि महिला उद्योजकांसाठी बँक कर्ज',
  );
  String get scheme005Full => pick(
    'The Stand-Up India scheme facilitates bank loans between ₹10 Lakh and ₹1 Crore to at least one SC or ST borrower and at least one woman borrower per bank branch for setting up greenfield enterprises in manufacturing, services, agri-allied activities, or trading sector.',
    'स्टैंड-अप इंडिया योजना प्रत्येक बैंक शाखा में कम से कम एक SC/ST और एक महिला उद्यमी को ₹10 लाख से ₹1 करोड़ तक का ऋण प्रदान करती है।',
    'स्टँड-अप इंडिया योजना प्रत्येक बँक शाखेत किमान एक SC/ST आणि एक महिला उद्योजकाला ₹10 लाख ते ₹1 कोटी पर्यंत बँक कर्ज देते.',
  );
  List<String> get scheme005Benefits => _pickList(
    ['Composite loan (term + working capital)','7-year repayment period','Margin money subsidy available','For new enterprises (greenfield)'],
    ['कम्पोजिट लोन (टर्म + कार्यशील पूंजी)','7 वर्ष की पुनर्भुगतान अवधि','मार्जिन मनी सब्सिडी उपलब्ध','नए उद्यमों के लिए'],
    ['कम्पोझिट कर्ज (मुदत + भांडवल)','7 वर्षांचा परतफेड कालावधी','मार्जिन मनी अनुदान उपलब्ध','नवीन उद्योगांसाठी'],
  );
  List<String> get scheme005Docs => _pickList(
    ['Aadhaar + PAN','Caste certificate (for SC/ST)','Business plan / project report','Bank statement','IT returns'],
    ['आधार + पैन','जाति प्रमाण पत्र (SC/ST के लिए)','व्यापार योजना / परियोजना रिपोर्ट','बैंक स्टेटमेंट','आयकर रिटर्न'],
    ['आधार + PAN','जात प्रमाणपत्र (SC/ST साठी)','व्यवसाय योजना / प्रकल्प अहवाल','बँक विवरण','आयकर विवरणपत्र'],
  );
  List<String> get scheme005Eligible => _pickList(
    ['SC/ST entrepreneurs','Women entrepreneurs','New businesses'],
    ['SC/ST उद्यमी','महिला उद्यमी','नए व्यवसाय'],
    ['SC/ST उद्योजक','महिला उद्योजक','नवीन व्यवसाय'],
  );

  // scheme_006 — PMEGP
  String get scheme006Name => pick('PMEGP (Employment Generation)', 'PMEGP (रोजगार सृजन)', 'PMEGP (रोजगार निर्मिती)');
  String get scheme006Short => pick(
    'Subsidy + loan for setting up new micro-enterprises',
    'नए सूक्ष्म उद्यम स्थापित करने के लिए सब्सिडी + ऋण',
    'नवीन सूक्ष्म उद्योग स्थापनेसाठी अनुदान + कर्ज',
  );
  String get scheme006Full => pick(
    'Prime Minister\'s Employment Generation Programme (PMEGP) helps unemployed youth and traditional artisans set up new micro-enterprises. It provides a subsidy of 15-35% of project cost. Implemented by KVIC.',
    'प्रधानमंत्री रोजगार सृजन कार्यक्रम (PMEGP) बेरोजगार युवाओं और पारंपरिक कारीगरों को नए सूक्ष्म उद्यम स्थापित करने में मदद करता है। परियोजना लागत की 15-35% सब्सिडी प्रदान करता है।',
    'पंतप्रधान रोजगार निर्मिती कार्यक्रम (PMEGP) बेरोजगार तरुण आणि पारंपारिक कारागीरांना नवीन सूक्ष्म उद्योग स्थापन करण्यास मदत करतो. प्रकल्प खर्चाच्या 15-35% अनुदान मिळते.',
  );
  List<String> get scheme006Benefits => _pickList(
    ['Government subsidy up to 35%','Covers manufacturing & services','First generation entrepreneurs welcome','Training & mentoring included'],
    ['35% तक सरकारी सब्सिडी','विनिर्माण और सेवाओं को कवर करता है','पहली पीढ़ी के उद्यमियों का स्वागत','प्रशिक्षण और मार्गदर्शन शामिल'],
    ['35% पर्यंत शासकीय अनुदान','उत्पादन आणि सेवांसाठी लागू','प्रथमपीढी उद्योजकांना स्वागत','प्रशिक्षण आणि मार्गदर्शन समाविष्ट'],
  );
  List<String> get scheme006Docs => _pickList(
    ['Aadhaar Card','Educational certificate (VIII pass)','Project report','Caste/special category certificate'],
    ['आधार कार्ड','शैक्षणिक प्रमाण पत्र (VIII पास)','परियोजना रिपोर्ट','जाति/विशेष श्रेणी प्रमाण पत्र'],
    ['आधार कार्ड','शैक्षणिक प्रमाणपत्र (VIII उत्तीर्ण)','प्रकल्प अहवाल','जात/विशेष श्रेणी प्रमाणपत्र'],
  );
  List<String> get scheme006Eligible => _pickList(
    ['Unemployed youth (18+ years)','Artisans and craftsmen','Rural and urban applicants'],
    ['बेरोजगार युवा (18+ वर्ष)','कारीगर और शिल्पकार','ग्रामीण और शहरी आवेदक'],
    ['बेरोजगार तरुण (18+ वर्षे)','कारागीर आणि शिल्पकार','ग्रामीण आणि शहरी अर्जदार'],
  );

  // ── Common ───────────────────────────────────────────────────────────────
  String get save             => pick('Save', 'सहेजें', 'जतन करा');
  String get cancel           => pick('Cancel', 'रद्द करें', 'रद्द करा');
  String get noData           => pick('No data available', 'कोई डेटा उपलब्ध नहीं', 'डेटा उपलब्ध नाही');
  String get loading          => pick('Loading...', 'लोड हो रहा है...', 'लोड होत आहे...');
  String get errorText        => pick('Something went wrong', 'कुछ गलत हो गया', 'काहीतरी चुकले');
  String get retry            => pick('Retry', 'पुनः प्रयास करें', 'पुन्हा प्रयत्न करा');

  // ── Helpers ──────────────────────────────────────────────────────────────
  /// Picks the string for the current locale. Public so widgets can inline
  /// one-off strings that are not yet extracted to named getters.
  String pick(String en, String hi, String mr) {
    switch (code) {
      case 'hi': return hi;
      case 'mr': return mr;
      default:   return en;
    }
  }

  List<String> _pickList(List<String> en, List<String> hi, List<String> mr) {
    switch (code) {
      case 'hi': return hi;
      case 'mr': return mr;
      default:   return en;
    }
  }
}
