import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/match_criteria_detail.dart';
import 'package:roommate_hub_mobile/models/match_recommendation.dart';
import 'package:roommate_hub_mobile/widgets/compatibility_bottom_sheet.dart';
import 'package:roommate_hub_mobile/widgets/match_card.dart';

MatchRecommendation recommendation({
  double score = 88,
  MatchCriteriaDetail? criteria,
}) {
  return MatchRecommendation(
    userId: 2,
    fullName: 'Tuấn Minh',
    age: 22,
    university: 'Đại học Quốc gia',
    targetDistrict: 'Thủ Đức',
    budgetAmount: 2200000,
    bioDescription: 'Hòa đồng, thích không gian yên tĩnh.',
    totalScore: score,
    matchedReasons: const ['Ngân sách phù hợp', 'Mức độ sạch sẽ tương đồng'],
    criteriaDetail:
        criteria ??
        MatchCriteriaDetail(
          budgetMatch: 96,
          sleepMatch: 84,
          cleanlinessMatch: 100,
          smokingMatch: 100,
          petMatch: 80,
        ),
  );
}

void main() {
  test(
    'MatchRecommendation hỗ trợ response mới và response backend hiện tại',
    () {
      final item = MatchRecommendation.fromJson({
        'userId': 2,
        'fullName': 'Tuấn Minh',
        'avatarUrl': null,
        'age': 22,
        'university': 'Đại học Quốc gia',
        'targetDistrict': 'Thủ Đức',
        'budgetAmount': 2200000,
        'bioDescription': 'Hòa đồng',
        'matchScore': 92,
        'matchedReasons': ['Cùng ngân sách'],
        'criteriaDetail': {
          'budgetMatch': 96,
          'sleepMatch': 84,
          'cleanlinessMatch': 100,
          'smokingMatch': 100,
          'petMatch': 80,
        },
      });

      expect(item.totalScore, 92);
      expect(item.age, 22);
      expect(item.university, 'Đại học Quốc gia');
      expect(item.matchedReasons, ['Cùng ngân sách']);
    },
  );

  testWidgets('MatchCard hiển thị đủ thông tin và hai hành động', (
    tester,
  ) async {
    var viewed = false;
    var connected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MatchCard(
              item: recommendation(),
              onViewDetails: () => viewed = true,
              onConnect: () => connected = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tuấn Minh'), findsOneWidget);
    expect(find.text('22 tuổi • Đại học Quốc gia'), findsOneWidget);
    expect(find.text('Match 88%'), findsOneWidget);
    expect(find.text('Thủ Đức'), findsOneWidget);
    expect(find.text('Xem đối chiếu'), findsOneWidget);

    await tester.tap(find.text('Xem đối chiếu'));
    await tester.tap(find.text('Gửi lời mời'));
    expect(viewed, isTrue);
    expect(connected, isTrue);
  });

  testWidgets('MatchCard phân loại đủ ba ngưỡng điểm', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              for (final score in [88.0, 68.0, 55.0])
                MatchCard(
                  item: recommendation(score: score),
                  onViewDetails: () {},
                  onConnect: () {},
                ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Match 88%'), findsOneWidget);
    expect(find.text('Match 68%'), findsOneWidget);
    expect(find.text('Match 55%'), findsOneWidget);
  });

  testWidgets('BottomSheet hiển thị 5 tiêu chí, nổi bật và lưu ý', (
    tester,
  ) async {
    final item = recommendation(
      score: 72,
      criteria: MatchCriteriaDetail(
        budgetMatch: 95,
        sleepMatch: 80,
        cleanlinessMatch: 70,
        smokingMatch: 40,
        petMatch: 55,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompatibilityBottomSheet(item: item, onConnect: () async {}),
        ),
      ),
    );

    expect(find.text('Vì sao 72%?'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
    for (final label in [
      'Ngân sách',
      'Giờ sinh hoạt',
      'Sạch sẽ',
      'Hút thuốc',
      'Thú cưng',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Điểm nổi bật'), findsOneWidget);
    expect(find.text('Điểm cần lưu ý'), findsOneWidget);
    expect(find.textContaining('hút thuốc'), findsOneWidget);
    expect(find.textContaining('thú cưng'), findsOneWidget);
  });
}
