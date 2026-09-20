import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/screens/survey_screen.dart';

void main() {
  testWidgets('SurveyScreen follows the five Penpot onboarding screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SurveyScreen(userId: 1)));

    // Wait for mock / loadPreferences future to settle
    await tester.pumpAndSettle();

    // Screen 36: location and budget
    expect(find.text('Bạn muốn ở đâu?'), findsOneWidget);
    expect(find.byType(RangeSlider), findsOneWidget);
    expect(find.text('Khu vực ưu tiên'), findsOneWidget);

    Future<void> continueTo(String title) async {
      await tester.ensureVisible(find.text('Tiếp tục'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }

    await continueTo('Nhịp sống của bạn');
    await continueTo('Thoải mái khi ở cùng');
    await continueTo('Cá tính của bạn');
    await continueTo('Sẵn sàng tìm bạn!');
    expect(find.text('Lưu tiêu chí & khám phá'), findsOneWidget);
  });
}
