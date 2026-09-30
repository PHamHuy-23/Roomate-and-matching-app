import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

  final _titleCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _electricityWaterCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _maxOccupantsCtrl = TextEditingController(text: '2');
  final _currentOccupantsCtrl = TextEditingController(text: '0');
  final _descCtrl = TextEditingController();
  final Map<String, bool> _amenities = {
    'Wifi': false,
    'Máy lạnh': false,
    'Nước nóng': false,
    'Máy giặt': false,
    'Chỗ để xe': false,
    'Giờ giấc tự do': false,
  };
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  double? _parseMoney(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }

  double? _parseOptionalNumber(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickRoomImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ảnh phải nhỏ hơn hoặc bằng 5 MB')),
      );
      return;
    }
    setState(() {
      _selectedImage = image;
      _selectedImageBytes = bytes;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _districtCtrl.dispose();
    _priceCtrl.dispose();
    _depositCtrl.dispose();
    _electricityWaterCtrl.dispose();
    _areaCtrl.dispose();
    _maxOccupantsCtrl.dispose();
    _currentOccupantsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final maxOccupants = int.parse(_maxOccupantsCtrl.text.trim());
      final currentOccupants = int.parse(_currentOccupantsCtrl.text.trim());
      if (currentOccupants > maxOccupants) {
        throw const ApiException(
          'Số người hiện tại không được lớn hơn số người tối đa',
        );
      }
      String? imageObjectKey;
      final image = _selectedImage;
      final imageBytes = _selectedImageBytes;
      if (image != null && imageBytes != null) {
        final upload = await _api.uploadImage(
          bytes: imageBytes,
          fileName: image.name,
          contentType: _contentType(image.name),
          purpose: 'room-post',
        );
        imageObjectKey = upload.objectKey;
      }
      final payload = {
        'title': _titleCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'price': _parseMoney(_priceCtrl.text)!,
        'deposit': _parseMoney(_depositCtrl.text),
        'electricityWaterCost': _parseMoney(_electricityWaterCtrl.text),
        'area': _parseOptionalNumber(_areaCtrl.text),
        'maxOccupants': maxOccupants,
        'currentOccupants': currentOccupants,
        'amenities': _amenities.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .join(','),
        'imageObjectKey': imageObjectKey,
        'description': _descCtrl.text.trim(),
      };

      final ok = await _api.createRoomPost(payload);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng tin tìm bạn ở ghép thành công!'),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng tin thất bại, vui lòng kiểm tra lại!'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Tin Tìm Bạn Ở Ghép'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            padding: const EdgeInsets.all(24),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề bài đăng',
                      hintText: 'Ví dụ: Tìm 1 bạn nam ở ghép phòng gần ĐH SPKT',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Vui lòng nhập tiêu đề'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ phòng trọ',
                      hintText: 'Ví dụ: Đường Võ Văn Ngân, TP. Thủ Đức',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Vui lòng nhập địa chỉ'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _districtCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Quận/Huyện',
                      hintText: 'Ví dụ: Thủ Đức',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Vui lòng nhập quận/huyện'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Giá thuê (VNĐ/tháng)',
                            hintText: '1800000',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Nhập giá phòng';
                            }
                            if (_parseMoney(v) == null) {
                              return 'Giá không hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _maxOccupantsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tối đa (người)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.group),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Nhập số người';
                            }
                            final value = int.tryParse(v.trim());
                            if (value == null || value < 1) {
                              return 'Số không hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _currentOccupantsCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Đang ở (người)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) {
                            final value = int.tryParse(v?.trim() ?? '');
                            return value == null || value < 0
                                ? 'Số không hợp lệ'
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _areaCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Diện tích (m²)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.square_foot),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final value = _parseOptionalNumber(v);
                            return value == null || value <= 0
                                ? 'Diện tích không hợp lệ'
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _depositCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Tiền cọc',
                            border: OutlineInputBorder(),
                            suffixText: 'đ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _electricityWaterCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Điện/nước',
                            border: OutlineInputBorder(),
                            suffixText: 'đ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tiện ích',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _amenities.entries.map((entry) {
                      return FilterChip(
                        label: Text(entry.key),
                        selected: entry.value,
                        onSelected: (selected) {
                          setState(() => _amenities[entry.key] = selected);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickRoomImage,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      _selectedImageBytes == null
                          ? 'Chọn ảnh phòng'
                          : 'Đổi ảnh phòng',
                    ),
                  ),
                  if (_selectedImageBytes != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _selectedImageBytes!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                              _selectedImage = null;
                              _selectedImageBytes = null;
                            }),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Bỏ ảnh'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả chi tiết phòng trọ',
                      hintText:
                          'Mô tả diện tích, nội thất (máy lạnh, tủ lạnh, gác lửng), chi phí điện nước...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Vui lòng nhập mô tả'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ĐĂNG BÀI NGAY',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
