/// Compatibility names from the existing catalogue, not a geocoder.
class DistrictNames {
  static const labels = <String, String>{
    'Thu Duc': 'TP. Thủ Đức',
    'Quan 1': 'Quận 1',
    'Quan 3': 'Quận 3',
    'Quan 4': 'Quận 4',
    'Quan 5': 'Quận 5',
    'Quan 6': 'Quận 6',
    'Quan 7': 'Quận 7',
    'Quan 8': 'Quận 8',
    'Quan 10': 'Quận 10',
    'Quan 11': 'Quận 11',
    'Quan 12': 'Quận 12',
    'Binh Thanh': 'Bình Thạnh',
    'Go Vap': 'Gò Vấp',
    'Phu Nhuan': 'Phú Nhuận',
    'Tan Binh': 'Tân Bình',
    'Tan Phu': 'Tân Phú',
    'Binh Tan': 'Bình Tân',
    'Binh Chanh': 'Huyện Bình Chánh',
    'Hoc Mon': 'Huyện Hóc Môn',
    'Nha Be': 'Huyện Nhà Bè',
  };

  static String fold(String value) {
    var result = value.toLowerCase();
    const groups = <String, String>{
      'àáạảãâầấậẩẫăằắặẳẵ': 'a',
      'èéẹẻẽêềếệểễ': 'e',
      'ìíịỉĩ': 'i',
      'òóọỏõôồốộổỗơờớợởỡ': 'o',
      'ùúụủũưừứựửữ': 'u',
      'ỳýỵỷỹ': 'y',
      'đ': 'd',
    };
    for (final group in groups.entries) {
      for (final rune in group.key.runes) {
        result = result.replaceAll(String.fromCharCode(rune), group.value);
      }
    }
    return result
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String canonical(String? value) {
    final trimmed = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    var comparable = fold(trimmed)
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceFirst(
          RegExp(r'\s+(?:(?:tp|thanh pho)\s+)?(?:hcm|ho chi minh)$'),
          '',
        )
        .replaceFirst(RegExp(r'^(?:tp|thanh pho|huyen)\s+'), '');
    final number = RegExp(r'^(?:q|quan)\s*(\d+)$').firstMatch(comparable);
    if (number != null) {
      comparable = 'quan ${number.group(1)}';
    } else {
      comparable = comparable.replaceFirst(RegExp(r'^quan\s+'), '');
    }
    for (final key in labels.keys) {
      if (fold(key) == comparable) return key;
    }
    return trimmed;
  }

  static String display(String? value) {
    final key = canonical(value);
    return labels[key] ?? (key.isEmpty ? 'Chưa chọn' : key);
  }

  static bool same(String? left, String? right) {
    final a = canonical(left);
    final b = canonical(right);
    return a.isNotEmpty && b.isNotEmpty && fold(a) == fold(b);
  }

  /// Explicit district is authoritative; use address only for legacy empty fields.
  /// Token boundaries prevent Quận 1 from matching Quận 10/11/12.
  static bool matchesRoom({
    required String district,
    required String address,
    required String selected,
  }) {
    if (district.trim().isNotEmpty) return same(district, selected);
    final key = canonical(selected);
    if (!labels.containsKey(key)) return false;
    final text = fold(address).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    final aliases = <String>{
      fold(key),
      fold(labels[key]!).replaceFirst(RegExp(r'^(?:tp|huyen)\s+'), ''),
    };
    if (key.startsWith('Quan ')) aliases.add('q ${key.substring(5)}');
    return aliases.any(
      (alias) => RegExp('(^| )${RegExp.escape(alias)}( |\$)').hasMatch(text),
    );
  }
}
