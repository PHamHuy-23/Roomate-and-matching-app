import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/screens/survey_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

class _PreferencesApi implements ApiService {
  _PreferencesApi(this.data);
  Map<String, dynamic>? data;
  Object? error;
  int loads = 0;
  Map<String, dynamic>? saved;

  @override
  Future<Map<String, dynamic>?> getPreferences(int userId) async {
    loads++;
    if (error != null) throw error!;
    return data;
  }

  @override
  Future<bool> savePreferences(int userId, Map<String, dynamic> payload) async {
    saved = payload;
    return false; // Keep the screen open to inspect the submitted payload.
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(WidgetTester tester, _PreferencesApi api) async {
  await tester.pumpWidget(
    MaterialApp(home: SurveyScreen(userId: 1, apiService: api)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('expanded slider scale stays stable when changing the budget', (
    tester,
  ) async {
    await _open(
      tester,
      _PreferencesApi({'budgetMin': 0, 'budgetMax': 20000000}),
    );
    tester.widget<RangeSlider>(find.byType(RangeSlider)).onChanged!(
      const RangeValues(2000000, 4000000),
    );
    await tester.pumpAndSettle();
    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    expect(slider.min, 0);
    expect(slider.max, 20000000);
    expect(slider.values, const RangeValues(2000000, 4000000));
  });

  testWidgets('lower slider extension cannot submit a budget below 500000', (
    tester,
  ) async {
    final api = _PreferencesApi({'budgetMin': 0, 'budgetMax': 500000});
    await _open(tester, api);
    tester.widget<RangeSlider>(find.byType(RangeSlider)).onChanged!(
      const RangeValues(0, 0),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Ngân sách tối đa phải từ 500.000 VNĐ và tối thiểu không được âm!',
      ),
      findsOneWidget,
    );
    expect(find.text('Bạn muốn ở đâu?'), findsOneWidget);
    expect(api.saved, isNull);
  });

  for (final range in <RangeValues>[
    const RangeValues(500000, 800000),
    const RangeValues(16000000, 20000000),
    const RangeValues(2000000, 4000000),
    const RangeValues(500000, 500000),
    const RangeValues(0, 500000),
  ]) {
    testWidgets(
      'preserves and submits saved budget ${range.start}-${range.end}',
      (tester) async {
        final api = _PreferencesApi({
          'budgetMin': range.start,
          'budgetMax': range.end,
        });
        await _open(tester, api);
        expect(tester.takeException(), isNull);
        final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
        expect(slider.values, range);
        expect(slider.min, lessThanOrEqualTo(range.start));
        expect(slider.max, greaterThanOrEqualTo(range.end));
        for (var step = 0; step < 4; step++) {
          await tester.ensureVisible(find.text('Tiếp tục'));
          await tester.tap(find.text('Tiếp tục'));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text('Lưu tiêu chí & khám phá'));
        await tester.tap(find.text('Lưu tiêu chí & khám phá'));
        await tester.pumpAndSettle();
        expect(api.saved?['budgetMin'], range.start);
        expect(api.saved?['budgetMax'], range.end);
      },
    );
  }

  final invalidRanges = <Map<String, dynamic>>[
    {'budgetMin': 5000000, 'budgetMax': 4000000},
    {'budgetMin': -1, 'budgetMax': 500000},
    {'budgetMin': 0, 'budgetMax': 499999},
    {'budgetMin': 1000000},
    {'budgetMax': 2000000},
    {'budgetMin': double.nan, 'budgetMax': double.infinity},
    {'budgetMin': '1000000', 'budgetMax': 2000000},
  ];
  for (var index = 0; index < invalidRanges.length; index++) {
    testWidgets(
      'invalid saved range $index cannot silently replace existing criteria',
      (tester) async {
        final api = _PreferencesApi(invalidRanges[index]);
        await _open(tester, api);
        expect(tester.takeException(), isNull);
        expect(
          find.text(
            'Khoảng ngân sách đã lưu không hợp lệ. Vui lòng kiểm tra lại dữ liệu.',
          ),
          findsOneWidget,
        );
        expect(find.byType(RangeSlider), findsNothing);
        expect(find.text('Tiếp tục'), findsNothing);
        expect(api.saved, isNull);
      },
    );
  }

  testWidgets('failed load blocks form until a successful retry', (
    tester,
  ) async {
    final api = _PreferencesApi({'budgetMin': 500000, 'budgetMax': 800000})
      ..error = const ApiException('Không tải được tiêu chí');
    await _open(tester, api);
    expect(find.text('Không tải được tiêu chí'), findsOneWidget);
    expect(find.byType(RangeSlider), findsNothing);
    expect(api.saved, isNull);
    api.error = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(api.loads, 2);
    expect(
      tester.widget<RangeSlider>(find.byType(RangeSlider)).values,
      const RangeValues(500000, 800000),
    );
    expect(api.saved, isNull);
  });

  testWidgets('unexpected parsing failure does not display default criteria', (
    tester,
  ) async {
    final api = _PreferencesApi({'targetDistrict': 123});
    await _open(tester, api);
    expect(
      find.text('Không thể đọc tiêu chí đã lưu, vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.byType(RangeSlider), findsNothing);
    expect(api.saved, isNull);
  });

  testWidgets('new user without saved preferences can start onboarding', (
    tester,
  ) async {
    await _open(tester, _PreferencesApi(null));
    expect(find.text('Bạn muốn ở đâu?'), findsOneWidget);
    expect(find.byType(RangeSlider), findsOneWidget);
  });
}
