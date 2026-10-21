import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/room_amenities.dart';

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
    RoomAmenities.parking: false,
    'Giờ giấc tự do': false,
  };
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _selectedImagesBytes = [];
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
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ được tải lên tối đa 4 ảnh cho mỗi phòng.')),
      );
      return;
    }
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
      _selectedImages.add(image);
      _selectedImagesBytes.add(bytes);
    });
  }

  void _removeRoomImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _selectedImagesBytes.removeAt(index);
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
      final List<String> imageObjectKeys = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        final bytes = _selectedImagesBytes[i];
        final upload = await _api.uploadImage(
          bytes: bytes,
          fileName: image.name,
          contentType: _contentType(image.name),
          purpose: 'room-post',
        );
        imageObjectKeys.add(upload.objectKey);
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
        'imageObjectKeys': imageObjectKeys,
        'imageObjectKey': imageObjectKeys.isNotEmpty ? imageObjectKeys.first : null,
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
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề bài đăng',
                      hintText: 'Ví dụ: Tìm 1 bạn nam ở ghép phòng gần ĐH SPKT',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tiêu đề';
                      if (v.trim().length > 200) return 'Tiêu đề tối đa 200 ký tự';
                      return null;
                    },
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hình ảnh phòng trọ (${_selectedImages.length}/4)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_selectedImages.length < 4)
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _pickRoomImage,
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                          label: const Text('Thêm ảnh'),
                        ),
                    ],
                  ),
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _selectedImagesBytes[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: _isLoading ? null : () => _removeRoomImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: index == 0 ? Colors.indigo : Colors.black45,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  index == 0 ? 'Ảnh bìa' : 'Ảnh ${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
