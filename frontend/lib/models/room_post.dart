class RoomPost {
  final int id;
  final String title;
  final String description;
  final double price;
  final String address;
  final int maxOccupants;
  final String authorName;
  final int authorId;
  final String? imageUrl;
  final double? areaM2;
  final List<String> amenities;

  RoomPost({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.address,
    required this.maxOccupants,
    required this.authorName,
    required this.authorId,
    this.imageUrl,
    this.areaM2,
    this.amenities = const <String>[],
  });

  factory RoomPost.fromJson(Map<String, dynamic> json) {
    return RoomPost(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
      maxOccupants: json['maxOccupants'] as int? ?? 1,
      authorName: json['authorName'] as String? ?? 'Ẩn danh',
      authorId: json['authorId'] as int? ?? 0,
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String?,
      areaM2: (json['areaM2'] ?? json['area_m2'] ?? json['area']) is num
          ? ((json['areaM2'] ?? json['area_m2'] ?? json['area']) as num)
                .toDouble()
          : null,
      amenities:
          (json['amenities'] as List<dynamic>?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const <String>[],
    );
  }
}
