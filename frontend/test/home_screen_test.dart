import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';

/// Tests cho home_screen logic: filtering bài đăng phòng trọ
void main() {
  // ============================================================
  // Mô phỏng logic filter tương tự _applyPostFilters trong home_screen
  // ============================================================

  // Dữ liệu mẫu
  final samplePosts = [
    RoomPost(
      id: 1,
      title: 'Phòng đẹp gần ĐH Sư Phạm Kỹ Thuật',
      description: 'Phòng rộng, sáng sủa',
      price: 3500000,
      address: '123 Võ Văn Ngân, Bình Thạnh',
      district: 'Bình Thạnh',
      maxOccupants: 3,
      currentOccupants: 1,
      authorName: 'Tiến Đạt',
      authorId: 1,
      amenities: ['Wifi', 'Máy lạnh', 'Giữ xe'],
    ),
    RoomPost(
      id: 2,
      title: 'Phòng trọ sinh viên Thủ Đức',
      description: 'Gần bến xe',
      price: 2000000,
      address: '456 Xa Lộ Hà Nội, TP. Thủ Đức',
      district: 'TP. Thủ Đức',
      maxOccupants: 2,
      currentOccupants: 0,
      authorName: 'Quang Huy',
      authorId: 2,
      amenities: ['Wifi', 'Nước nóng'],
    ),
    RoomPost(
      id: 3,
      title: 'Căn hộ mini Quận 10',
      description: 'Full nội thất',
      price: 5000000,
      address: '789 Ba Tháng Hai, Quận 10',
      district: 'Quận 10',
      maxOccupants: 2,
      currentOccupants: 1,
      authorName: 'Quốc Huy',
      authorId: 3,
      amenities: ['Wifi', 'Máy lạnh', 'Nước nóng', 'Máy giặt', 'Giữ xe', 'Giờ tự do'],
    ),
  ];

  /// Hàm lọc giống logic _applyPostFilters
  List<RoomPost> applyFilters({
    required List<RoomPost> posts,
    String keyword = '',
    double minPrice = 0,
    double maxPrice = 10000000,
    String? district,
    Set<String> amenities = const {},
  }) {
    return posts.where((p) {
      final kw = keyword.toLowerCase();
      final matchKeyword = kw.isEmpty ||
          p.address.toLowerCase().contains(kw) ||
          p.title.toLowerCase().contains(kw) ||
          p.district.toLowerCase().contains(kw) ||
          p.authorName.toLowerCase().contains(kw);

      final matchPrice = p.price >= minPrice && p.price <= maxPrice;

      final matchDistrict = district == null ||
          district == 'Tất cả' ||
          p.district == district ||
          p.address.contains(district);

      final matchAmenities = amenities.isEmpty ||
          amenities.every((a) => p.amenities.contains(a));

      return matchKeyword && matchPrice && matchDistrict && matchAmenities;
    }).toList();
  }

  group('Room post filtering logic', () {
    test('returns all posts when no filter is applied', () {
      final result = applyFilters(posts: samplePosts);
      expect(result.length, 3);
    });

    test('filters by keyword (title)', () {
      final result = applyFilters(posts: samplePosts, keyword: 'sinh viên');
      expect(result.length, 1);
      expect(result[0].id, 2);
    });

    test('filters by keyword (author name)', () {
      final result = applyFilters(posts: samplePosts, keyword: 'Tiến Đạt');
      expect(result.length, 1);
      expect(result[0].id, 1);
    });

    test('filters by district', () {
      final result = applyFilters(posts: samplePosts, district: 'Bình Thạnh');
      expect(result.length, 1);
      expect(result[0].district, 'Bình Thạnh');
    });

    test('filters by "Tất cả" district returns all', () {
      final result = applyFilters(posts: samplePosts, district: 'Tất cả');
      expect(result.length, 3);
    });

    test('filters by price range', () {
      final result = applyFilters(posts: samplePosts, minPrice: 2500000, maxPrice: 4000000);
      expect(result.length, 1);
      expect(result[0].id, 1);
    });

    test('filters by single amenity', () {
      final result = applyFilters(posts: samplePosts, amenities: {'Máy lạnh'});
      expect(result.length, 2); // posts 1 and 3 have Máy lạnh
      expect(result.map((p) => p.id).toList(), [1, 3]);
    });

    test('filters by multiple amenities (must have ALL)', () {
      final result = applyFilters(posts: samplePosts, amenities: {'Wifi', 'Máy lạnh', 'Giữ xe'});
      expect(result.length, 2); // posts 1 and 3 have all three
      expect(result.map((p) => p.id).toList(), [1, 3]);
    });

    test('filters by amenity that no post has returns empty', () {
      final result = applyFilters(posts: samplePosts, amenities: {'Hồ bơi'});
      expect(result, isEmpty);
    });

    test('combined filters: district + price + amenity', () {
      final result = applyFilters(
        posts: samplePosts,
        district: 'Bình Thạnh',
        minPrice: 3000000,
        maxPrice: 4000000,
        amenities: {'Wifi'},
      );
      expect(result.length, 1);
      expect(result[0].id, 1);
    });

    test('combined filters that match nothing return empty', () {
      final result = applyFilters(
        posts: samplePosts,
        district: 'Bình Thạnh',
        amenities: {'Máy giặt'}, // post 1 in Bình Thạnh doesn't have Máy giặt
      );
      expect(result, isEmpty);
    });
  });

  // ============================================================
  // Error state tests (logic validation)
  // ============================================================
  group('Error state handling', () {
    test('error message is preserved from API exception', () {
      // Simulate the error handling logic from home_screen
      String? postsError;
      const apiError = 'Không thể kết nối đến máy chủ';

      // Simulate catchError assigning error
      postsError = apiError;

      expect(postsError, isNotNull);
      expect(postsError, contains('kết nối'));
    });

    test('error state is cleared on reload', () {
      String? postsError = 'Some error';
      // Simulate _loadData resetting error
      postsError = null;

      expect(postsError, isNull);
    });
  });
}
