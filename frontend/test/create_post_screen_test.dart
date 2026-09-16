import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/screens/create_post_screen.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';

void main() {
  // ============================================================
  // 1. Unit Tests: RoomPost.fromJson parsing
  // ============================================================
  group('RoomPost.fromJson', () {
    test('parses full payload with all new fields correctly', () {
      final json = {
        'id': 1,
        'title': 'Tìm bạn ở ghép Bình Thạnh',
        'description': 'Phòng đẹp, yên tĩnh',
        'price': 3500000.0,
        'address': '123 Võ Văn Ngân, Bình Thạnh',
        'district': 'Bình Thạnh',
        'deposit': 1000000.0,
        'electricityWaterCost': 300000.0,
        'area': 25.0,
        'maxOccupants': 3,
        'currentOccupants': 1,
        'amenities': 'Wifi,Máy lạnh,Giữ xe',
        'authorName': 'Tiến Đạt',
        'authorId': 10,
        'status': 'APPROVED',
        'createdAt': '2026-09-15T10:00:00',
        'viewCount': 42,
      };

      final post = RoomPost.fromJson(json);

      expect(post.id, 1);
      expect(post.title, 'Tìm bạn ở ghép Bình Thạnh');
      expect(post.price, 3500000.0);
      expect(post.district, 'Bình Thạnh');
      expect(post.deposit, 1000000.0);
      expect(post.electricityWaterCost, 300000.0);
      expect(post.area, 25.0);
      expect(post.maxOccupants, 3);
      expect(post.currentOccupants, 1);
      expect(post.amenities, ['Wifi', 'Máy lạnh', 'Giữ xe']);
      expect(post.authorName, 'Tiến Đạt');
      expect(post.viewCount, 42);
    });

    test('handles missing optional fields with defaults', () {
      final json = {
        'id': 2,
        'title': 'Phòng trọ Q9',
        'description': 'Test',
        'price': 2000000.0,
        'address': '456 Đường ABC, Quận 9',
        'maxOccupants': 2,
        'authorName': 'Test User',
        'authorId': 5,
      };

      final post = RoomPost.fromJson(json);

      expect(post.district, 'Quận 9'); // extracted from address
      expect(post.deposit, isNull);
      expect(post.electricityWaterCost, isNull);
      expect(post.area, isNull);
      expect(post.currentOccupants, 0);
      expect(post.amenities, isEmpty);
      expect(post.viewCount, 0);
    });

    test('parses amenities from List format', () {
      final json = {
        'id': 3,
        'title': 'Test',
        'description': 'Test',
        'price': 1000000.0,
        'address': 'Test',
        'maxOccupants': 1,
        'authorName': 'Test',
        'authorId': 1,
        'amenities': ['Wifi', 'Nước nóng'],
      };

      final post = RoomPost.fromJson(json);
      expect(post.amenities, ['Wifi', 'Nước nóng']);
    });

    test('handles null and empty amenities gracefully', () {
      final jsonNull = {
        'id': 4, 'title': 'T', 'description': 'D', 'price': 1.0,
        'address': 'A', 'maxOccupants': 1, 'authorName': 'N', 'authorId': 1,
        'amenities': null,
      };
      final jsonEmpty = Map<String, dynamic>.from(jsonNull)..['amenities'] = '';

      expect(RoomPost.fromJson(jsonNull).amenities, isEmpty);
      expect(RoomPost.fromJson(jsonEmpty).amenities, isEmpty);
    });
  });

  // ============================================================
  // 2. Widget Tests: CreatePostScreen form validation
  // ============================================================
  group('CreatePostScreen widget tests', () {
    Widget buildTestWidget() {
      return const MaterialApp(
        home: CreatePostScreen(authorId: 1),
      );
    }

    testWidgets('renders form with all required sections', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Check section headers
      expect(find.text('📝 Thông tin cơ bản'), findsOneWidget);
      expect(find.text('📍 Địa chỉ phòng trọ'), findsOneWidget);
      expect(find.text('💰 Chi phí'), findsOneWidget);
      expect(find.text('🏠 Thông tin phòng'), findsOneWidget);
      expect(find.text('✨ Tiện ích có sẵn'), findsOneWidget);
      expect(find.text('ĐĂNG BÀI NGAY'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty required fields', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Scroll down and tap submit
      final submitButton = find.text('ĐĂNG BÀI NGAY');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Should show validation error messages
      expect(find.text('Vui lòng nhập tiêu đề'), findsOneWidget);
    });

    testWidgets('shows validation error for short title', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Enter a short title (< 10 chars)
      final titleField = find.widgetWithText(TextFormField, 'Tiêu đề bài đăng *');
      await tester.enterText(titleField, 'ABC');

      // Tap submit
      final submitButton = find.text('ĐĂNG BÀI NGAY');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Tiêu đề phải tối thiểu 10 ký tự'), findsOneWidget);
    });

    testWidgets('amenity chips are selectable', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Find and tap the Wifi chip
      final wifiChip = find.text('📶 Wifi');
      await tester.ensureVisible(wifiChip);
      await tester.tap(wifiChip);
      await tester.pumpAndSettle();

      // The chip should now be selected (FilterChip renders differently when selected)
      final filterChip = tester.widget<FilterChip>(
        find.ancestor(of: wifiChip, matching: find.byType(FilterChip)),
      );
      expect(filterChip.selected, isTrue);
    });

    testWidgets('currentOccupants field validates non-negative number', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Find the currentOccupants field and enter invalid input
      final curOccField = find.widgetWithText(TextFormField, 'Hiện tại (người)');
      await tester.enterText(curOccField, '-3');

      // Tap submit to trigger validation
      final submitButton = find.text('ĐĂNG BÀI NGAY');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Số không hợp lệ'), findsOneWidget);
    });
  });
}
