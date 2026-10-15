/// Compatibility between existing room data and the current parking option.
class RoomAmenities {
  static const parking = 'Giữ xe';

  static String canonical(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return switch (trimmed.toLowerCase()) {
      'giữ xe' || 'chỗ để xe' => parking,
      _ => trimmed,
    };
  }

  static String key(String value) => canonical(value).toLowerCase();

  static List<String> normalize(Iterable<String> values) => List.unmodifiable(
    values.map(canonical).where((value) => value.isNotEmpty).toSet(),
  );
}
