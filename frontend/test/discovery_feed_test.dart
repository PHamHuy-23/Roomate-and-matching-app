import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/models/match_criteria_detail.dart';
import 'package:roommate_hub_mobile/models/match_recommendation.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';
import 'package:roommate_hub_mobile/screens/home_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';
import 'package:roommate_hub_mobile/widgets/match_card.dart';

MatchRecommendation candidate(
  double score, {
  int id = 2,
  int? age,
  String? university,
}) {
  return MatchRecommendation(
    userId: id,
    fullName: 'Ứng viên $id',
    age: age,
    university: university,
    targetDistrict: 'Thủ Đức',
    budgetAmount: 2500000,
    totalScore: score,
    criteriaDetail: MatchCriteriaDetail(
      budgetMatch: 90,
      sleepMatch: 80,
      cleanlinessMatch: 85,
      smokingMatch: 100,
      petMatch: 70,
    ),
  );
}

class FakeDiscoveryApi implements ApiService {
  List<MatchRecommendation> candidates = [candidate(85)];
  bool failRecommendations = false;
  int requestCount = 0;
  Completer<bool>? pendingRequest;

  @override
  Future<List<MatchRecommendation>> getRecommendations(
    int currentUserId,
  ) async {
    if (failRecommendations) {
      throw const ApiException('Không thể kết nối đến máy chủ');
    }
    return candidates;
  }

  @override
  Future<List<RoomPost>> getRoomPosts() async => [];

  @override
  Future<bool> sendMatchRequest(int senderId, int receiverId, double score) {
    requestCount++;
    return pendingRequest?.future ?? Future.value(true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> showFeed(WidgetTester tester, FakeDiscoveryApi api) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        apiService: api,
        currentUser: AuthUser(
          token: 'token',
          userId: 1,
          email: 'user@example.com',
          fullName: 'Người dùng',
          gender: 'MALE',
          role: 'ROLE_USER',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('Recommendation cũ vẫn đọc được khi thiếu tuổi và trường', () {
    final data = <String, dynamic>{
      'userId': 2,
      'fullName': 'Ứng viên',
      'targetDistrict': 'Thủ Đức',
      'budgetAmount': 2500000,
      'totalScore': 85,
      'criteriaDetail': {
        'budgetMatch': 90,
        'sleepMatch': 80,
        'cleanlinessMatch': 85,
        'smokingMatch': 100,
        'petMatch': 70,
      },
    };
    final legacy = MatchRecommendation.fromJson(data);
    expect(legacy.age, isNull);
    expect(legacy.university, isNull);
    data.addAll({'age': 20, 'university': 'Đại học'});
    final updated = MatchRecommendation.fromJson(data);
    expect(updated.age, 20);
    expect(updated.university, 'Đại học');
  });

  testWidgets('Feed trống hướng dẫn cập nhật tiêu chí', (tester) async {
    await showFeed(tester, FakeDiscoveryApi()..candidates = []);
    expect(find.text('Chưa có ứng viên phù hợp'), findsOneWidget);
    expect(find.text('Cập nhật tiêu chí'), findsOneWidget);
    expect(find.byType(MatchCard), findsNothing);
  });
  testWidgets('Badge phân biệt đúng các mức 85, 60 và dưới 60', (tester) async {
    for (final entry in <double, Color>{
      85: const Color(0xFF1565C0),
      84: const Color(0xFF9A5B00),
      60: const Color(0xFF9A5B00),
      59: const Color(0xFF616161),
    }.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(item: candidate(entry.key), onConnect: () {}),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('${entry.key.toInt()}%'));
      expect(text.style!.color, entry.value);
    }
  });

  testWidgets('Thẻ vừa màn hình nhỏ, chỉ hiện tuổi và trường khi có dữ liệu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MatchCard(
              item: candidate(
                85,
                age: 20,
                university:
                    'Trường Đại học Sư phạm Kỹ thuật Thành phố Hồ Chí Minh',
              ),
              onConnect: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('20 tuổi'), findsOneWidget);
    expect(find.textContaining('Trường Đại học'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Xem 5 tiêu chí tương thích'));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Feed sắp xếp tương thích giảm dần và không thay đổi dữ liệu gốc',
    (tester) async {
      final api = FakeDiscoveryApi()
        ..candidates = [candidate(59), candidate(95, id: 3)];
      await showFeed(tester, api);
      final first = tester.widget<MatchCard>(find.byType(MatchCard).first);
      expect(first.item.userId, 3);
      expect(api.candidates.first.userId, 2);
      expect(find.text('95%'), findsOneWidget);
    },
  );

  testWidgets('Lỗi tải Feed có thể thử lại', (tester) async {
    final api = FakeDiscoveryApi()..failRecommendations = true;
    await showFeed(tester, api);
    expect(find.text('Chưa tải được gợi ý'), findsOneWidget);
    api.failRecommendations = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Ứng viên 2'), findsOneWidget);
  });

  testWidgets('Chỉ gửi một yêu cầu khi đang chờ và hiển thị đã gửi', (
    tester,
  ) async {
    final pending = Completer<bool>();
    final api = FakeDiscoveryApi()..pendingRequest = pending;
    await showFeed(tester, api);
    await tester.ensureVisible(find.text('Gửi yêu cầu kết nối'));
    await tester.tap(find.text('Gửi yêu cầu kết nối'));
    await tester.pump();
    expect(find.text('Đang gửi...'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(api.requestCount, 1);
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Đã gửi yêu cầu'), findsOneWidget);
  });

  testWidgets('Gửi lỗi hiển thị thông báo và cho phép thử lại', (tester) async {
    final pending = Completer<bool>();
    final api = FakeDiscoveryApi()..pendingRequest = pending;
    await showFeed(tester, api);
    await tester.ensureVisible(find.text('Gửi yêu cầu kết nối'));
    await tester.tap(find.text('Gửi yêu cầu kết nối'));
    await tester.pump();
    pending.completeError(const ApiException('Không thể kết nối đến máy chủ'));
    await tester.pumpAndSettle();
    expect(find.text('Không thể kết nối đến máy chủ'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
