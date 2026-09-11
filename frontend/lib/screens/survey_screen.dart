import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class SurveyScreen extends StatefulWidget {
  final int userId;
  const SurveyScreen({super.key, required this.userId});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final ApiService _api = ApiService();
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  bool _isLoading = true;
  String _district = 'Thu Duc';
  double _budget = 2000000;
  int _sleepHabit = 1; // 1: Ngủ sớm, 2: Bình thường, 3: Cú đêm
  double _cleanliness = 4.0; // 1 -> 5
  bool _isSmoking = false;
  bool _allowPets = false;
  final _bioCtrl = TextEditingController();

  final List<String> _districts = [
    'Thu Duc',
    'Quan 1',
    'Quan 3',
    'Quan 5',
    'Quan 10',
    'Binh Thanh',
    'Go Vap',
    'Phu Nhuan',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final data = await _api.getPreferences(widget.userId);
      if (data != null) {
        setState(() {
          if (_districts.contains(data['targetDistrict'])) {
            _district = data['targetDistrict'];
          }
          _budget = (data['budgetAmount'] as num).toDouble();
          _sleepHabit = data['sleepHabit'] as int;
          _cleanliness = (data['cleanlinessLevel'] as num).toDouble();
          _isSmoking = data['isSmoking'] as bool;
          _allowPets = data['allowPets'] as bool;
          _bioCtrl.text = data['bioDescription'] ?? '';
        });
      }
    } catch (_) {
      // Dùng giá trị mặc định nếu người dùng mới chưa có tiêu chí
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final payload = {
      'targetDistrict': _district,
      'budgetAmount': _budget,
      'sleepHabit': _sleepHabit,
      'cleanlinessLevel': _cleanliness.toInt(),
      'isSmoking': _isSmoking,
      'allowPets': _allowPets,
      'bioDescription': _bioCtrl.text.trim(),
    };

    final ok = await _api.savePreferences(widget.userId, payload);
    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật tiêu chí thành công! Hệ thống đã tính toán lại gợi ý.')),
        );
        Navigator.pop(context, true); // Trả về true để HomeScreen reload gợi ý
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu tiêu chí thất bại!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khảo Sát Tiêu Chí Bạn Trọ'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. KHU VỰC
                const Text('Khu vực mong muốn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _district,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _districts
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) => setState(() => _district = val!),
                ),
                const SizedBox(height: 18),

                // 2. NGÂN SÁCH (SLIDER)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ngân sách dự kiến:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(fmt.format(_budget), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16)),
                  ],
                ),
                Slider(
                  value: _budget,
                  min: 1000000,
                  max: 8000000,
                  divisions: 14,
                  label: fmt.format(_budget),
                  onChanged: (val) => setState(() => _budget = val),
                ),
                const SizedBox(height: 14),

                // 3. GIỜ GIẤC SINH HOẠT
                const Text('Giờ giấc sinh hoạt:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                RadioGroup<int>(
                  groupValue: _sleepHabit,
                  onChanged: (val) {
                    if (val != null) setState(() => _sleepHabit = val);
                  },
                  child: const Row(
                    children: [
                      Expanded(
                        child: RadioListTile<int>(
                          title: Text('Ngủ sớm', style: TextStyle(fontSize: 13)),
                          value: 1,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                          title: Text('Bình thường', style: TextStyle(fontSize: 13)),
                          value: 2,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                          title: Text('Cú đêm', style: TextStyle(fontSize: 13)),
                          value: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. MỨC ĐỘ SẠCH SẼ (1 - 5)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mức độ sạch sẽ (1 - 5):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('${_cleanliness.toInt()} / 5', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Slider(
                  value: _cleanliness,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '${_cleanliness.toInt()}',
                  onChanged: (val) => setState(() => _cleanliness = val),
                ),
                const SizedBox(height: 14),

                // 5. THÓI QUEN HÚT THUỐC & THÚ CƯNG
                SwitchListTile(
                  title: const Text('Có hút thuốc?'),
                  value: _isSmoking,
                  onChanged: (val) => setState(() => _isSmoking = val),
                ),
                SwitchListTile(
                  title: const Text('Cho phép / Nuôi thú cưng?'),
                  value: _allowPets,
                  onChanged: (val) => setState(() => _allowPets = val),
                ),
                const SizedBox(height: 14),

                // 6. GIỚI THIỆU BẢN THÂN
                const Text('Mô tả bản thân & yêu cầu thêm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                TextField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ví dụ: Sinh viên năm cuối, cần tìm bạn ít ồn ào để tập trung làm đồ án...',
                  ),
                ),
                const SizedBox(height: 24),

                // NÚT LƯU
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('LƯU VÀ TÍNH TOÁN LẠI GỢI Ý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}