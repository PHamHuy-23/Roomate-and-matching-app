import 'package:intl/intl.dart';

class UserPreference {
  static final NumberFormat _currencyFmt =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  static const Map<String, String> districtMap = {
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

  final String targetDistrict;
  final double budgetAmount;
  final int sleepHabit;
  final int cleanlinessLevel;
  final bool isSmoking;
  final bool allowPets;
  final String? bioDescription;

  // Parsed metadata fields from bioDescription
  final String? targetGender;
  final double? minBudget;
  final double? maxBudget;
  final String? cookingHabit;
  final String? petHabit;
  final String? personality;
  final List<String> interests;
  final String? moveInTime;
  final String? topPriority;
  final String? bioNote;

  const UserPreference({
    required this.targetDistrict,
    required this.budgetAmount,
    required this.sleepHabit,
    required this.cleanlinessLevel,
    required this.isSmoking,
    required this.allowPets,
    this.bioDescription,
    this.targetGender,
    this.minBudget,
    this.maxBudget,
    this.cookingHabit,
    this.petHabit,
    this.personality,
    this.interests = const [],
    this.moveInTime,
    this.topPriority,
    this.bioNote,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    final district = (json['targetDistrict'] as String?) ?? '';
    final budget = (json['budgetAmount'] as num?)?.toDouble() ?? 0.0;
    final sleep = (json['sleepHabit'] as int?) ?? 1;
    final clean = (json['cleanlinessLevel'] as num?)?.toInt() ?? 3;
    final smoking = (json['isSmoking'] as bool?) ?? false;
    final pets = (json['allowPets'] as bool?) ?? false;
    final rawBio = (json['bioDescription'] as String?) ?? '';

    String? targetGender;
    double? minB;
    double? maxB;
    String? cooking;
    String? petH = pets ? 'LOVE_PETS' : 'NO_PETS';
    String? personality;
    List<String> interestsList = [];
    String? moveIn;
    String? priority;
    String? note;

    if (rawBio.isNotEmpty) {
      final metaRegex = RegExp(r'^\[(.*?)\](?:\n(.*))?$', dotAll: true);
      final match = metaRegex.firstMatch(rawBio);
      if (match != null) {
        final metaPart = match.group(1) ?? '';
        final notePart = match.group(2) ?? '';
        if (notePart.trim().isNotEmpty) {
          note = notePart.trim();
        }

        final parts = metaPart.split('|').map((s) => s.trim()).toList();
        for (final part in parts) {
          if (part.startsWith('Yêu cầu giới tính:')) {
            targetGender = part.replaceFirst('Yêu cầu giới tính:', '').trim();
          } else if (part.startsWith('Ngân sách:')) {
            final numMatches = RegExp(r'([\d\.]+)').allMatches(part);
            final nums = numMatches.map((m) {
              final cleanStr = m.group(1)!.replaceAll('.', '');
              return double.tryParse(cleanStr);
            }).whereType<double>().toList();
            if (nums.length >= 2) {
              minB = nums[0];
              maxB = nums[1];
            }
          } else if (part.startsWith('Nấu ăn:')) {
            cooking = part.replaceFirst('Nấu ăn:', '').trim();
          } else if (part.startsWith('Thú cưng:')) {
            petH = part.replaceFirst('Thú cưng:', '').trim();
          } else if (part.startsWith('Tính cách:')) {
            personality = part.replaceFirst('Tính cách:', '').trim();
          } else if (part.startsWith('Sở thích:')) {
            final val = part.replaceFirst('Sở thích:', '').trim();
            interestsList = val
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          } else if (part.startsWith('Dọn vào:')) {
            moveIn = part.replaceFirst('Dọn vào:', '').trim();
          } else if (part.startsWith('Ưu tiên:')) {
            priority = part.replaceFirst('Ưu tiên:', '').trim();
          }
        }
      } else {
        note = rawBio;
      }
    }

    return UserPreference(
      targetDistrict: district,
      budgetAmount: budget,
      sleepHabit: sleep,
      cleanlinessLevel: clean,
      isSmoking: smoking,
      allowPets: pets,
      bioDescription: rawBio,
      targetGender: targetGender,
      minBudget: minB,
      maxBudget: maxB,
      cookingHabit: cooking,
      petHabit: petH,
      personality: personality,
      interests: interestsList,
      moveInTime: moveIn,
      topPriority: priority,
      bioNote: note,
    );
  }

  String get districtDisplay =>
      districtMap[targetDistrict] ??
      (targetDistrict.isNotEmpty ? targetDistrict : 'Chưa chọn');

  String get budgetDisplay {
    if (minBudget != null && maxBudget != null) {
      return '${_currencyFmt.format(minBudget)} - ${_currencyFmt.format(maxBudget)}';
    }
    if (budgetAmount > 0) {
      return '${_currencyFmt.format(budgetAmount)}/tháng';
    }
    return 'Chưa thiết lập';
  }

  String get sleepHabitDisplay {
    switch (sleepHabit) {
      case 1:
        return 'Dậy sớm (Early Bird)';
      case 2:
        return 'Linh hoạt / Bình thường';
      case 3:
        return 'Cú đêm (Night Owl)';
      default:
        return 'Chưa rõ';
    }
  }

  String get cleanlinessDisplay => '$cleanlinessLevel★ / 5★';

  String get smokingDisplay => isSmoking ? 'Có hút thuốc' : 'Không hút thuốc';

  String get petDisplay {
    if (petHabit != null && petHabit!.isNotEmpty) {
      if (petHabit == 'LOVE_PETS' || petHabit!.contains('Thích') || petHabit!.contains('Nuôi')) {
        return 'Thích / Nuôi thú cưng';
      }
      if (petHabit == 'ALLERGIC' || petHabit!.contains('Dị ứng')) {
        return 'Dị ứng thú cưng';
      }
      if (petHabit == 'NO_PETS' || petHabit!.contains('Không')) {
        return 'Không nuôi thú cưng';
      }
      return petHabit!;
    }
    return allowPets ? 'Thích / Nuôi thú cưng' : 'Không nuôi thú cưng';
  }
}
