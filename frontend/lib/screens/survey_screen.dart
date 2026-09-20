import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../navigation/app_routes.dart';
import '../services/api_service.dart';

class SurveyScreen extends StatefulWidget {
  final int userId;
  final ApiService? apiService;
  final bool redirectToHomeOnComplete;

  const SurveyScreen({
    super.key,
    required this.userId,
    this.apiService,
    this.redirectToHomeOnComplete = false,
  });

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  late final ApiService _api;
  final NumberFormat fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  int _currentStep = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  // Các trường hiển thị trong handoff Penpot. Một số trường chưa có cột tương
  // ứng trong API preferences nên chỉ được dùng để hoàn thiện trải nghiệm UI;
  // dữ liệu lõi vẫn được lưu qua payload hiện có ở _save().
  DateTime _moveInDate = DateTime(2026, 10, 1);
  String _roomType = 'SHARED';
  String _workSchedule = 'DAY';

  // Bước 1: Ngân sách, Khu vực & Giới tính (UC-07, FR-07 - Tiêu chí cứng)
  RangeValues _budgetRange = const RangeValues(2000000, 4000000);
  String _district = 'Binh Thanh';
  String _targetGender = 'ANY'; // ANY, MALE, FEMALE (Theo UC-07)

  // Bước 2: Lối sống sinh hoạt (UC-08, FR-08)
  int _sleepHabit =
      1; // 1: Dậy sớm (Early Bird), 2: Bình thường, 3: Cú đêm (Night Owl)
  String _cookingHabit = 'COOK_HOME'; // COOK_HOME, EAT_OUT, FLEXIBLE

  // Bước 3: Thói quen cá nhân (UC-08, FR-08)
  double _cleanliness = 4.0; // 1.0 -> 5.0
  bool _isSmoking = false;
  String _petHabit = 'NO_PETS'; // LOVE_PETS, ALLERGIC, NO_PETS
  bool _allowPets = false;

  // Bước 4: Tính cách, Sở thích & Kế hoạch ở (UC-08, UC-25, UC-42 - FR-25, FR-42)
  String _personality = 'AMBIVERT'; // INTROVERT, EXTROVERT, AMBIVERT
  Set<String> _selectedInterests = {'Nấu ăn', 'Đọc sách', 'Chạy bộ'};
  String _moveInTime =
      'ASAP'; // ASAP: Dọn vào ngay, TWO_WEEKS: Trong 2 tuần, NEXT_MONTH: Đầu tháng sau, FLEXIBLE: Linh hoạt
  String _topPriority =
      'CLEAN'; // BUDGET, SLEEP, CLEAN, SMOKING (FR-25 Trọng số động)
  // Giá trị hiển thị riêng ở bước 4 theo handoff Penpot; ưu tiên ghép đôi
  // (_topPriority) vẫn được lưu trong payload ở bước 5.
  String _personalValue = 'PRIVACY';
  final TextEditingController _bioCtrl = TextEditingController();

  static const Map<String, String> _districtMap = {
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

  static const List<Map<String, dynamic>> _interestOptions = [
    {'name': 'Thể thao', 'icon': Icons.sports_soccer},
    {'name': 'Đọc sách', 'icon': Icons.menu_book},
    {'name': 'Chơi game', 'icon': Icons.sports_esports},
    {'name': 'Xem phim', 'icon': Icons.movie},
    {'name': 'Du lịch', 'icon': Icons.flight_takeoff},
    {'name': 'Âm nhạc', 'icon': Icons.music_note},
    {'name': 'Nấu ăn', 'icon': Icons.soup_kitchen},
    {'name': 'Chạy bộ', 'icon': Icons.directions_run},
    {'name': 'Nhiếp ảnh', 'icon': Icons.camera_alt},
    {'name': 'Công nghệ', 'icon': Icons.laptop_chromebook},
    {'name': 'Board game', 'icon': Icons.casino},
    {'name': 'Nghệ thuật', 'icon': Icons.palette},
    {'name': 'Học ngoại ngữ', 'icon': Icons.translate},
  ];

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _loadPreferences();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  String _districtDisplay(String distKey) {
    return _districtMap[distKey] ?? distKey;
  }

  String _districtFieldDisplay(String distKey) {
    if (distKey == 'Binh Thanh') return 'Bình Thạnh, TP. Hồ Chí Minh';
    return _districtDisplay(distKey);
  }

  String _targetGenderLabel(String gender) {
    switch (gender) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
        return 'Nữ';
      default:
        return 'Tất cả / Không yêu cầu';
    }
  }

  String _sleepHabitLabel(int habit) {
    switch (habit) {
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

  String _cookingHabitLabel(String habit) {
    switch (habit) {
      case 'COOK_HOME':
        return 'Tự nấu ở nhà';
      case 'EAT_OUT':
        return 'Ăn ngoài / Tiện lợi';
      case 'FLEXIBLE':
        return 'Linh hoạt';
      default:
        return habit;
    }
  }

  String _petHabitLabel(String habit) {
    switch (habit) {
      case 'LOVE_PETS':
        return 'Thích / Nuôi thú cưng';
      case 'ALLERGIC':
        return 'Dị ứng thú cưng';
      case 'NO_PETS':
        return 'Không nuôi thú cưng';
      default:
        return habit;
    }
  }

  String _personalityLabel(String p) {
    switch (p) {
      case 'INTROVERT':
        return 'Hướng nội';
      case 'EXTROVERT':
        return 'Hướng ngoại';
      case 'AMBIVERT':
        return 'Linh hoạt (Ambivert)';
      default:
        return p;
    }
  }

  String _moveInTimeLabel(String m) {
    switch (m) {
      case 'ASAP':
        return 'Dọn vào ở ngay';
      case 'TWO_WEEKS':
        return 'Trong vòng 1-2 tuần';
      case 'NEXT_MONTH':
        return 'Đầu tháng tới';
      case 'FLEXIBLE':
        return 'Linh hoạt thỏa thuận';
      default:
        return m;
    }
  }

  String _topPriorityLabel(String pr) {
    switch (pr) {
      case 'BUDGET':
        return 'Ngân sách phù hợp';
      case 'SLEEP':
        return 'Giờ giấc sinh hoạt tương đồng';
      case 'CLEAN':
        return 'Mức độ sạch sẽ ngăn nắp';
      case 'SMOKING':
        return 'Không khói thuốc (Tuyệt đối)';
      default:
        return pr;
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final data = await _api.getPreferences(widget.userId);
      if (data != null) {
        setState(() {
          final targetDist = data['targetDistrict'] as String?;
          if (targetDist != null && targetDist.isNotEmpty) {
            _district = targetDist;
          }

          final loadedBudget =
              (data['budgetAmount'] as num?)?.toDouble() ?? 3000000.0;
          _sleepHabit = (data['sleepHabit'] as int?) ?? 1;
          _cleanliness = ((data['cleanlinessLevel'] as num?)?.toDouble() ?? 4.0)
              .clamp(1.0, 5.0);
          _isSmoking = (data['isSmoking'] as bool?) ?? false;
          _allowPets = (data['allowPets'] as bool?) ?? false;
          _petHabit = _allowPets ? 'LOVE_PETS' : 'NO_PETS';

          final rawBio = (data['bioDescription'] as String?) ?? '';
          _parseBioDescription(rawBio, loadedBudget);
        });
      }
    } catch (_) {
      // Giữ giá trị mặc định nếu người dùng mới chưa từng làm khảo sát
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _parseBioDescription(String rawBio, double fallbackBudget) {
    if (rawBio.isEmpty) {
      final minB = (fallbackBudget * 0.7).clamp(1000000.0, 14000000.0);
      final maxB = fallbackBudget.clamp(minB + 500000.0, 15000000.0);
      _budgetRange = RangeValues(minB, maxB);
      return;
    }

    final metaRegex = RegExp(r'^\[(.*?)\](?:\n(.*))?$', dotAll: true);
    final match = metaRegex.firstMatch(rawBio);
    if (match != null) {
      final metaPart = match.group(1) ?? '';
      final notePart = match.group(2) ?? '';
      _bioCtrl.text = notePart.trim();

      final parts = metaPart.split('|').map((s) => s.trim()).toList();
      double? parsedMin;
      double? parsedMax;

      for (final part in parts) {
        if (part.startsWith('Yêu cầu giới tính:')) {
          final val = part.replaceFirst('Yêu cầu giới tính:', '').trim();
          if (val.contains('Nam')) {
            _targetGender = 'MALE';
          } else if (val.contains('Nữ')) {
            _targetGender = 'FEMALE';
          } else {
            _targetGender = 'ANY';
          }
        } else if (part.startsWith('Ngân sách:')) {
          final numMatches = RegExp(r'([\d\.]+)').allMatches(part);
          final nums = numMatches
              .map((m) {
                final clean = m.group(1)!.replaceAll('.', '');
                return double.tryParse(clean);
              })
              .whereType<double>()
              .toList();
          if (nums.length >= 2) {
            parsedMin = nums[0].clamp(1000000.0, 14500000.0);
            parsedMax = nums[1].clamp(1500000.0, 15000000.0);
          }
        } else if (part.startsWith('Nấu ăn:')) {
          final val = part.replaceFirst('Nấu ăn:', '').trim();
          if (val.contains('Tự nấu')) {
            _cookingHabit = 'COOK_HOME';
          } else if (val.contains('Ăn ngoài')) {
            _cookingHabit = 'EAT_OUT';
          } else if (val.contains('Linh hoạt')) {
            _cookingHabit = 'FLEXIBLE';
          }
        } else if (part.startsWith('Thú cưng:')) {
          final val = part.replaceFirst('Thú cưng:', '').trim();
          if (val.contains('Thích') || val.contains('Nuôi')) {
            _petHabit = 'LOVE_PETS';
            _allowPets = true;
          } else if (val.contains('Dị ứng')) {
            _petHabit = 'ALLERGIC';
            _allowPets = false;
          } else {
            _petHabit = 'NO_PETS';
            _allowPets = false;
          }
        } else if (part.startsWith('Tính cách:')) {
          final val = part.replaceFirst('Tính cách:', '').trim();
          if (val.contains('Hướng nội')) {
            _personality = 'INTROVERT';
          } else if (val.contains('Hướng ngoại')) {
            _personality = 'EXTROVERT';
          } else {
            _personality = 'AMBIVERT';
          }
        } else if (part.startsWith('Sở thích:')) {
          final val = part.replaceFirst('Sở thích:', '').trim();
          final list = val
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toSet();
          if (list.isNotEmpty) _selectedInterests = list;
        } else if (part.startsWith('Dọn vào:')) {
          final val = part.replaceFirst('Dọn vào:', '').trim();
          if (val.contains('ngay')) {
            _moveInTime = 'ASAP';
          } else if (val.contains('2 tuần')) {
            _moveInTime = 'TWO_WEEKS';
          } else if (val.contains('tháng tới')) {
            _moveInTime = 'NEXT_MONTH';
          } else {
            _moveInTime = 'FLEXIBLE';
          }
        } else if (part.startsWith('Ưu tiên:')) {
          final val = part.replaceFirst('Ưu tiên:', '').trim();
          if (val.contains('Ngân sách')) {
            _topPriority = 'BUDGET';
          } else if (val.contains('Giờ giấc')) {
            _topPriority = 'SLEEP';
          } else if (val.contains('Sạch sẽ')) {
            _topPriority = 'CLEAN';
          } else if (val.contains('thuốc lá')) {
            _topPriority = 'SMOKING';
          }
        }
      }

      if (parsedMin != null && parsedMax != null && parsedMin < parsedMax) {
        _budgetRange = RangeValues(parsedMin, parsedMax);
      } else {
        final minB = (fallbackBudget * 0.7).clamp(1000000.0, 14000000.0);
        final maxB = fallbackBudget.clamp(minB + 500000.0, 15000000.0);
        _budgetRange = RangeValues(minB, maxB);
      }
    } else {
      _bioCtrl.text = rawBio;
      final minB = (fallbackBudget * 0.7).clamp(1000000.0, 14000000.0);
      final maxB = fallbackBudget.clamp(minB + 500000.0, 15000000.0);
      _budgetRange = RangeValues(minB, maxB);
    }
  }

  String _buildBioDescription() {
    final note = _bioCtrl.text.trim();
    final meta = [
      'Yêu cầu giới tính: ${_targetGenderLabel(_targetGender)}',
      'Ngân sách: ${fmt.format(_budgetRange.start)} - ${fmt.format(_budgetRange.end)}',
      'Nấu ăn: ${_cookingHabitLabel(_cookingHabit)}',
      'Thú cưng: ${_petHabitLabel(_petHabit)}',
      'Tính cách: ${_personalityLabel(_personality)}',
      if (_selectedInterests.isNotEmpty)
        'Sở thích: ${_selectedInterests.join(", ")}',
      'Dọn vào: ${_moveInTimeLabel(_moveInTime)}',
      'Ưu tiên: ${_topPriorityLabel(_topPriority)}',
    ].join(' | ');

    if (note.isEmpty) {
      return '[$meta]';
    }
    return '[$meta]\n$note';
  }

  bool _validateStep(int stepIndex) {
    switch (stepIndex) {
      case 0:
        if (_district.trim().isEmpty) {
          _showWarningSnackBar('Vui lòng chọn Quận/Huyện mong muốn tìm phòng!');
          return false;
        }
        if (_budgetRange.start >= _budgetRange.end) {
          _showWarningSnackBar(
            'Ngân sách tối thiểu phải nhỏ hơn ngân sách tối đa!',
          );
          return false;
        }
        return true;
      case 1:
        if (_sleepHabit != 1 && _sleepHabit != 2 && _sleepHabit != 3) {
          _showWarningSnackBar('Vui lòng chọn thói quen giờ giấc ngủ nghỉ!');
          return false;
        }
        if (_cookingHabit.isEmpty) {
          _showWarningSnackBar('Vui lòng chọn thói quen nấu ăn!');
          return false;
        }
        return true;
      case 2:
        if (_cleanliness < 1.0 || _cleanliness > 5.0) {
          _showWarningSnackBar(
            'Vui lòng đánh giá mức độ sạch sẽ từ 1 đến 5 sao!',
          );
          return false;
        }
        if (_petHabit.isEmpty) {
          _showWarningSnackBar('Vui lòng chọn quan điểm về thú cưng!');
          return false;
        }
        return true;
      case 3:
        if (_personality.isEmpty) {
          _showWarningSnackBar('Vui lòng chọn xu hướng tính cách của bạn!');
          return false;
        }
        if (_selectedInterests.isEmpty) {
          _showWarningSnackBar(
            'Vui lòng chọn ít nhất 1 sở thích để tìm bạn trọ phù hợp!',
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.deepOrange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onStepContinue() {
    if (!_validateStep(_currentStep)) return;

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _save();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // Kept for backward compatibility with older deep-link callers.
  // ignore: unused_element
  void _onStepTapped(int step) {
    if (step > _currentStep) {
      for (int s = _currentStep; s < step; s++) {
        if (!_validateStep(s)) return;
      }
    }
    setState(() => _currentStep = step);
  }

  Future<void> _save() async {
    for (int s = 0; s <= 3; s++) {
      if (!_validateStep(s)) {
        setState(() => _currentStep = s);
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      _allowPets = (_petHabit == 'LOVE_PETS');

      final payload = {
        'targetDistrict': _district,
        'budgetAmount': _budgetRange.end,
        'sleepHabit': _sleepHabit,
        'cleanlinessLevel': _cleanliness.toInt(),
        'isSmoking': _isSmoking,
        'allowPets': _allowPets,
        'bioDescription': _buildBioDescription(),
      };

      final ok = await _api.savePreferences(widget.userId, payload);
      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lưu tiêu chí thành công! Hệ thống đã tính toán lại gợi ý ghép đôi phù hợp nhất.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        if (widget.redirectToHomeOnComplete) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          Navigator.pop(context, true);
        }
      } else {
        _showWarningSnackBar('Lưu tiêu chí thất bại, vui lòng thử lại sau!');
      }
    } catch (e) {
      if (mounted) {
        _showWarningSnackBar('Lỗi kết nối: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ignore: unused_element
  StepState _getStepState(int stepIndex) {
    if (_currentStep > stepIndex) {
      return StepState.complete;
    } else if (_currentStep == stepIndex) {
      return StepState.editing;
    } else {
      return StepState.indexed;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Đang tải tiêu chí khảo sát...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _penpotCanvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                _buildPenpotHeader(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: SingleChildScrollView(
                      key: ValueKey(_currentStep),
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                      child: _buildPenpotStep(_currentStep),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _penpotCanvas = Color(0xFFF5F8F7);
  static const _penpotInk = Color(0xFF142523);
  static const _penpotMuted = Color(0xFF65746F);
  static const _penpotPrimary = Color(0xFF087E6B);
  static const _penpotSoft = Color(0xFFE8F4F1);

  Widget _buildPenpotHeader() {
    final titles = [
      'Bạn muốn ở đâu?',
      'Nhịp sống của bạn',
      'Thoải mái khi ở cùng',
      'Cá tính của bạn',
      'Sẵn sàng tìm bạn!',
    ];
    final sections = [
      'Ngân sách & khu vực',
      'Sinh hoạt hàng ngày',
      'Thói quen cá nhân',
      'Tính cách & sở thích',
      'Kiểm tra tiêu chí',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              BackButton(
                onPressed: _currentStep == 0
                    ? () => Navigator.maybePop(context)
                    : _onStepCancel,
                color: _penpotInk,
              ),
              const Spacer(),
              Text(
                '${_currentStep + 1} / 5 · ${sections[_currentStep]}',
                style: const TextStyle(
                  color: _penpotMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              titles[_currentStep],
              style: const TextStyle(
                color: _penpotInk,
                fontSize: 29,
                height: 1.12,
                fontWeight: FontWeight.w800,
                letterSpacing: -.6,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: (_currentStep + 1) / 5,
              backgroundColor: const Color(0xFFDCE8E4),
              valueColor: const AlwaysStoppedAnimation(_penpotPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenpotStep(int step) {
    switch (step) {
      case 0:
        return _buildPenpotLocationStep();
      case 1:
        return _buildPenpotLifestyleStep();
      case 2:
        return _buildPenpotComfortStep();
      case 3:
        return _buildPenpotPersonalityStep();
      default:
        return _buildPenpotSummaryStep();
    }
  }

  Widget _penpotSectionLabel(String label, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: _penpotPrimary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _penpotInk,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _penpotCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE9E5)),
      ),
      child: child,
    );
  }

  Widget _penpotChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? _penpotSoft : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _penpotPrimary : const Color(0xFFD6E2DE),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: selected ? _penpotPrimary : _penpotMuted,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? _penpotPrimary : _penpotInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _penpotContinueButton({
    String label = 'Tiếp tục',
    VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed ?? _onStepContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: _penpotPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving && _currentStep == 4
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPenpotLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn câu trả lời phản ánh thói quen thực tế\nđể gợi ý phù hợp hơn.',
          style: TextStyle(color: _penpotMuted, height: 1.35),
        ),
        const SizedBox(height: 18),
        _penpotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _penpotSectionLabel(
                'Ngân sách mỗi tháng',
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: 8),
              Text(
                '${fmt.format(_budgetRange.start)} — ${fmt.format(_budgetRange.end)}',
                style: const TextStyle(
                  color: _penpotPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              RangeSlider(
                values: _budgetRange,
                min: 1000000,
                max: 15000000,
                divisions: 28,
                activeColor: _penpotPrimary,
                inactiveColor: const Color(0xFFD5E4DF),
                onChanged: (value) => setState(() => _budgetRange = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _penpotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _penpotSectionLabel(
                'Khu vực ưu tiên',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _district,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _penpotCanvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                items: _districtMap.keys
                    .map(
                      (key) => DropdownMenuItem(
                        value: key,
                        child: Text(_districtFieldDisplay(key)),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _district = value ?? _district),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _penpotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _penpotSectionLabel(
                'Ngày chuyển vào dự kiến',
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _moveInDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null && mounted) {
                    setState(() => _moveInDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _penpotCanvas,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_moveInDate),
                    style: const TextStyle(
                      color: _penpotInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _penpotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _penpotSectionLabel('Bạn muốn tìm', icon: Icons.home_outlined),
              const SizedBox(height: 10),
              Row(
                children: [
                  _penpotChoice(
                    label: 'Phòng riêng',
                    selected: _roomType == 'PRIVATE',
                    onTap: () => setState(() => _roomType = 'PRIVATE'),
                  ),
                  const SizedBox(width: 8),
                  _penpotChoice(
                    label: 'Ở ghép',
                    selected: _roomType == 'SHARED',
                    onTap: () => setState(() => _roomType = 'SHARED'),
                  ),
                ],
              ),
            ],
          ),
        ),
        _penpotContinueButton(),
      ],
    );
  }

  Widget _buildPenpotLifestyleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn câu trả lời phản ánh thói quen thực tế\nđể gợi ý phù hợp hơn.',
          style: TextStyle(color: _penpotMuted, height: 1.35),
        ),
        const SizedBox(height: 18),
        _penpotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _penpotSectionLabel(
                'Giờ đi ngủ thường ngày',
                icon: Icons.nightlight_outlined,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _choiceChip(
                    'Trước 23:00',
                    _sleepHabit == 1,
                    () => setState(() => _sleepHabit = 1),
                  ),
                  _choiceChip(
                    '23:00 – 01:00',
                    _sleepHabit == 2,
                    () => setState(() => _sleepHabit = 2),
                  ),
                  _choiceChip(
                    'Sau 01:00',
                    _sleepHabit == 3,
                    () => setState(() => _sleepHabit = 3),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _penpotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _penpotSectionLabel(
                'Thói quen ăn uống',
                icon: Icons.restaurant_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _penpotChoice(
                    label: 'Tự nấu tại nhà',
                    selected: _cookingHabit == 'COOK_HOME',
                    onTap: () => setState(() => _cookingHabit = 'COOK_HOME'),
                  ),
                  const SizedBox(width: 8),
                  _penpotChoice(
                    label: 'Ăn ngoài',
                    selected: _cookingHabit == 'EAT_OUT',
                    onTap: () => setState(() => _cookingHabit = 'EAT_OUT'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _choiceChip(
                'Linh hoạt',
                _cookingHabit == 'FLEXIBLE',
                () => setState(() => _cookingHabit = 'FLEXIBLE'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _penpotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _penpotSectionLabel(
                'Lịch học / làm việc',
                icon: Icons.work_outline,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _penpotChoice(
                    label: 'Ban ngày',
                    selected: _workSchedule == 'DAY',
                    onTap: () => setState(() => _workSchedule = 'DAY'),
                  ),
                  const SizedBox(width: 8),
                  _penpotChoice(
                    label: 'Ban đêm',
                    selected: _workSchedule == 'NIGHT',
                    onTap: () => setState(() => _workSchedule = 'NIGHT'),
                  ),
                ],
              ),
            ],
          ),
        ),
        _penpotContinueButton(),
      ],
    );
  }

  Widget _buildPenpotComfortStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn câu trả lời phản ánh thói quen thực tế\nđể gợi ý phù hợp hơn.',
          style: TextStyle(color: _penpotMuted, height: 1.35),
        ),
        const SizedBox(height: 18),
        _penpotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _penpotSectionLabel(
                'Mức độ gọn gàng',
                icon: Icons.cleaning_services_outlined,
              ),
              const SizedBox(height: 6),
              Text(
                '${_cleanliness.toInt()} / 5 · Dọn dẹp thường xuyên',
                style: const TextStyle(
                  color: _penpotPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Slider(
                value: _cleanliness,
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: _penpotPrimary,
                onChanged: (value) => setState(() => _cleanliness = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _penpotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _penpotSectionLabel(
                'Hút thuốc',
                icon: Icons.smoking_rooms_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _penpotChoice(
                    label: 'Không hút thuốc',
                    selected: !_isSmoking,
                    onTap: () => setState(() => _isSmoking = false),
                  ),
                  const SizedBox(width: 8),
                  _penpotChoice(
                    label: 'Có hút thuốc',
                    selected: _isSmoking,
                    onTap: () => setState(() => _isSmoking = true),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _penpotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _penpotSectionLabel('Thú cưng', icon: Icons.pets_outlined),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _choiceChip(
                    'Có thể trao đổi trước',
                    _petHabit == 'NO_PETS',
                    () => setState(() => _petHabit = 'NO_PETS'),
                  ),
                  _choiceChip(
                    'Thích thú cưng',
                    _petHabit == 'LOVE_PETS',
                    () => setState(() => _petHabit = 'LOVE_PETS'),
                  ),
                  _choiceChip(
                    'Dị ứng thú cưng',
                    _petHabit == 'ALLERGIC',
                    () => setState(() => _petHabit = 'ALLERGIC'),
                  ),
                ],
              ),
            ],
          ),
        ),
        _penpotContinueButton(),
      ],
    );
  }

  Widget _buildPenpotPersonalityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn câu trả lời phản ánh thói quen thực tế\nđể gợi ý phù hợp hơn.',
          style: TextStyle(color: _penpotMuted, height: 1.35),
        ),
        const SizedBox(height: 18),
        _penpotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _penpotSectionLabel('Tính cách', icon: Icons.psychology_outlined),
              const SizedBox(height: 12),
              Row(
                children: [
                  _penpotChoice(
                    label: 'Hướng nội',
                    selected: _personality == 'INTROVERT',
                    onTap: () => setState(() => _personality = 'INTROVERT'),
                  ),
                  const SizedBox(width: 8),
                  _penpotChoice(
                    label: 'Linh hoạt',
                    selected: _personality == 'AMBIVERT',
                    onTap: () => setState(() => _personality = 'AMBIVERT'),
                  ),
                  const SizedBox(width: 8),
                  _penpotChoice(
                    label: 'Hướng ngoại',
                    selected: _personality == 'EXTROVERT',
                    onTap: () => setState(() => _personality = 'EXTROVERT'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _penpotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _penpotSectionLabel(
                'Điều bạn trân trọng',
                icon: Icons.favorite_border,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _choiceChip(
                    'Tôn trọng không gian riêng',
                    _personalValue == 'PRIVACY',
                    () => setState(() => _personalValue = 'PRIVACY'),
                  ),
                  _choiceChip(
                    'Giờ giấc tương đồng',
                    _personalValue == 'SCHEDULE',
                    () => setState(() => _personalValue = 'SCHEDULE'),
                  ),
                  _choiceChip(
                    'Ưu tiên vệ sinh',
                    _personalValue == 'CLEAN',
                    () => setState(() => _personalValue = 'CLEAN'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _penpotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _penpotSectionLabel('Sở thích', icon: Icons.interests_outlined),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _interestOptions.map((item) {
                  final name = item['name'] as String;
                  final selected = _selectedInterests.contains(name);
                  return _choiceChip(
                    name,
                    selected,
                    () => setState(() {
                      if (selected) {
                        _selectedInterests.remove(name);
                      } else {
                        _selectedInterests.add(name);
                      }
                    }),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        _penpotContinueButton(),
      ],
    );
  }

  Widget _buildPenpotSummaryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bạn có thể thay đổi tiêu chí bất cứ lúc nào\ntrong mục Hồ sơ.',
          style: TextStyle(color: _penpotMuted, height: 1.35),
        ),
        const SizedBox(height: 18),
        _summaryCard(
          'Ngân sách & khu vực',
          '${fmt.format(_budgetRange.start)} – ${fmt.format(_budgetRange.end)} / tháng · ${_districtDisplay(_district)}',
          Icons.location_on_outlined,
        ),
        _summaryCard(
          'Lối sống',
          '${_sleepHabit == 1
              ? 'Dậy sớm'
              : _sleepHabit == 3
              ? 'Cú đêm'
              : 'Linh hoạt'} · ${_cookingHabit == 'COOK_HOME'
              ? 'Tự nấu'
              : _cookingHabit == 'EAT_OUT'
              ? 'Ăn ngoài'
              : 'Linh hoạt'} · ${_cleanliness.toInt() >= 4 ? 'Gọn gàng' : 'Linh hoạt'}',
          Icons.schedule_outlined,
        ),
        _summaryCard(
          'Tính cách & sở thích',
          '${_personality == 'AMBIVERT' ? 'Linh hoạt' : _personalityLabel(_personality)} · ${_selectedInterests.take(3).join(' · ')}',
          Icons.interests_outlined,
        ),
        _summaryCard(
          'Ưu tiên',
          _topPriority == 'CLEAN'
              ? 'Ưu tiên vệ sinh · Ưu tiên khu vực'
              : _topPriorityLabel(_topPriority),
          Icons.star_border_rounded,
        ),
        _penpotContinueButton(
          label: 'Lưu tiêu chí & khám phá',
          onPressed: _isSaving ? null : _save,
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _penpotCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _penpotSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _penpotPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _penpotMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: _penpotInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _penpotSoft : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _penpotPrimary : const Color(0xFFD6E2DE),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _penpotPrimary : _penpotInk,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BƯỚC 1: NGÂN SÁCH & KHU VỰC (UC-07)
  // ==========================================
  // Legacy Stepper builders are retained so older test fixtures and deep links
  // can still be migrated without losing the original field implementation.
  // ignore: unused_element
  Widget _buildStep1BudgetDistrict() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.indigo.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.payments_outlined, color: Colors.indigo, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Khoảng ngân sách dự kiến hàng tháng:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${fmt.format(_budgetRange.start)} - ${fmt.format(_budgetRange.end)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _budgetRange,
          min: 1000000,
          max: 15000000,
          divisions: 28, // Bước nhảy 500.000 VNĐ từ 1M đến 15M
          activeColor: Colors.indigo,
          inactiveColor: Colors.indigo.shade100,
          labels: RangeLabels(
            fmt.format(_budgetRange.start),
            fmt.format(_budgetRange.end),
          ),
          onChanged: (RangeValues val) {
            setState(() {
              if (val.start < val.end) {
                _budgetRange = val;
              }
            });
          },
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1.000.000 đ',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '15.000.000 đ',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Chọn nhanh khoảng giá phổ biến:',
          style: TextStyle(fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildBudgetQuickChip('1.5M - 3M', 1500000, 3000000),
            _buildBudgetQuickChip('2M - 4.5M', 2000000, 4500000),
            _buildBudgetQuickChip('3M - 6M', 3000000, 6000000),
            _buildBudgetQuickChip('5M - 10M', 5000000, 10000000),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.location_city_outlined, color: Colors.indigo, size: 20),
            SizedBox(width: 8),
            Text(
              'Quận / Huyện mong muốn (TP. Hồ Chí Minh):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _districtMap.containsKey(_district)
              ? _district
              : 'Thu Duc',
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            prefixIcon: Icon(Icons.place_outlined),
          ),
          items: _districtMap.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _district = val);
          },
        ),
        const SizedBox(height: 10),
        const Text(
          'Khu vực tập trung đông sinh viên:',
          style: TextStyle(fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children:
              [
                'Thu Duc',
                'Binh Thanh',
                'Quan 10',
                'Go Vap',
                'Quan 1',
                'Quan 7',
              ].map((key) {
                final isSelected = _district == key;
                return ChoiceChip(
                  label: Text(_districtMap[key] ?? key),
                  selected: isSelected,
                  selectedColor: Colors.indigo.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.indigo.shade900 : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _district = key);
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        // Yêu cầu về Giới tính bạn cùng phòng (UC-07, FR-07)
        const Row(
          children: [
            Icon(Icons.wc_outlined, color: Colors.indigo, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Yêu cầu giới tính bạn cùng phòng (Hard Filter):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'ANY',
                label: Text('Bất kỳ', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.people_outline, size: 18),
              ),
              ButtonSegment<String>(
                value: 'MALE',
                label: Text('Nam', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.male, size: 18),
              ),
              ButtonSegment<String>(
                value: 'FEMALE',
                label: Text('Nữ', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.female, size: 18),
              ),
            ],
            selected: {_targetGender},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _targetGender = newSelection.first);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetQuickChip(String label, double start, double end) {
    final isSelected = (_budgetRange.start == start && _budgetRange.end == end);
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected
          ? Colors.indigo.shade100
          : Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.indigo.shade900 : Colors.black87,
      ),
      onPressed: () {
        setState(() {
          _budgetRange = RangeValues(start, end);
        });
      },
    );
  }

  // ==========================================
  // BƯỚC 2: LỐI SỐNG SINH HOẠT (UC-08)
  // ==========================================
  // ignore: unused_element
  Widget _buildStep2Lifestyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.bedtime_outlined, color: Colors.indigo, size: 20),
            SizedBox(width: 8),
            Text(
              'Thói quen giờ giấc ngủ nghỉ:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(
                value: 1,
                label: Text(
                  'Dậy sớm (Early Bird)',
                  style: TextStyle(fontSize: 12),
                ),
                icon: Icon(Icons.wb_sunny_outlined, size: 18),
              ),
              ButtonSegment<int>(
                value: 2,
                label: Text('Linh hoạt', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.schedule_outlined, size: 18),
              ),
              ButtonSegment<int>(
                value: 3,
                label: Text(
                  'Cú đêm (Night Owl)',
                  style: TextStyle(fontSize: 12),
                ),
                icon: Icon(Icons.nightlight_round_outlined, size: 18),
              ),
            ],
            selected: {_sleepHabit},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() => _sleepHabit = newSelection.first);
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _sleepHabit == 1
              ? 'Thường đi ngủ trước 23h và thức dậy sớm trước 6h30 sáng.'
              : _sleepHabit == 3
              ? 'Thường thức khuya sau 1h sáng, học tập hoặc làm việc về đêm.'
              : 'Giờ giấc linh hoạt theo lịch học và làm việc trong tuần.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.restaurant_outlined, color: Colors.indigo, size: 20),
            SizedBox(width: 8),
            Text(
              'Thói quen ăn uống & Nấu nướng:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'COOK_HOME',
                label: Text('Tự nấu ở nhà', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.soup_kitchen_outlined, size: 18),
              ),
              ButtonSegment<String>(
                value: 'EAT_OUT',
                label: Text(
                  'Ăn ngoài / Tiện lợi',
                  style: TextStyle(fontSize: 12),
                ),
                icon: Icon(Icons.fastfood_outlined, size: 18),
              ),
              ButtonSegment<String>(
                value: 'FLEXIBLE',
                label: Text('Linh hoạt', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.restaurant_menu_outlined, size: 18),
              ),
            ],
            selected: {_cookingHabit},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _cookingHabit = newSelection.first);
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _cookingHabit == 'COOK_HOME'
              ? 'Thường xuyên đi chợ và chuẩn bị bữa ăn tại phòng trọ.'
              : _cookingHabit == 'EAT_OUT'
              ? 'Ưu tiên ăn ngoài, quán cơm bình dân hoặc đặt đồ ăn trực tuyến.'
              : 'Thỉnh thoảng nấu ăn cuối tuần, trong tuần ăn ngoài tiện lợi.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BƯỚC 3: THÓI QUEN CÁ NHÂN (UC-08)
  // ==========================================
  // ignore: unused_element
  Widget _buildStep3PersonalHabits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.cleaning_services_outlined,
                  color: Colors.indigo,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Mức độ sạch sẽ / ngăn nắp:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_cleanliness.toInt()} / 5 sao',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final starNum = index + 1;
              final isFilled = starNum <= _cleanliness;
              return IconButton(
                iconSize: 38,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                icon: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFilled ? Colors.amber : Colors.grey.shade400,
                ),
                onPressed: () {
                  setState(() => _cleanliness = starNum.toDouble());
                },
              );
            }),
          ),
        ),
        Center(
          child: Text(
            _cleanliness == 1
                ? 'Thoải mái, ít khi dọn dẹp thường xuyên'
                : _cleanliness == 2
                ? 'Mức trung bình, dọn dẹp khi cảm thấy cần thiết'
                : _cleanliness == 3
                ? 'Gọn gàng, có lịch dọn phòng định kỳ trong tuần'
                : _cleanliness == 4
                ? 'Rất sạch sẽ, lau chùi và giữ không gian luôn tinh tươm'
                : 'Cực kỳ ngăn nắp & sạch sẽ tuyệt đối, đồ vật luôn đúng chỗ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SwitchListTile(
            secondary: Icon(
              _isSmoking ? Icons.smoking_rooms : Icons.smoke_free,
              color: _isSmoking ? Colors.deepOrange : Colors.green,
            ),
            title: const Text('Thói quen hút thuốc (Thuốc lá / Vape)'),
            subtitle: Text(
              _isSmoking
                  ? 'Có hút thuốc (Cần phòng trọ có ban công/khu vực riêng)'
                  : 'Không hút thuốc (Môi trường trong lành, không khói)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            value: _isSmoking,
            activeThumbColor: Colors.indigo,
            onChanged: (val) => setState(() => _isSmoking = val),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(Icons.pets_outlined, color: Colors.indigo, size: 20),
            SizedBox(width: 8),
            Text(
              'Thú cưng (Chó, Mèo...):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'LOVE_PETS',
                label: Text('Thích / Nuôi', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.pets, size: 18),
              ),
              ButtonSegment<String>(
                value: 'ALLERGIC',
                label: Text('Dị ứng lông', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.warning_amber_rounded, size: 18),
              ),
              ButtonSegment<String>(
                value: 'NO_PETS',
                label: Text('Không nuôi', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.block, size: 18),
              ),
            ],
            selected: {_petHabit},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _petHabit = newSelection.first;
                _allowPets = (_petHabit == 'LOVE_PETS');
              });
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BƯỚC 4: TÍNH CÁCH, SỞ THÍCH & KẾ HOẠCH (UC-08, UC-25, UC-42)
  // ==========================================
  // ignore: unused_element
  Widget _buildStep4PersonalityInterests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.psychology_outlined, color: Colors.indigo, size: 20),
            SizedBox(width: 8),
            Text(
              'Xu hướng tính cách:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'INTROVERT',
                label: Text('Hướng nội', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.self_improvement, size: 18),
              ),
              ButtonSegment<String>(
                value: 'AMBIVERT',
                label: Text('Linh hoạt', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.swap_horiz, size: 18),
              ),
              ButtonSegment<String>(
                value: 'EXTROVERT',
                label: Text('Hướng ngoại', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.groups, size: 18),
              ),
            ],
            selected: {_personality},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _personality = newSelection.first);
            },
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.interests_outlined, color: Colors.indigo, size: 20),
                SizedBox(width: 8),
                Text(
                  'Sở thích cá nhân (chọn nhiều):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            Text(
              'Đã chọn ${_selectedInterests.length}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.indigo.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interestOptions.map((opt) {
            final name = opt['name'] as String;
            final icon = opt['icon'] as IconData;
            final isSelected = _selectedInterests.contains(name);

            return FilterChip(
              avatar: Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.indigo,
              ),
              label: Text(name),
              selected: isSelected,
              selectedColor: Colors.indigo,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedInterests.add(name);
                  } else {
                    _selectedInterests.remove(name);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // UC-42: Kế hoạch thời gian dọn vào ở
        const Row(
          children: [
            Icon(
              Icons.event_available_outlined,
              color: Colors.indigo,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Dự kiến thời gian dọn vào ở (UC-42):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'ASAP',
                label: Text('Dọn vào ngay', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment<String>(
                value: 'TWO_WEEKS',
                label: Text('Trong 1-2 tuần', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment<String>(
                value: 'NEXT_MONTH',
                label: Text('Đầu tháng tới', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment<String>(
                value: 'FLEXIBLE',
                label: Text('Linh hoạt', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {_moveInTime},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _moveInTime = newSelection.first);
            },
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // FR-25: Tiêu chí ưu tiên số 1 (Dynamic Weighting)
        const Row(
          children: [
            Icon(Icons.star_half_outlined, color: Colors.indigo, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tiêu chí bạn ưu tiên số 1 (Trọng số động FR-25):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _topPriority,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: const [
            DropdownMenuItem(
              value: 'BUDGET',
              child: Text('Ngân sách phù hợp (Hệ số x 2.0)'),
            ),
            DropdownMenuItem(
              value: 'SLEEP',
              child: Text('Giờ giấc ngủ nghỉ tương đồng (Hệ số x 2.0)'),
            ),
            DropdownMenuItem(
              value: 'CLEAN',
              child: Text('Mức độ sạch sẽ ngăn nắp (Hệ số x 2.0)'),
            ),
            DropdownMenuItem(
              value: 'SMOKING',
              child: Text('Tuyệt đối không khói thuốc (Knock-out)'),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _topPriority = val);
          },
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        const Row(
          children: [
            Icon(Icons.edit_note, color: Colors.indigo, size: 22),
            SizedBox(width: 8),
            Text(
              'Mô tả bản thân & Yêu cầu bạn trọ:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText:
                'Ví dụ: Sinh viên năm 3 IT, tìm bạn ghép phòng sạch sẽ, hòa đồng, không ồn ào giờ khuya...',
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BƯỚC 5: TỔNG QUAN & XÁC NHẬN (QLTC_BM1)
  // ==========================================
  // ignore: unused_element
  Widget _buildStep5OverviewSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.indigo.shade100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.indigo,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tóm Tắt Hồ Sơ Tiêu Chí 5 Chiều',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Đối chiếu chuẩn theo biểu mẫu QLTC_BM1',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // 1. Tiêu chí cứng (Ngân sách & Khu vực & Giới tính)
                _buildSummaryRow(
                  icon: Icons.place_outlined,
                  title: 'Khu vực & Ngân sách:',
                  content:
                      '${_districtDisplay(_district)} • ${fmt.format(_budgetRange.start)} - ${fmt.format(_budgetRange.end)} (Yêu cầu giới tính: ${_targetGenderLabel(_targetGender)})',
                ),
                const SizedBox(height: 12),

                // 2. Lối sống
                _buildSummaryRow(
                  icon: Icons.nightlife_outlined,
                  title: 'Lối sống sinh hoạt:',
                  content:
                      '${_sleepHabitLabel(_sleepHabit)} • ${_cookingHabitLabel(_cookingHabit)}',
                ),
                const SizedBox(height: 12),

                // 3. Thói quen
                _buildSummaryRow(
                  icon: Icons.clean_hands_outlined,
                  title: 'Thói quen cá nhân:',
                  content:
                      'Sạch sẽ: ${_cleanliness.toInt()}/5★ • ${_isSmoking ? "Có hút thuốc" : "Không hút thuốc"} • ${_petHabitLabel(_petHabit)}',
                ),
                const SizedBox(height: 12),

                // 4. Tính cách & Sở thích
                _buildSummaryRow(
                  icon: Icons.psychology_outlined,
                  title: 'Tính cách & Sở thích:',
                  content:
                      '${_personalityLabel(_personality)}${_selectedInterests.isNotEmpty ? " • ${_selectedInterests.join(', ')}" : ""}',
                ),
                const SizedBox(height: 12),

                // 5. Kế hoạch & Ưu tiên
                _buildSummaryRow(
                  icon: Icons.event_available_outlined,
                  title: 'Kế hoạch & Ưu tiên:',
                  content:
                      'Dọn vào: ${_moveInTimeLabel(_moveInTime)} • Ưu tiên số 1: ${_topPriorityLabel(_topPriority)}',
                ),
                const SizedBox(height: 12),

                // 6. Ghi chú
                _buildSummaryRow(
                  icon: Icons.notes_outlined,
                  title: 'Mô tả bản thân:',
                  content: _bioCtrl.text.trim().isNotEmpty
                      ? _bioCtrl.text.trim()
                      : '(Chưa nhập lời nhắn bổ sung)',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Khi bấm Lưu, hệ thống sẽ tự động tính toán lại mức độ tương thích (%) với các ứng viên cùng khu vực theo công thức trọng số đa tiêu chí!',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.indigo),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: content),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
