import 'match_criteria_detail.dart';

class MatchRecommendation {
  final int userId;
  final String fullName;
  final String? avatarUrl;
  final int? age;
  final String? university;
  final String targetDistrict;
  final double budgetAmount;
  final String? bioDescription;
  final double totalScore;
  final MatchCriteriaDetail criteriaDetail;
  final List<String> matchedReasons;

  MatchRecommendation({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.age,
    this.university,
    required this.targetDistrict,
    required this.budgetAmount,
    this.bioDescription,
    required this.totalScore,
    required this.criteriaDetail,
    this.matchedReasons = const [],
  });

  factory MatchRecommendation.fromJson(Map<String, dynamic> json) {
    return MatchRecommendation(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      age: (json['age'] as num?)?.toInt(),
      university: json['university'] as String?,
      targetDistrict: json['targetDistrict'] as String,
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
      bioDescription: json['bioDescription'] as String?,
      totalScore: ((json['totalScore'] ?? json['matchScore']) as num)
          .toDouble(),
      criteriaDetail: MatchCriteriaDetail.fromJson(
        json['criteriaDetail'] as Map<String, dynamic>,
      ),
      matchedReasons:
          (json['matchedReasons'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
    );
  }
}
