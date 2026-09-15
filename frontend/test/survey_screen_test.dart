import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/screens/survey_screen.dart';

void main() {
  testWidgets('SurveyScreen renders 5-step Stepper correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SurveyScreen(userId: 1),
      ),
    );

    // Wait for mock / loadPreferences future to settle
    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('Khảo Sát Tiêu Chí 5 Chiều'), findsOneWidget);

    // Verify Stepper is present
    expect(find.byType(Stepper), findsOneWidget);

    // Verify Step 1 elements
    expect(find.text('Bước 1: Ngân sách & Khu vực'), findsOneWidget);
    expect(find.byType(RangeSlider), findsOneWidget);
    expect(find.text('Quận / Huyện mong muốn (TP. Hồ Chí Minh):'), findsOneWidget);

    // Verify Continue button
    expect(find.text('TIẾP TỤC'), findsOneWidget);
  });
}
