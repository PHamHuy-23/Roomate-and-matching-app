import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/match_criteria_detail.dart';
import 'package:roommate_hub_mobile/models/match_recommendation.dart';
import 'package:roommate_hub_mobile/screens/candidate_profile_screen.dart';
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
  test('MatchRecommendation đọc đúng contract của recommendations API', () {
    final item = MatchRecommendation.fromJson({
      'userId': 2,
      'fullName': 'Tuấn Minh',
      'avatarUrl': null,
      'age': 22,
      'university': 'Đại học Quốc gia',
      'targetDistrict': 'Thủ Đức',
      'budgetAmount': 2200000,
      'bioDescription': 'Hòa đồng',
      'totalScore': 92,
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
  });

  testWidgets('MatchCard hiển thị ảnh, điểm và mở hồ sơ', (tester) async {
    var viewed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MatchCard(
              item: recommendation(),
              onViewDetails: () => viewed = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tuấn Minh, 22'), findsOneWidget);
    expect(find.text('Đại học Quốc gia • Thủ Đức'), findsOneWidget);
    expect(find.text('88% phù hợp'), findsOneWidget);
    expect(find.text('Ngân sách hợp'), findsOneWidget);
    expect(find.textContaining('Hòa đồng'), findsOneWidget);
    expect(find.text('Xem hồ sơ & độ phù hợp'), findsOneWidget);

    await tester.tap(find.text('Xem hồ sơ & độ phù hợp'));
    expect(viewed, isTrue);
  });

  testWidgets('MatchCard phân loại đủ ba ngưỡng điểm', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                for (final score in [88.0, 68.0, 55.0])
                  MatchCard(
                    item: recommendation(score: score),
                    onViewDetails: () {},
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('88% phù hợp'), findsOneWidget);
    expect(find.text('68% phù hợp'), findsOneWidget);
    expect(find.text('55% phù hợp'), findsOneWidget);
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

    expect(find.text('Vì sao hai bạn phù hợp?'), findsOneWidget);
    expect(find.text('72%'), findsOneWidget);
    expect(find.text('Khá phù hợp'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
    for (final label in [
      'Ngân sách',
      'Giờ giấc sinh hoạt',
      'Vệ sinh & ngăn nắp',
      'Hút thuốc',
      'Thú cưng',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Điểm nổi bật'), findsOneWidget);
    expect(find.text('Điểm cần trao đổi'), findsOneWidget);
    expect(find.textContaining('Hút thuốc: 40%'), findsOneWidget);
    expect(find.textContaining('Thú cưng: 55%'), findsOneWidget);
  });

  testWidgets('Hồ sơ ứng viên mở đối chiếu và gửi lời mời thật', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CandidateProfileScreen(
          item: recommendation(),
          requestSent: false,
          onConnect: () async {
            requests++;
            return true;
          },
        ),
      ),
    );

    expect(find.text('Tuấn Minh, 22'), findsOneWidget);
    expect(find.text('2,2 triệu / tháng'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('88% phù hợp · Xem lý do'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('88% phù hợp · Xem lý do'));
    await tester.pumpAndSettle();
    expect(find.text('Vì sao hai bạn phù hợp?'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(5));

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi lời mời kết nối'));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.text('Đã gửi lời mời kết nối'), findsOneWidget);
  });

  testWidgets('Thẻ và bảng đối chiếu không tràn ở màn hình 320px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MatchCard(item: recommendation(), onViewDetails: () {}),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompatibilityBottomSheet(
            item: recommendation(),
            onConnect: () async {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
