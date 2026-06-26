class PassportModel {
  final String id;
  final String passportId;
  final String reportId;
  final double businessHealthScore;
  final double loanReadinessScore;
  final double confidenceScore;
  final String riskLevel;
  final String recommendedLoanRange;
  final List<Map<String, dynamic>> scoreBreakdown;
  final String verificationHash;
  final DateTime generatedDate;
  final bool isLocked;

  const PassportModel({
    required this.id,
    required this.passportId,
    required this.reportId,
    required this.businessHealthScore,
    required this.loanReadinessScore,
    required this.confidenceScore,
    required this.riskLevel,
    required this.recommendedLoanRange,
    required this.scoreBreakdown,
    required this.verificationHash,
    required this.generatedDate,
    this.isLocked = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'passportId': passportId,
    'reportId': reportId,
    'businessHealthScore': businessHealthScore,
    'loanReadinessScore': loanReadinessScore,
    'confidenceScore': confidenceScore,
    'riskLevel': riskLevel,
    'recommendedLoanRange': recommendedLoanRange,
    'scoreBreakdown': scoreBreakdown,
    'verificationHash': verificationHash,
    'generatedDate': generatedDate.toIso8601String(),
    'isLocked': isLocked,
  };

  factory PassportModel.fromJson(Map<String, dynamic> json) => PassportModel(
    id: json['id'] as String,
    passportId: json['passportId'] as String,
    reportId: json['reportId'] as String,
    businessHealthScore: (json['businessHealthScore'] as num).toDouble(),
    loanReadinessScore: (json['loanReadinessScore'] as num).toDouble(),
    confidenceScore: (json['confidenceScore'] as num).toDouble(),
    riskLevel: json['riskLevel'] as String,
    recommendedLoanRange: json['recommendedLoanRange'] as String,
    scoreBreakdown:
        (json['scoreBreakdown'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
    verificationHash: json['verificationHash'] as String,
    generatedDate: DateTime.parse(json['generatedDate'] as String),
    isLocked: json['isLocked'] as bool? ?? true,
  );
}
