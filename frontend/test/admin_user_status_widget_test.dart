import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_confirm_lock_screen.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_user_details_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

const _lockedUser = {
  'userId': '28',
  'id': '#028',
  'fullName': 'Tài khoản thử nghiệm',
  'email': 'test@example.invalid',
  'role': 'Thành viên',
  'status': 'Đã khóa',
};

Future<void> _desktop(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _openConfirm(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => screen)),
              child: const Text('Mở xác nhận'),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('Mở xác nhận'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'confirmed LOCKED reaches details and the user list as a display label',
    (tester) async {
      await _desktop(tester);
      final changed = <String>[];
      final calls = <(int, String)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: AdminUserDetailsScreen(
            user: {..._lockedUser, 'status': 'Hoạt động'},
            onStatusChanged: changed.add,
          ),
          routes: {
            AppRoutes.adminConfirmLock: (context) {
              final arguments =
                  ModalRoute.of(context)!.settings.arguments! as Map;
              return AdminConfirmLockScreen(
                user: arguments['user'] as Map<String, String>,
                onStatusChanged:
                    arguments['onStatusChanged'] as ValueChanged<String>,
                onSetStatus: (id, status) async {
                  calls.add((id, status));
                  return 'LOCKED';
                },
              );
            },
          },
        ),
      );
      await tester.tap(find.text('Khóa tài khoản'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminConfirmLockScreen), findsOneWidget);
      await tester.tap(find.text('Xác nhận khóa'));
      await tester.pumpAndSettle();
      expect(calls, [(28, 'LOCKED')]);
      expect(changed, ['Đã khóa']);
      expect(find.byType(AdminConfirmLockScreen), findsNothing);
      expect(find.text('Đã khóa'), findsOneWidget);
      expect(find.text('Mở khóa tài khoản'), findsOneWidget);
    },
  );

  testWidgets(
    'unlock sends ACTIVE once, waits for confirmation, then updates UI',
    (tester) async {
      await _desktop(tester);
      final result = Completer<String>();
      final calls = <(int, String)>[];
      final changed = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: AdminUserDetailsScreen(
            user: _lockedUser,
            onStatusChanged: changed.add,
            onSetStatus: (id, status) {
              calls.add((id, status));
              return result.future;
            },
          ),
        ),
      );
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Mở khóa tài khoản'),
      );
      button.onPressed!();
      button.onPressed!();
      await tester.pump();
      expect(calls, [(28, 'ACTIVE')]);
      expect(changed, isEmpty);
      expect(find.text('Đã khóa'), findsOneWidget);
      expect(find.text('Đã mở khóa tài khoản.'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      result.complete('ACTIVE');
      await tester.pumpAndSettle();
      expect(changed, ['Hoạt động']);
      expect(find.text('Hoạt động'), findsOneWidget);
      expect(find.text('Khóa tài khoản'), findsOneWidget);
    },
  );

  for (final mismatch in [false, true]) {
    testWidgets('unlock failure keeps locked UI and retries ACTIVE ($mismatch)', (
      tester,
    ) async {
      await _desktop(tester);
      final calls = <(int, String)>[];
      final changed = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: AdminUserDetailsScreen(
            user: _lockedUser,
            onStatusChanged: changed.add,
            onSetStatus: (id, status) async {
              calls.add((id, status));
              if (calls.length == 1) {
                if (mismatch) return 'LOCKED';
                throw const ApiException('Không thể mở khóa');
              }
              return 'ACTIVE';
            },
          ),
        ),
      );
      await tester.tap(find.text('Mở khóa tài khoản'));
      await tester.pumpAndSettle();
      expect(changed, isEmpty);
      expect(find.text('Đã khóa'), findsOneWidget);
      expect(find.text('Đã mở khóa tài khoản.'), findsNothing);
      expect(find.text('Khóa tài khoản'), findsNothing);
      // Let the earlier error SnackBar expire before asserting the retry success message.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mở khóa tài khoản'));
      await tester.pumpAndSettle();
      expect(calls, [(28, 'ACTIVE'), (28, 'ACTIVE')]);
      expect(changed, ['Hoạt động']);
      expect(find.text('Đã mở khóa tài khoản.'), findsOneWidget);
    });
  }

  testWidgets(
    'confirm from stale LOCKED profile still requests LOCKED and prevents double submit',
    (tester) async {
      await _desktop(tester);
      final result = Completer<String>();
      final calls = <(int, String)>[];
      final changed = <String>[];
      await _openConfirm(
        tester,
        AdminConfirmLockScreen(
          user: _lockedUser,
          onStatusChanged: changed.add,
          onSetStatus: (id, status) {
            calls.add((id, status));
            return result.future;
          },
        ),
      );
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận khóa'),
      );
      button.onPressed!();
      button.onPressed!();
      await tester.pump();
      expect(calls, [(28, 'LOCKED')]);
      expect(changed, isEmpty);
      expect(find.byType(AdminConfirmLockScreen), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Hủy thao tác'),
            )
            .onPressed,
        isNull,
      );
      result.complete('LOCKED');
      await tester.pumpAndSettle();
      expect(changed, ['LOCKED']);
      expect(find.byType(AdminConfirmLockScreen), findsNothing);
    },
  );

  for (final mismatch in [false, true]) {
    testWidgets(
      'lock failure does not close or update status, retry remains LOCKED ($mismatch)',
      (tester) async {
        await _desktop(tester);
        final calls = <(int, String)>[];
        final changed = <String>[];
        await _openConfirm(
          tester,
          AdminConfirmLockScreen(
            user: _lockedUser,
            onStatusChanged: changed.add,
            onSetStatus: (id, status) async {
              calls.add((id, status));
              if (calls.length == 1) {
                if (mismatch) return 'ACTIVE';
                throw const ApiException('Không thể khóa');
              }
              return 'LOCKED';
            },
          ),
        );
        await tester.tap(find.text('Xác nhận khóa'));
        await tester.pumpAndSettle();
        expect(changed, isEmpty);
        expect(find.byType(AdminConfirmLockScreen), findsOneWidget);
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Xác nhận khóa'),
              )
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.text('Xác nhận khóa'));
        await tester.pumpAndSettle();
        expect(calls, [(28, 'LOCKED'), (28, 'LOCKED')]);
        expect(changed, ['LOCKED']);
        expect(find.byType(AdminConfirmLockScreen), findsNothing);
      },
    );
  }
}
