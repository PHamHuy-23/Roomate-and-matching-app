import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_moderate_post_screen.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_post_approved_screen.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_post_needs_edit_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

class _ModerationApi implements ApiService {
  String? lastStatus;

  @override
  Future<List<dynamic>> getAdminPosts() async => [
        {
          'id': 28,
          'title': 'Studio ngập nắng, có ban công',
          'description': 'Phòng có nội thất cơ bản.',
          'price': 3500000,
          'address': 'Bình Thạnh',
          'maxOccupants': 2,
          'author': {'fullName': 'Minh Anh'},
          'createdAt': '2026-09-19T00:00:00Z',
          'status': 'PENDING',
        },
      ];

  @override
  Future<bool> moderatePost(int postId, String status) async {
    lastStatus = status;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Duyệt tin mở màn kết quả và quay lại màn kiểm duyệt', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _ModerationApi();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminModeratePostScreen(apiService: api),
        routes: {
          AppRoutes.adminPostApproved: (_) => const AdminPostApprovedScreen(),
          AppRoutes.adminModeratePost: (_) => AdminModeratePostScreen(apiService: api),
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Duyệt & hiển thị tin'));
    await tester.pumpAndSettle();
    expect(api.lastStatus, 'APPROVED');
    expect(find.text('Tin đã được duyệt'), findsNWidgets(2));

    await tester.tap(find.text('Tiếp tục kiểm duyệt'));
    await tester.pumpAndSettle();
    expect(find.text('Kiểm duyệt tin đăng'), findsOneWidget);
    expect(find.text('Duyệt & hiển thị tin'), findsOneWidget);
  });

  testWidgets('Từ chối tin mở màn chỉnh sửa và quay lại màn kiểm duyệt', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _ModerationApi();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminModeratePostScreen(apiService: api),
        routes: {
          AppRoutes.adminPostNeedsEdit: (_) => const AdminPostNeedsEditScreen(),
          AppRoutes.adminModeratePost: (_) => AdminModeratePostScreen(apiService: api),
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Từ chối tin đăng'));
    await tester.pumpAndSettle();
    expect(api.lastStatus, 'REJECTED');
    expect(find.text('Tin cần được chỉnh sửa'), findsNWidgets(2));

    await tester.tap(find.text('Tiếp tục kiểm duyệt'));
    await tester.pumpAndSettle();
    expect(find.text('Kiểm duyệt tin đăng'), findsOneWidget);
    expect(find.text('Từ chối tin đăng'), findsOneWidget);
  });
}
