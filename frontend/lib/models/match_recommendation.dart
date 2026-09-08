import 'match_criteria_detail.dart';

class MatchRecommendation {
  final int userId;
  final String fullName;
  final String? avatarUrl;
  final String targetDistrict;
  final double budgetAmount;
  final String? bioDescription;
  final double totalScore;
  final MatchCriteriaDetail criteriaDetail;

  MatchRecommendation({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.targetDistrict,
    required this.budgetAmount,
    this.bioDescription,
    required this.totalScore,
    required this.criteriaDetail,
  });

  factory MatchRecommendation.fromJson(Map<String, dynamic> json) {
    return MatchRecommendation(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      targetDistrict: json['targetDistrict'] as String,
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
      bioDescription: json['bioDescription'] as String?,
      totalScore: (json['totalScore'] as num).toDouble(),
      criteriaDetail: MatchCriteriaDetail.fromJson(
        json['criteriaDetail'] as Map<String, dynamic>,
      ),
    );
  }
}