import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/user_preference.dart';
import 'package:roommate_hub_mobile/screens/survey_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

const _extraFields = {
  'moveInDate': '2099-11-04',
  'roomType': 'PRIVATE',
  'workSchedule': 'NIGHT',
  'personalValue': 'SCHEDULE',
};

class _SurveyApi implements ApiService {
  _SurveyApi(this.data);
  Map<String, dynamic>? data;
  Map<String, dynamic>? submitted;
  int saves = 0;
  bool failSave = false;
  Completer<bool>? saveReply;
  @override
  Future<Map<String, dynamic>?> getPreferences(int userId) async => data;
  @override
  Future<bool> savePreferences(int userId, Map<String, dynamic> payload) async {
    expect(userId, 10);
    saves++;
    submitted = Map.of(payload);
    if (saveReply != null) await saveReply!.future;
    if (failSave) throw const ApiException('Không thể lưu lựa chọn');
    data = {...?data, ...payload};
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(WidgetTester tester, _SurveyApi api) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SurveyScreen(key: UniqueKey(), userId: 10, apiService: api),
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

Future<void> _next(WidgetTester tester) => _tap(tester, find.text('Tiếp tục'));
Future<void> _summary(WidgetTester tester) async {
  for (var step = 0; step < 4; step++) {
    await _next(tester);
  }
}

bool _selectedChoice(WidgetTester tester, String label) {
  final container = tester.widget<AnimatedContainer>(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).color ==
      const Color(0xFFE8F4F1);
}

bool _selectedChip(WidgetTester tester, String label) {
  final container = tester.widget<Container>(
    find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
  );
  return (container.decoration! as BoxDecoration).color ==
      const Color(0xFFE8F4F1);
}

void main() {
  test(
    'model reads four structured fields independently of matching priority',
    () {
      final pref = UserPreference.fromJson({
        ..._extraFields,
        'topPriority': 'BUDGET',
      });
      expect(pref.moveInDate, DateTime(2099, 11, 4));
      expect(pref.roomType, 'PRIVATE');
      expect(pref.workSchedule, 'NIGHT');
      expect(pref.personalValue, 'SCHEDULE');
      expect(UserPreference.fromJson({}).moveInDate, isNull);
      expect(UserPreference.fromJson({}).roomType, isNull);
      expect(UserPreference.fromJson({}).workSchedule, isNull);
      expect(UserPreference.fromJson({}).personalValue, isNull);
    },
  );

  for (final invalid in [
    {'moveInDate': '2026-02-30'},
    {'moveInDate': '2026-11-04T12:00:00Z'},
    {'moveInDate': 123},
    {'roomType': 'OTHER'},
    {'workSchedule': ''},
    {'personalValue': 'BUDGET'},
  ]) {
    testWidgets('invalid stored survey choice $invalid blocks unsafe save', (
      tester,
    ) async {
      final api = _SurveyApi(invalid);
      await _open(tester, api);
      expect(
        find.text('Không thể đọc tiêu chí đã lưu, vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(find.text('Tiếp tục'), findsNothing);
      expect(api.saves, 0);
    });
  }

  testWidgets('legacy fields stay unselected and are not invented in payload', (
    tester,
  ) async {
    final api = _SurveyApi({'bioDescription': 'Lời giới thiệu cũ'})
      ..failSave = true;
    await _open(tester, api);
    expect(find.text('Chưa chọn ngày (không bắt buộc)'), findsOneWidget);
    expect(_selectedChoice(tester, 'Ở ghép'), isFalse);
    expect(_selectedChoice(tester, 'Phòng riêng'), isFalse);
    await _next(tester);
    expect(_selectedChoice(tester, 'Ban ngày'), isFalse);
    expect(_selectedChoice(tester, 'Ban đêm'), isFalse);
    await _next(tester);
    await _next(tester);
    expect(_selectedChip(tester, 'Tôn trọng không gian riêng'), isFalse);
    await _next(tester);
    await _tap(tester, find.text('Lưu tiêu chí & khám phá'));
    for (final field in _extraFields.keys) {
      expect(api.submitted!.containsKey(field), isFalse);
    }
    expect(api.submitted!['bioDescription'], contains('Lời giới thiệu cũ'));
  });

  testWidgets(
    'all four saved fields reload and appear in summary and save payload',
    (tester) async {
      final api = _SurveyApi({..._extraFields, 'topPriority': 'BUDGET'})
        ..failSave = true;
      await _open(tester, api);
      expect(find.text('04/11/2099'), findsOneWidget);
      expect(_selectedChoice(tester, 'Phòng riêng'), isTrue);
      await _next(tester);
      expect(_selectedChoice(tester, 'Ban đêm'), isTrue);
      await _next(tester);
      await _next(tester);
      expect(_selectedChip(tester, 'Giờ giấc tương đồng'), isTrue);
      await _next(tester);
      expect(find.text('04/11/2099 · Phòng riêng'), findsOneWidget);
      expect(find.text('Ban đêm'), findsOneWidget);
      expect(find.text('Giờ giấc tương đồng'), findsOneWidget);
      await _tap(tester, find.text('Lưu tiêu chí & khám phá'));
      for (final field in _extraFields.keys) {
        expect(api.submitted![field], _extraFields[field]);
      }
      expect(api.submitted!['topPriority'], 'BUDGET');
    },
  );

  testWidgets(
    'past move-in date opens picker safely and cancel preserves stored date',
    (tester) async {
      final api = _SurveyApi({..._extraFields, 'moveInDate': '2020-01-01'})
        ..failSave = true;
      await _open(tester, api);
      expect(find.text('01/01/2020'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('survey-move-in-date')));
      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.initialDate, DateUtils.dateOnly(DateTime.now()));
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byType(DatePickerDialog))).pop();
      await tester.pumpAndSettle();
      expect(find.text('01/01/2020'), findsOneWidget);
      await _summary(tester);
      await _tap(tester, find.text('Lưu tiêu chí & khám phá'));
      expect(api.submitted!['moveInDate'], '2020-01-01');
    },
  );

  testWidgets(
    'new choices survive a successful save and reopening the survey',
    (tester) async {
      final api = _SurveyApi(null);
      Object? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurveyScreen(userId: 10, apiService: api),
                    ),
                  );
                },
                child: const Text('Mở khảo sát'),
              ),
            ),
          ),
        ),
      );
      await _tap(tester, find.text('Mở khảo sát'));
      await _tap(tester, find.text('Phòng riêng'));
      await _tap(tester, find.byKey(const ValueKey('survey-move-in-date')));
      final picked = DateUtils.dateOnly(
        DateTime.now(),
      ).add(const Duration(days: 30));
      Navigator.of(tester.element(find.byType(DatePickerDialog))).pop(picked);
      await tester.pumpAndSettle();
      await _next(tester);
      await _tap(tester, find.text('Ban đêm'));
      await _next(tester);
      await _next(tester);
      await _tap(tester, find.text('Giờ giấc tương đồng'));
      await _next(tester);
      await _tap(tester, find.text('Lưu tiêu chí & khám phá'));
      expect(find.text('Mở khảo sát'), findsOneWidget);
      expect(result, true);
      expect(api.saves, 1);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Mở khảo sát'));
      expect(_selectedChoice(tester, 'Phòng riêng'), isTrue);
      await _summary(tester);
      expect(find.text('Ban đêm'), findsOneWidget);
      expect(find.text('Giờ giấc tương đồng'), findsOneWidget);
      expect(
        api.data!['moveInDate'],
        picked.toIso8601String().split('T').first,
      );
      expect(api.data!['roomType'], 'PRIVATE');
      expect(api.data!['workSchedule'], 'NIGHT');
      expect(api.data!['personalValue'], 'SCHEDULE');
    },
  );

  testWidgets(
    'save waits for backend, blocks duplicate submission and preserves failed draft',
    (tester) async {
      final api = _SurveyApi(Map.of(_extraFields))
        ..saveReply = Completer<bool>()
        ..failSave = true;
      await _open(tester, api);
      await _summary(tester);
      await tester.ensureVisible(find.text('Lưu tiêu chí & khám phá'));
      await tester.tap(find.text('Lưu tiêu chí & khám phá'));
      await tester.pump();
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(SurveyScreen), findsOneWidget);
      expect(api.saves, 1);
      api.saveReply!.complete(true);
      await tester.pumpAndSettle();
      expect(find.textContaining('Không thể lưu lựa chọn'), findsOneWidget);
      expect(find.text('04/11/2099 · Phòng riêng'), findsOneWidget);
      expect(find.text('Giờ giấc tương đồng'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
    },
  );
}
