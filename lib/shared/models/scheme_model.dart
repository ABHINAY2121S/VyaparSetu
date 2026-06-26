class SchemeModel {
  final String id;
  final String name;
  final String shortDescription;
  final String fullDescription;
  final double eligibilityPercent;
  final String loanRange;
  final String interestRate;
  final List<String> benefits;
  final List<String> requiredDocuments;
  final List<String> eligibleFor;
  final String applyUrl;
  final String category;
  final bool isPopular;

  const SchemeModel({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.fullDescription,
    required this.eligibilityPercent,
    required this.loanRange,
    required this.interestRate,
    required this.benefits,
    required this.requiredDocuments,
    required this.eligibleFor,
    required this.applyUrl,
    required this.category,
    this.isPopular = false,
  });

  static List<SchemeModel> get allSchemes => [
    const SchemeModel(
      id: 'scheme_001',
      name: 'PM Mudra Yojana — Kishore',
      shortDescription:
          'Micro loans for growing small businesses without collateral',
      fullDescription:
          'Pradhan Mantri Mudra Yojana (PMMY) under the Kishore category provides '
          'loans from ₹50,000 to ₹5 Lakh for micro-enterprises that have already '
          'established their businesses and need funds for expansion. No collateral '
          'required. Banks, MFIs, and NBFCs participate in this scheme.',
      eligibilityPercent: 91,
      loanRange: '₹50,000 – ₹5 Lakh',
      interestRate: '8% – 12% p.a.',
      benefits: [
        'No collateral required',
        'Low interest rate',
        'Easy repayment tenure (3-5 years)',
        'Available at all banks and NBFCs',
        'No processing fee',
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'PAN Card',
        'Business proof (Udyam/License)',
        'Bank statement (6 months)',
        'Passport-size photographs',
      ],
      eligibleFor: [
        'All micro-businesses',
        'Vegetable vendors',
        'Shop owners',
        'Service providers',
      ],
      applyUrl: 'https://www.mudra.org.in',
      category: 'Loan',
      isPopular: true,
    ),
    const SchemeModel(
      id: 'scheme_002',
      name: 'PM SVANidhi Scheme',
      shortDescription:
          'Micro-credit for street vendors to resume livelihoods',
      fullDescription:
          'PM Street Vendor\'s AtmaNirbhar Nidhi (PM SVANidhi) provides affordable '
          'working capital loans to street vendors. The scheme provides initial loans '
          'of ₹10,000 with enhanced credit of ₹20,000 and ₹50,000 on timely repayment. '
          'Digital transactions are incentivized with cashback rewards.',
      eligibilityPercent: 85,
      loanRange: '₹10,000 – ₹50,000',
      interestRate: '7% p.a. (subsidized)',
      benefits: [
        'Collateral-free loan',
        'Interest subsidy up to 7%',
        'Digital payment rewards',
        'Enhanced credit on repayment',
        'Social security scheme access',
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'Vending certificate (if available)',
        'Survey list by urban local body',
        'Bank account details',
      ],
      eligibleFor: [
        'Street vendors',
        'Hawkers',
        'Roadside stall owners',
        'Cart vendors',
      ],
      applyUrl: 'https://pmsvanidhi.mohua.gov.in',
      category: 'Loan',
      isPopular: true,
    ),
    const SchemeModel(
      id: 'scheme_003',
      name: 'Mudra Shishu Loan',
      shortDescription: 'Seed capital for new and very small businesses',
      fullDescription:
          'The Shishu category under PM Mudra Yojana covers loans up to ₹50,000 '
          'for new or very small businesses. Ideal for first-time entrepreneurs '
          'who need working capital or to purchase equipment. Processed quickly '
          'with minimal documentation.',
      eligibilityPercent: 88,
      loanRange: 'Up to ₹50,000',
      interestRate: '8% – 10% p.a.',
      benefits: [
        'Quickest approval (3-7 days)',
        'Minimal documentation',
        'No collateral',
        'Flexible repayment',
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'PAN Card',
        'Proof of business identity',
      ],
      eligibleFor: [
        'New businesses (< 2 years)',
        'Home-based businesses',
        'Artisans',
        'Small traders',
      ],
      applyUrl: 'https://www.mudra.org.in',
      category: 'Loan',
      isPopular: false,
    ),
    const SchemeModel(
      id: 'scheme_004',
      name: 'MSME Credit Guarantee Fund',
      shortDescription:
          'Guarantee-backed loans for MSME businesses up to ₹2 Crore',
      fullDescription:
          'The Credit Guarantee Fund Trust for Micro and Small Enterprises (CGTMSE) '
          'provides guarantee coverage to banks for loans given to MSMEs without '
          'collateral. This enables MSMEs to get larger loans for business growth.',
      eligibilityPercent: 72,
      loanRange: 'Up to ₹2 Crore',
      interestRate: 'As per bank rates',
      benefits: [
        'No collateral for loans up to ₹2 Cr',
        'Credit guarantee from government',
        'Covers multiple loan types',
        'Available at all scheduled banks',
      ],
      requiredDocuments: [
        'Udyam Registration Certificate',
        'Aadhaar + PAN',
        'Business financial statements',
        'Bank statement (12 months)',
        'IT returns (if applicable)',
      ],
      eligibleFor: [
        'Registered MSMEs (Udyam)',
        'Manufacturing businesses',
        'Service businesses',
      ],
      applyUrl: 'https://www.cgtmse.in',
      category: 'Guarantee',
      isPopular: false,
    ),
    const SchemeModel(
      id: 'scheme_005',
      name: 'Stand-Up India Scheme',
      shortDescription:
          'Bank loans for SC/ST and women entrepreneurs for new ventures',
      fullDescription:
          'The Stand-Up India scheme facilitates bank loans between ₹10 Lakh and '
          '₹1 Crore to at least one SC or ST borrower and at least one woman borrower '
          'per bank branch for setting up greenfield enterprises in manufacturing, '
          'services, agri-allied activities, or trading sector.',
      eligibilityPercent: 68,
      loanRange: '₹10 Lakh – ₹1 Crore',
      interestRate: 'Base rate + 3% p.a.',
      benefits: [
        'Composite loan (term + working capital)',
        '7-year repayment period',
        'Margin money subsidy available',
        'For new enterprises (greenfield)',
      ],
      requiredDocuments: [
        'Aadhaar + PAN',
        'Caste certificate (for SC/ST)',
        'Business plan / project report',
        'Bank statement',
        'IT returns',
      ],
      eligibleFor: [
        'SC/ST entrepreneurs',
        'Women entrepreneurs',
        'New businesses',
      ],
      applyUrl: 'https://www.standupmitra.in',
      category: 'Loan',
      isPopular: false,
    ),
    const SchemeModel(
      id: 'scheme_006',
      name: 'PMEGP (Employment Generation)',
      shortDescription: 'Subsidy + loan for setting up new micro-enterprises',
      fullDescription:
          'Prime Minister\'s Employment Generation Programme (PMEGP) helps '
          'unemployed youth and traditional artisans set up new micro-enterprises. '
          'It provides a subsidy of 15-35% of project cost. Implemented by KVIC.',
      eligibilityPercent: 60,
      loanRange: '₹10 Lakh – ₹25 Lakh',
      interestRate: 'As per bank rates',
      benefits: [
        'Government subsidy up to 35%',
        'Covers manufacturing & services',
        'First generation entrepreneurs welcome',
        'Training & mentoring included',
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'Educational certificate (VIII pass)',
        'Project report',
        'Caste/special category certificate',
      ],
      eligibleFor: [
        'Unemployed youth (18+ years)',
        'Artisans and craftsmen',
        'Rural and urban applicants',
      ],
      applyUrl: 'https://www.kviconline.gov.in/pmegpeportal',
      category: 'Subsidy + Loan',
      isPopular: false,
    ),
  ];
}
