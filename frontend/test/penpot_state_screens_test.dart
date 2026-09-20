import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/screens/penpot_state_screens.dart';

void main() {
  testWidgets('Màn người đã chặn hiển thị thẻ theo Penpot', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BlockedUsersScreen()));

    expect(find.text('Người đã chặn'), findsOneWidget);
    expect(find.text('Quản lý ai có thể tìm thấy bạn'), findsOneWidget);
    expect(find.text('Người dùng #028'), findsOneWidget);
    expect(find.text('Bỏ chặn người dùng'), findsOneWidget);
  });

  testWidgets('Màn thông báo hiển thị danh sách mẫu', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));

    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Minh Anh gửi lời mời kết nối'), findsOneWidget);
    expect(find.text('Tất cả thông báo đã được đọc'), findsOneWidget);
  });

  testWidgets('Các trạng thái discovery hiển thị đúng nội dung', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PenpotStateScreen(mode: PenpotStateMode.offline)),
    );

    expect(find.text('Chưa tải được dữ liệu'), findsOneWidget);
    expect(find.text('Thử tải lại'), findsOneWidget);
  });

  testWidgets('Màn đang tải phòng dùng skeleton theo Penpot', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PenpotStateScreen(mode: PenpotStateMode.loadingRoom),
      ),
    );

    expect(find.text('Đang tải phòng'), findsOneWidget);
    expect(find.text('Đang tìm những lựa chọn dành cho bạn'), findsOneWidget);
    expect(find.byKey(const Key('penpot_loading_skeleton')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
