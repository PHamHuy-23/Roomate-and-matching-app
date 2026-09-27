import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_report_resolved_screen.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_reports_screen.dart';

void main() {
  testWidgets('Chọn từng báo cáo cập nhật phần chi tiết', (tester) async {
    // The admin layout is designed for a desktop viewport; keep all report
    // cards visible so the interaction test exercises the actual tap target.
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: AdminReportsScreen()),
    );

    expect(find.text('BC-028 / Chi tiết báo cáo'), findsOneWidget);
    expect(find.textContaining('Thông tin phòng không đúng thực tế'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin_report_BC-027')));
    await tester.pumpAndSettle();

    expect(find.text('BC-027 / Chi tiết báo cáo'), findsOneWidget);
    expect(find.textContaining('Nội dung tin đăng không phù hợp'), findsOneWidget);
    expect(find.textContaining('Đang chờ quản trị viên kiểm tra nội dung.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin_report_BC-026')));
    await tester.pumpAndSettle();

    expect(find.text('BC-026 / Chi tiết báo cáo'), findsOneWidget);
    expect(find.textContaining('Tin đăng có dấu hiệu trùng lặp'), findsOneWidget);
  });

  testWidgets('Nút về danh sách báo cáo mở lại màn danh sách', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: const AdminReportResolvedScreen(),
        routes: {
          AppRoutes.adminReports: (_) => const AdminReportsScreen(),
        },
      ),
    );

    await tester.tap(find.text('Về danh sách báo cáo'));
    await tester.pumpAndSettle();

    expect(find.text('Báo cáo vi phạm'), findsNWidgets(2));
    expect(find.text('Báo cáo đang chờ'), findsOneWidget);
  });
}
