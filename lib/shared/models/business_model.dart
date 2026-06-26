class BusinessModel {
  final String id;
  final String businessName;
  final String businessType;
  final int businessAge;
  final String city;
  final String revenueRange;
  final DateTime registeredAt;

  const BusinessModel({
    required this.id,
    required this.businessName,
    required this.businessType,
    required this.businessAge,
    required this.city,
    required this.revenueRange,
    required this.registeredAt,
  });

  BusinessModel copyWith({
    String? id,
    String? businessName,
    String? businessType,
    int? businessAge,
    String? city,
    String? revenueRange,
    DateTime? registeredAt,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      businessAge: businessAge ?? this.businessAge,
      city: city ?? this.city,
      revenueRange: revenueRange ?? this.revenueRange,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessName': businessName,
    'businessType': businessType,
    'businessAge': businessAge,
    'city': city,
    'revenueRange': revenueRange,
    'registeredAt': registeredAt.toIso8601String(),
  };

  factory BusinessModel.fromJson(Map<String, dynamic> json) => BusinessModel(
    id: json['id'] as String,
    businessName: json['businessName'] as String,
    businessType: json['businessType'] as String,
    businessAge: json['businessAge'] as int,
    city: json['city'] as String,
    revenueRange: json['revenueRange'] as String,
    registeredAt: DateTime.parse(json['registeredAt'] as String),
  );

  static BusinessModel get defaultBusiness => BusinessModel(
    id: 'biz_001',
    businessName: 'Ramesh Vegetable Store',
    businessType: 'Vegetable/Fruit Vendor',
    businessAge: 3,
    city: 'Mumbai',
    revenueRange: '₹25,000 – ₹50,000/month',
    registeredAt: DateTime(2024, 1, 15),
  );
}
