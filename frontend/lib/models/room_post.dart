class RoomPost {
  final int id;
  final String title;
  final String description;
  final double price;
  final String address;
  final String district;
  final int maxOccupants;
  final int currentOccupants;
  final String authorName;
  final int authorId;
  final String? imageUrl;
  final List<String> amenities;
  final double? deposit;
  final double? electricityWaterCost;
  final double? area;
  final String status;
  final String? createdAt;
  final int viewCount;

  RoomPost({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.address,
    this.district = '',
    required this.maxOccupants,
    this.currentOccupants = 0,
    required this.authorName,
    required this.authorId,
    this.imageUrl,
    this.amenities = const [],
    this.deposit,
    this.electricityWaterCost,
    this.area,
    this.status = 'AVAILABLE',
    this.createdAt,
    this.viewCount = 0,
  });

  factory RoomPost.fromJson(Map<String, dynamic> json) {
    // Parse amenities từ JSON (có thể là List<String> hoặc chuỗi phân tách bằng dấu phẩy)
    List<String> parseAmenities(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String && raw.isNotEmpty) {
        return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    // Trích xuất quận/huyện từ địa chỉ nếu backend không trả về trường district riêng
    String extractDistrict(String address, String? district) {
      if (district != null && district.isNotEmpty) return district;
      // Thử tìm các quận phổ biến trong địa chỉ
      final knownDistricts = [
        'Bình Thạnh', 'Thủ Đức', 'Quận 1', 'Quận 2', 'Quận 3',
        'Quận 4', 'Quận 5', 'Quận 6', 'Quận 7', 'Quận 8',
        'Quận 9', 'Quận 10', 'Quận 11', 'Quận 12',
        'Gò Vấp', 'Tân Bình', 'Tân Phú', 'Phú Nhuận',
        'Bình Tân', 'Nhà Bè', 'Hóc Môn', 'Củ Chi',
      ];
      for (final d in knownDistricts) {
        if (address.toLowerCase().contains(d.toLowerCase())) return d;
      }
      return '';
    }

    final address = json['address'] as String? ?? '';

    return RoomPost(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      address: address,
      district: extractDistrict(address, json['district'] as String?),
      maxOccupants: json['maxOccupants'] as int? ?? 1,
      currentOccupants: json['currentOccupants'] as int? ?? 0,
      authorName: json['authorName'] as String? ?? 'Ẩn danh',
      authorId: json['authorId'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String?,
      amenities: parseAmenities(json['amenities']),
      deposit: (json['deposit'] as num?)?.toDouble(),
      electricityWaterCost: (json['electricityWaterCost'] as num?)?.toDouble(),
      area: (json['area'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'AVAILABLE',
      createdAt: json['createdAt'] as String?,
      viewCount: json['viewCount'] as int? ?? 0,
    );
  }

  /// Tính thời gian đăng tương đối (VD: "2 giờ trước", "Hôm qua")
  String get timeAgo {
    if (createdAt == null || createdAt!.isEmpty) return '';
    try {
      final created = DateTime.parse(createdAt!);
      final now = DateTime.now();
      final diff = now.difference(created);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
      return '${(diff.inDays / 30).floor()} tháng trước';
    } catch (_) {
      return '';
    }
  }

  /// Map emoji cho tiện ích
  static const Map<String, String> amenityIcons = {
    'Wifi': '📶',
    'Máy lạnh': '❄️',
    'Nước nóng': '🚿',
    'Máy giặt': '🧺',
    'Giữ xe': '🛵',
    'Giờ tự do': '🔑',
  };
}