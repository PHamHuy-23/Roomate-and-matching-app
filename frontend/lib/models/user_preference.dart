import 'package:intl/intl.dart';
import 'district_names.dart';

class UserPreference {
  static final NumberFormat _currencyFmt = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );

  static const Map<String, String> districtMap = DistrictNames.labels;

  final String targetDistrict;
  final double budgetAmount;
  final int sleepHabit;
  final int cleanlinessLevel;
  final bool isSmoking;
  final bool allowPets;
  final String? bioDescription;
  final DateTime? moveInDate;
  final String? roomType;
  final String? workSchedule;
  final String? personalValue;

  static const roomTypeValues = {'PRIVATE', 'SHARED'};
  static const workScheduleValues = {'DAY', 'NIGHT'};
  static const personalValueValues = {'PRIVACY', 'SCHEDULE', 'CLEAN'};

  static String? parseSurveyChoice(Object? value, Set<String> allowed) {
    if (value == null) return null;
    if (value is! String || !allowed.contains(value)) {
      throw const FormatException('Lựa chọn khảo sát đã lưu không hợp lệ');
    }
    return value;
  }

  static DateTime? parseMoveInDate(Object? value) {
    if (value == null) return null;
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Ngày chuyển vào đã lưu không hợp lệ');
    }
    final parsed = DateTime.tryParse(value);
    // DateTime.parse normalizes invalid dates (e.g. February 30); reject them.
    if (parsed == null || DateFormat('yyyy-MM-dd').format(parsed) != value) {
      throw const FormatException('Ngày chuyển vào đã lưu không hợp lệ');
    }
    return parsed;
  }

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
    this.moveInDate,
    this.roomType,
    this.workSchedule,
    this.personalValue,
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
            final nums = numMatches
                .map((m) {
                  final cleanStr = m.group(1)!.replaceAll('.', '');
                  return double.tryParse(cleanStr);
                })
                .whereType<double>()
                .toList();
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
      moveInDate: parseMoveInDate(json['moveInDate']),
      roomType: parseSurveyChoice(json['roomType'], roomTypeValues),
      workSchedule: parseSurveyChoice(json['workSchedule'], workScheduleValues),
      personalValue: parseSurveyChoice(
        json['personalValue'],
        personalValueValues,
      ),
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

  String get districtDisplay => DistrictNames.display(targetDistrict);

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
      if (petHabit == 'LOVE_PETS' ||
          petHabit!.contains('Thích') ||
          petHabit!.contains('Nuôi')) {
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
