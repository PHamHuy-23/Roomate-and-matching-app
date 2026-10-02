import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/district_names.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/models/match_recommendation.dart';
import 'package:roommate_hub_mobile/models/match_criteria_detail.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';
import 'package:roommate_hub_mobile/screens/home_screen.dart';
import 'package:roommate_hub_mobile/screens/survey_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

class _DistrictApi implements ApiService {
  _DistrictApi({
    this.district = 'Thu Duc',
    this.matches = const [],
    this.posts = const [],
  });
  final String district;
  final List<MatchRecommendation> matches;
  final List<RoomPost> posts;
  Map<String, dynamic>? saved;
  @override
  bool get hasAuthToken => false;
  @override
  Set<int> get savedPostIds => {};
  @override
  Future<List<MatchRecommendation>> getRecommendations(int userId) async =>
      matches;
  @override
  Future<List<RoomPost>> getRoomPosts() async => posts;
  @override
  Future<Map<String, dynamic>?> getPreferences(int userId) async => {
    'targetDistrict': district,
  };
  @override
  Future<bool> savePreferences(int userId, Map<String, dynamic> data) async {
    saved = data;
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MatchRecommendation _match(int id, String district) => MatchRecommendation(
  userId: id,
  fullName: 'Candidate $id',
  targetDistrict: district,
  budgetAmount: 2000000,
  totalScore: 90,
  criteriaDetail: MatchCriteriaDetail(
    budgetMatch: 100,
    sleepMatch: 100,
    cleanlinessMatch: 100,
    smokingMatch: 100,
    petMatch: 100,
  ),
);

RoomPost _room(int id, String district) => RoomPost(
  id: id,
  title: 'Room $id',
  description: 'Test',
  address: 'Địa chỉ kiểm thử',
  district: district,
  price: 2000000,
  maxOccupants: 2,
  authorName: 'Owner',
  authorId: 7,
  areaM2: 35,
);

Future<void> _home(WidgetTester tester, _DistrictApi api, {int tab = 0}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        apiService: api,
        initialTab: tab,
        currentUser: AuthUser(
          token: 'test',
          userId: 1,
          email: 'test@example.invalid',
          fullName: 'Tester',
          gender: 'MALE',
          role: 'ROLE_USER',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Canonical aliases agree with backend, including decomposed Vietnamese',
    () {
      for (final name in [
        'Thu Duc',
        'THỦ ĐỨC',
        ' TP. Thủ Đức ',
        'Thành phố Thủ Đức',
        'Thủ Đức, TP.HCM',
        'Thu  Duc, Ho Chi Minh',
        'Thu\u0309 Đu\u031b\u0301c',
      ]) {
        expect(DistrictNames.canonical(name), 'Thu Duc');
        expect(DistrictNames.same(name, 'Thu Duc'), isTrue);
      }
      expect(
        DistrictNames.canonical('Quận Bình Thạnh, TP. Hồ Chí Minh'),
        'Binh Thanh',
      );
      expect(DistrictNames.canonical('Huyện Hóc Môn'), 'Hoc Mon');
      expect(DistrictNames.canonical('Q.1'), 'Quan 1');
      expect(DistrictNames.canonical('Quan10'), 'Quan 10');
      expect(DistrictNames.same('Quận 1', 'Quận 10'), isFalse);
      expect(DistrictNames.same('Bình Tân', 'Bình Thạnh'), isFalse);
      expect(DistrictNames.same(null, ''), isFalse);
      expect(DistrictNames.canonical('  Khu vực  mới  '), 'Khu vực mới');
      expect(DistrictNames.same('Khu vực mới', 'Binh Thanh'), isFalse);
    },
  );

  test('Every catalogue label round trips to its unique key', () {
    for (final entry in DistrictNames.labels.entries) {
      expect(DistrictNames.canonical(entry.value), entry.key);
      expect(DistrictNames.canonical('${entry.value}, TP.HCM'), entry.key);
    }
  });

  test(
    'Room filtering prefers district and does not confuse Quận 1 with Quận 10',
    () {
      expect(
        DistrictNames.matchesRoom(
          district: 'Thu Duc',
          address: 'Test',
          selected: 'Thủ Đức, TP.HCM',
        ),
        isTrue,
      );
      expect(
        DistrictNames.matchesRoom(
          district: 'Quan 10',
          address: 'Quận 1',
          selected: 'Quận 1',
        ),
        isFalse,
      );
      expect(
        DistrictNames.matchesRoom(
          district: '',
          address: '123 Đường A, Quận 1, TP.HCM',
          selected: 'Quan 1',
        ),
        isTrue,
      );
      for (final number in [10, 11, 12]) {
        expect(
          DistrictNames.matchesRoom(
            district: '',
            address: 'Quận $number',
            selected: 'Quận 1',
          ),
          isFalse,
        );
      }
      expect(
        DistrictNames.matchesRoom(
          district: '',
          address: 'Test address',
          selected: 'Quan 1',
        ),
        isFalse,
      );
    },
  );

  for (final name in ['Thủ Đức, TP.HCM', 'Quận Bình Thạnh', 'Khu vực mới']) {
    testWidgets(
      'Survey preserves and submits $name without substituting a default',
      (tester) async {
        final api = _DistrictApi(district: name);
        await tester.pumpWidget(
          MaterialApp(home: SurveyScreen(userId: 1, apiService: api)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.text(
            DistrictNames.canonical(name) == 'Binh Thanh'
                ? 'Bình Thạnh, TP. Hồ Chí Minh'
                : DistrictNames.display(name),
          ),
          findsOneWidget,
        );
        for (var step = 0; step < 4; step++) {
          await tester.ensureVisible(find.text('Tiếp tục'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Tiếp tục'));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text('Lưu tiêu chí & khám phá'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lưu tiêu chí & khám phá'));
        await tester.pumpAndSettle();
        expect(api.saved?['targetDistrict'], DistrictNames.canonical(name));
      },
    );
  }

  testWidgets(
    'Discovery deduplicates aliases and filters both canonical and legacy candidates',
    (tester) async {
      await _home(
        tester,
        _DistrictApi(
          matches: [
            _match(2, 'Thu Duc'),
            _match(3, 'Thủ Đức, TP.HCM'),
            _match(4, 'Binh Thanh'),
          ],
        ),
      );
      await tester.tap(find.text('Tìm kiếm và lọc gợi ý'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('match-filter-button')));
      await tester.pumpAndSettle();
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const Key('district-filter')),
      );
      expect(dropdown.initialValue, 'Tất cả');
      final control = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: find.byKey(const Key('district-filter')),
          matching: find.byType(DropdownButton<String>),
        ),
      );
      expect(
        control.items!.where((item) => item.value == 'Thu Duc'),
        hasLength(1),
      );
      expect(control.items!.map((item) => item.value), [
        'Tất cả',
        'Binh Thanh',
        'Thu Duc',
      ]);
      await tester.tap(find.byKey(const Key('district-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TP. Thủ Đức').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem kết quả'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('match-search-field')),
        'thủ đức',
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Candidate 2'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Candidate 2'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Candidate 3'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Candidate 3'), findsOneWidget);
      expect(find.text('Candidate 4'), findsNothing);
    },
  );

  testWidgets(
    'Room feed filters a canonical key using the Vietnamese selection',
    (tester) async {
      await _home(
        tester,
        _DistrictApi(posts: [_room(1, 'Binh Thanh'), _room(2, 'Thu Duc')]),
        tab: 1,
      );
      await tester.tap(find.text('Gần bạn'));
      await tester.pumpAndSettle();
      expect(find.text('Room 1'), findsOneWidget);
      expect(find.text('Room 2'), findsNothing);
      await tester.tap(find.text('Gần bạn'));
      await tester.pumpAndSettle();
      final search = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Tìm khu vực, trường học…',
      );
      await tester.enterText(search, 'thủ đức');
      await tester.pumpAndSettle();
      expect(find.text('Room 1'), findsNothing);
      expect(find.text('Room 2'), findsOneWidget);
    },
  );
}
