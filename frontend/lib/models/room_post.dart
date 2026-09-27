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
  final double? areaM2;
  final List<String> amenities;
  final double? deposit;
  final double? electricityWaterCost;
  final String status;
  final String? createdAt;

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
    this.areaM2,
    this.amenities = const <String>[],
    this.deposit,
    this.electricityWaterCost,
    this.status = 'AVAILABLE',
    this.createdAt,
  });

  factory RoomPost.fromJson(Map<String, dynamic> json) {
    final rawAmenities = json['amenities'];
    final amenities = switch (rawAmenities) {
      List<dynamic> values =>
        values
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false),
      String value =>
        value
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false),
      _ => const <String>[],
    };
    return RoomPost(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
      district: json['district'] as String? ?? '',
      maxOccupants: json['maxOccupants'] as int? ?? 1,
      currentOccupants: json['currentOccupants'] as int? ?? 0,
      authorName: json['authorName'] as String? ?? 'Ẩn danh',
      authorId: json['authorId'] as int? ?? 0,
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String?,
      areaM2: (json['areaM2'] ?? json['area_m2'] ?? json['area']) is num
          ? ((json['areaM2'] ?? json['area_m2'] ?? json['area']) as num)
                .toDouble()
          : null,
      amenities: amenities,
      deposit: (json['deposit'] as num?)?.toDouble(),
      electricityWaterCost: (json['electricityWaterCost'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'AVAILABLE',
      createdAt: json['createdAt'] as String?,
    );
  }
}
