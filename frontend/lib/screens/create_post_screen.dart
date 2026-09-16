import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class CreatePostScreen extends StatefulWidget {
  final int authorId;
  const CreatePostScreen({super.key, required this.authorId});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final _priceFormatter = NumberFormat('#,###', 'vi_VN');

  // Controllers
  final _titleCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _electricWaterCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _maxOccupantsCtrl = TextEditingController(text: '2');
  final _currentOccupantsCtrl = TextEditingController(text: '1');
  final _descCtrl = TextEditingController();

  bool _isLoading = false;

  // Dropdown Quận/Huyện
  String? _selectedDistrict;
  static const List<String> _districts = [
    'Quận 1',
    'Quận 3',
    'Quận 4',
    'Quận 5',
    'Quận 6',
    'Quận 7',
    'Quận 8',
    'Quận 9',
    'Quận 10',
    'Quận 11',
    'Quận 12',
    'Bình Thạnh',
    'TP. Thủ Đức',
    'Gò Vấp',
    'Tân Bình',
    'Tân Phú',
    'Phú Nhuận',
    'Bình Tân',
    'Nhà Bè',
    'Hóc Môn',
    'Củ Chi',
  ];

  // Tiện ích (Amenities) - chọn nhiều dạng Chip
  final Map<String, bool> _amenities = {
    'Wifi': false,
    'Máy lạnh': false,
    'Nước nóng': false,
    'Máy giặt': false,
    'Giữ xe': false,
    'Giờ tự do': false,
  };

  static const Map<String, String> _amenityEmojis = {
    'Wifi': '📶',
    'Máy lạnh': '❄️',
    'Nước nóng': '🚿',
    'Máy giặt': '🧺',
    'Giữ xe': '🛵',
    'Giờ tự do': '🔑',
  };

  /// Xử lý format giá tự động thêm dấu chấm phân cách hàng nghìn
  String _formatPrice(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    final number = int.tryParse(digits);
    if (number == null) return digits;
    return _priceFormatter.format(number);
  }

  /// Parse giá từ chuỗi có format thành số
  double? _parsePrice(String formatted) {
    final digits = formatted.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Quận/Huyện')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Lấy danh sách tiện ích đã chọn
      final selectedAmenities = _amenities.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      // Ghép địa chỉ đầy đủ: số nhà, đường + Quận
      final fullAddress = '${_addressCtrl.text.trim()}, $_selectedDistrict';

      final maxOcc = int.tryParse(_maxOccupantsCtrl.text.trim()) ?? 1;
      final curOcc = int.tryParse(_currentOccupantsCtrl.text.trim()) ?? 0;

      if (curOcc > maxOcc) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Số người hiện tại không được vượt quá số người tối đa!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final payload = {
        'authorId': widget.authorId,
        'title': _titleCtrl.text.trim(),
        'address': fullAddress,
        'district': _selectedDistrict,
        'price': _parsePrice(_priceCtrl.text),
        'deposit': _parsePrice(_depositCtrl.text),
        'electricityWaterCost': _parsePrice(_electricWaterCtrl.text),
        'area': double.tryParse(_areaCtrl.text.trim()),
        'maxOccupants': maxOcc,
        'currentOccupants': curOcc,
        'description': _descCtrl.text.trim(),
        'amenities': selectedAmenities.join(','),
      };

      final ok = await _api.createRoomPost(payload);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Đăng tin tìm bạn ở ghép thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng tin thất bại, vui lòng kiểm tra lại!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _depositCtrl.dispose();
    _electricWaterCtrl.dispose();
    _areaCtrl.dispose();
    _maxOccupantsCtrl.dispose();
    _currentOccupantsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng tin tìm bạn ở ghép / Cho thuê phòng'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ======= PHẦN 1: THÔNG TIN CƠ BẢN =======
                  _buildSectionCard(
                    title: '📝 Thông tin cơ bản',
                    children: [
                      // Tiêu đề bài đăng
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề bài đăng *',
                          hintText: 'VD: Tìm 1 bạn nam ở ghép phòng gần ĐH Sư Phạm Kỹ Thuật',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tiêu đề';
                          if (v.trim().length < 10) return 'Tiêu đề phải tối thiểu 10 ký tự';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Mô tả chi tiết
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả chi tiết phòng trọ *',
                          hintText: 'Mô tả diện tích, nội thất (máy lạnh, tủ lạnh, gác lửng), chi phí điện nước, ưu điểm khu vực...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Vui lòng nhập mô tả'
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ======= PHẦN 2: ĐỊA CHỈ =======
                  _buildSectionCard(
                    title: '📍 Địa chỉ phòng trọ',
                    children: [
                      // Dropdown Quận/Huyện
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: const InputDecoration(
                          labelText: 'Quận / Huyện *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        items: _districts.map((d) {
                          return DropdownMenuItem(value: d, child: Text(d));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedDistrict = val),
                        validator: (v) => v == null ? 'Vui lòng chọn Quận/Huyện' : null,
                      ),
                      const SizedBox(height: 14),

                      // Địa chỉ cụ thể (Số nhà, tên đường)
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Số nhà, tên đường *',
                          hintText: 'VD: 123 Đường Võ Văn Ngân',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Vui lòng nhập địa chỉ cụ thể'
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ======= PHẦN 3: CHI PHÍ =======
                  _buildSectionCard(
                    title: '💰 Chi phí',
                    children: [
                      // Giá thuê / tháng
                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Giá thuê phòng (VNĐ/tháng) *',
                          hintText: '3500000',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          suffixText: 'đ/tháng',
                        ),
                        onChanged: (val) {
                          final formatted = _formatPrice(val);
                          if (formatted != val) {
                            _priceCtrl.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Nhập giá phòng';
                          if (_parsePrice(v) == null) return 'Giá không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          // Tiền cọc
                          Expanded(
                            child: TextFormField(
                              controller: _depositCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(
                                labelText: 'Tiền cọc (VNĐ)',
                                hintText: '1000000',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                              ),
                              onChanged: (val) {
                                final formatted = _formatPrice(val);
                                if (formatted != val) {
                                  _depositCtrl.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(offset: formatted.length),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Tiền điện nước
                          Expanded(
                            child: TextFormField(
                              controller: _electricWaterCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(
                                labelText: 'Điện/Nước (VNĐ)',
                                hintText: '300000',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.bolt),
                              ),
                              onChanged: (val) {
                                final formatted = _formatPrice(val);
                                if (formatted != val) {
                                  _electricWaterCtrl.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(offset: formatted.length),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ======= PHẦN 4: PHÒNG =======
                  _buildSectionCard(
                    title: '🏠 Thông tin phòng',
                    children: [
                      Row(
                        children: [
                          // Diện tích
                          Expanded(
                            child: TextFormField(
                              controller: _areaCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Diện tích (m²)',
                                hintText: '25',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.square_foot),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Tối đa (người)
                          Expanded(
                            child: TextFormField(
                              controller: _maxOccupantsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Tối đa (người) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.group),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Nhập số người';
                                if (int.tryParse(v.trim()) == null) return 'Số không hợp lệ';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Số người hiện tại
                          Expanded(
                            child: TextFormField(
                              controller: _currentOccupantsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Hiện tại (người)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (v) {
                                if (v != null && v.trim().isNotEmpty) {
                                  final n = int.tryParse(v.trim());
                                  if (n == null || n < 0) return 'Số không hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ======= PHẦN 5: TIỆN ÍCH =======
                  _buildSectionCard(
                    title: '✨ Tiện ích có sẵn',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _amenities.entries.map((entry) {
                          final emoji = _amenityEmojis[entry.key] ?? '🔹';
                          return FilterChip(
                            label: Text('$emoji ${entry.key}'),
                            selected: entry.value,
                            selectedColor: Colors.indigo.shade100,
                            checkmarkColor: Colors.indigo,
                            onSelected: (selected) {
                              setState(() => _amenities[entry.key] = selected);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ======= NÚT ĐĂNG BÀI =======
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitPost,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.publish),
                      label: Text(
                        _isLoading ? 'ĐANG ĐĂNG...' : 'ĐĂNG BÀI NGAY',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget phụ: Tạo section Card có title
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}