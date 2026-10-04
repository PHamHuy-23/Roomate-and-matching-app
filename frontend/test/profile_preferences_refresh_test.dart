import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/profile_screen.dart';
import 'package:roommate_hub_mobile/screens/survey_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

final _user = AuthUser(
  token: 'test-token',
  userId: 10,
  fullName: 'Profile test',
  email: 'profile@example.test',
  gender: 'MALE',
  role: 'ROLE_USER',
);

Map<String, dynamic> _preferences({
  String district = 'Thu Duc',
  bool smoking = false,
}) => {
  'targetDistrict': district,
  'budgetAmount': 4000000.0,
  'budgetMin': 2000000.0,
  'budgetMax': 4000000.0,
  'sleepHabit': 1,
  'cleanlinessLevel': 4,
  'isSmoking': smoking,
  'allowPets': false,
};

class _PreferencesApi implements ApiService {
  Map<String, dynamic>? data = _preferences();
  final reads = Queue<Future<Map<String, dynamic>?> Function()>();
  int readCalls = 0;
  int saveCalls = 0;
  bool saveSucceeds = true;
  Completer<bool>? saveReply;

  @override
  Future<Map<String, dynamic>?> getPreferences(int userId) {
    expect(userId, _user.userId);
    readCalls++;
    return reads.isEmpty
        ? Future.value(data == null ? null : Map.of(data!))
        : reads.removeFirst()();
  }

  @override
  Future<bool> savePreferences(int userId, Map<String, dynamic> payload) async {
    expect(userId, _user.userId);
    saveCalls++;
    final success = saveReply == null ? saveSucceeds : await saveReply!.future;
    if (success) data = {...?data, ...payload};
    return success;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _openProfile(WidgetTester tester, _PreferencesApi api) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProfileScreen(currentUser: _user, apiService: api),
      routes: {
        AppRoutes.survey: (_) =>
            SurveyScreen(userId: _user.userId, apiService: api),
      },
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openSurvey(WidgetTester tester) async {
  await _tap(tester, find.text('Tiêu chí của tôi'));
  expect(find.byType(SurveyScreen), findsOneWidget);
}

Future<void> _editSmokingAndSave(WidgetTester tester) async {
  await _tap(tester, find.text('Tiếp tục'));
  await _tap(tester, find.text('Tiếp tục'));
  await _tap(tester, find.text('Có hút thuốc'));
  await _tap(tester, find.text('Tiếp tục'));
  await _tap(tester, find.text('Tiếp tục'));
  await _tap(tester, find.text('Lưu tiêu chí & khám phá'));
}

Future<void> _refreshProfile(WidgetTester tester) async {
  final refresh = tester.widget<RefreshIndicator>(
    find.byType(RefreshIndicator),
  );
  unawaited(refresh.onRefresh());
  await tester.pump();
}

void main() {
  testWidgets('successful real survey save reloads the profile summary', (
    tester,
  ) async {
    final api = _PreferencesApi();
    await _openProfile(tester, api);
    expect(find.textContaining('Không hút thuốc'), findsOneWidget);
    await _openSurvey(tester);
    await _editSmokingAndSave(tester);
    expect(api.saveCalls, 1);
    expect(api.readCalls, 3);
    expect(find.byType(SurveyScreen), findsNothing);
    expect(find.textContaining('Có hút thuốc'), findsOneWidget);
    expect(find.textContaining('Không hút thuốc'), findsNothing);
  });

  testWidgets('cancelled survey keeps the profile summary without extra read', (
    tester,
  ) async {
    final api = _PreferencesApi();
    await _openProfile(tester, api);
    await _openSurvey(tester);
    Navigator.of(tester.element(find.byType(SurveyScreen))).pop();
    await tester.pumpAndSettle();
    expect(api.saveCalls, 0);
    expect(api.readCalls, 2);
    expect(find.textContaining('Không hút thuốc'), findsOneWidget);
  });

  testWidgets(
    'failed survey save stays open and does not claim fresh summary',
    (tester) async {
      final api = _PreferencesApi()..saveSucceeds = false;
      await _openProfile(tester, api);
      await _openSurvey(tester);
      await _editSmokingAndSave(tester);
      expect(api.saveCalls, 1);
      expect(api.readCalls, 2);
      expect(find.byType(SurveyScreen), findsOneWidget);
      expect(find.textContaining('Lưu tiêu chí thất bại'), findsOneWidget);
      Navigator.of(tester.element(find.byType(SurveyScreen))).pop();
      await tester.pumpAndSettle();
      expect(api.readCalls, 2);
      expect(find.textContaining('Không hút thuốc'), findsOneWidget);
    },
  );

  testWidgets('initial read failure is not an empty preference and can retry', (
    tester,
  ) async {
    final api = _PreferencesApi()
      ..reads.add(() => Future.error(const ApiException('Read failed')));
    await _openProfile(tester, api);
    expect(
      find.text('Không tải được tiêu chí. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Chưa thiết lập tiêu chí ghép trọ'), findsNothing);
    await _tap(tester, find.text('Thử lại'));
    expect(api.readCalls, 2);
    expect(find.textContaining('TP. Thủ Đức'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });

  testWidgets(
    'post-save reload shows loading, error, then actual data on retry',
    (tester) async {
      final api = _PreferencesApi();
      await _openProfile(tester, api);
      await _openSurvey(tester);
      final pending = Completer<Map<String, dynamic>?>();
      api.reads.add(() => pending.future);
      await _editSmokingAndSave(tester);
      expect(api.readCalls, 3);
      expect(find.text('Đang tải...'), findsOneWidget);
      expect(find.textContaining('Không hút thuốc'), findsNothing);
      pending.completeError(const ApiException('Refresh failed'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không tải được tiêu chí. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(find.textContaining('Không hút thuốc'), findsNothing);
      expect(find.text('Chưa thiết lập tiêu chí ghép trọ'), findsNothing);
      await _tap(tester, find.text('Thử lại'));
      expect(api.readCalls, 4);
      expect(find.textContaining('Có hút thuốc'), findsOneWidget);
    },
  );

  testWidgets('latest refresh wins when earlier response completes last', (
    tester,
  ) async {
    final api = _PreferencesApi();
    await _openProfile(tester, api);
    final older = Completer<Map<String, dynamic>?>();
    final newer = Completer<Map<String, dynamic>?>();
    api.reads.addAll([() => older.future, () => newer.future]);
    await _refreshProfile(tester);
    await _refreshProfile(tester);
    newer.complete(_preferences(district: 'Binh Thanh', smoking: true));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bình Thạnh'), findsOneWidget);
    older.complete(_preferences(district: 'Thu Duc'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bình Thạnh'), findsOneWidget);
    expect(find.textContaining('TP. Thủ Đức'), findsNothing);
    expect(find.textContaining('Có hút thuốc'), findsOneWidget);
  });

  testWidgets('late refresh error cannot overwrite newer successful refresh', (
    tester,
  ) async {
    final api = _PreferencesApi();
    await _openProfile(tester, api);
    final older = Completer<Map<String, dynamic>?>();
    final newer = Completer<Map<String, dynamic>?>();
    api.reads.addAll([() => older.future, () => newer.future]);
    await _refreshProfile(tester);
    await _refreshProfile(tester);
    newer.complete(_preferences(district: 'Binh Thanh'));
    await tester.pumpAndSettle();
    older.completeError(const ApiException('Stale request failed'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bình Thạnh'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('null API result remains an honest empty preference state', (
    tester,
  ) async {
    final api = _PreferencesApi()..data = null;
    await _openProfile(tester, api);
    expect(find.text('Chưa thiết lập tiêu chí ghép trọ'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });

  testWidgets('late read after disposing the screen causes no setState error', (
    tester,
  ) async {
    final api = _PreferencesApi();
    final pending = Completer<Map<String, dynamic>?>();
    api.reads.add(() => pending.future);
    await _openProfile(tester, api);
    expect(find.text('Đang tải...'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    pending.complete(_preferences(district: 'Binh Thanh'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
