class MatchCriteriaDetail {
  final double budgetMatch;
  final double sleepMatch;
  final double cleanlinessMatch;
  final double smokingMatch;
  final double petMatch;

  MatchCriteriaDetail({
    required this.budgetMatch,
    required this.sleepMatch,
    required this.cleanlinessMatch,
    required this.smokingMatch,
    required this.petMatch,
  });

  factory MatchCriteriaDetail.fromJson(Map<String, dynamic> json) {
    return MatchCriteriaDetail(
      budgetMatch: (json['budgetMatch'] as num).toDouble(),
      sleepMatch: (json['sleepMatch'] as num).toDouble(),
      cleanlinessMatch: (json['cleanlinessMatch'] as num).toDouble(),
      smokingMatch: (json['smokingMatch'] as num).toDouble(),
      petMatch: (json['petMatch'] as num).toDouble(),
    );
  }
}