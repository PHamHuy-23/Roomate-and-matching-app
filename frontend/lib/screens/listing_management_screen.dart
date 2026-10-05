import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../models/room_post.dart';
import '../models/room_amenities.dart';
import '../models/viewing_appointment.dart';
import '../services/api_service.dart';
import '../widgets/penpot_back_button.dart';

enum ListingFlowMode {
  myListings,
  create,
  photosAmenities,
  priceRules,
  preview,
  submitted,
  edit,
  viewingRequest,
  reportReceived,
  confirmedViewing,
  close,
  closed,
}

class ListingManagementScreen extends StatefulWidget {
  const ListingManagementScreen({
    required this.mode,
    required this.authorId,
    this.posts = const [],
    this.apiService,
    this.initialPostId,
    super.key,
  });

  final ListingFlowMode mode;
  final int authorId;
  final List<RoomPost> posts;
  final ApiService? apiService;
  final int? initialPostId;

  @override
  State<ListingManagementScreen> createState() =>
      _ListingManagementScreenState();
}

class _ListingManagementScreenState extends State<ListingManagementScreen> {
  ApiService get _api => widget.apiService ?? ApiService();

  static const _canvas = Color(0xFFF5F8F7);

  static const _primary = Color(0xFF087E6B);
  static const _ink = Color(0xFF142523);
  static const _muted = Color(0xFF65746F);
  static const _soft = Color(0xFFE8F4F1);
  static const _border = Color(0xFFDCE6E3);
  static const _amenityOptions = <String>[
    'Máy lạnh',
    'Bếp riêng',
    RoomAmenities.parking,
    'Wi-Fi',
    'Nội thất',
    'Máy giặt',
  ];

  late ListingFlowMode _mode;
  final List<ListingFlowMode> _history = <ListingFlowMode>[];
  late bool _editingExisting;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _depositCtrl;
  late final TextEditingController _utilityCtrl;
  late final TextEditingController _descriptionCtrl;
  final _areaCtrl = TextEditingController();
  double get _area =>
      double.tryParse(_areaCtrl.text.trim().replaceAll(',', '.')) ?? double.nan;
  int _maxOccupants = 2;
  String? _imageObjectKey;
  String? _imageUrl;
  bool _busy = false;
  String? _loadError;
  bool _loadingData = false;
  final Set<String> _amenities = {};
  RoomPost? _selectedPost;
  ViewingAppointment? _selectedAppointment;
  List<RoomPost> _myPosts = [];
  List<ViewingAppointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _editingExisting = widget.mode == ListingFlowMode.edit;
    _myPosts = widget.posts
        .where((post) => post.authorId == widget.authorId)
        .toList();
    final post = _myPosts.isEmpty ? null : _myPosts.first;
    _titleCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _districtCtrl = TextEditingController();
    _priceCtrl = TextEditingController();
    _depositCtrl = TextEditingController(text: '0');
    _utilityCtrl = TextEditingController(text: '0');
    _descriptionCtrl = TextEditingController();
    if (_editingExisting && post != null) _selectPost(post);
    _loadData();
  }

  Future<void> _loadData() async {
    if (_loadingData) return;
    if (!_api.hasAuthToken) return;
    setState(() {
      _loadingData = true;
      _loadError = null;
    });
    try {
      final postsFuture = _api.getMyPosts();
      final aptsFuture = _api.getMyAppointments();
      final results = await Future.wait([postsFuture, aptsFuture]);
      if (mounted) {
        setState(() {
          final fetchedPosts = results[0] as List<RoomPost>;
          _myPosts = fetchedPosts
              .where((post) => post.authorId == widget.authorId)
              .toList();
          _loadError = null;
          _appointments = results[1] as List<ViewingAppointment>;
          if (_selectedPost == null && widget.initialPostId != null) {
            final selected = _myPosts.where(
              (post) => post.id == widget.initialPostId,
            );
            if (selected.isNotEmpty) {
              _selectPost(selected.first);
            } else {
              _loadError = 'Không tìm thấy tin đăng của bạn cho lịch hẹn này.';
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = 'Không thể tải dữ liệu: $e');
    } finally {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  void _selectPost(RoomPost post) {
    _selectedPost = post;
    _titleCtrl.text = post.title;
    _addressCtrl.text = post.address;
    _districtCtrl.text = post.district;
    _priceCtrl.text = _formatMoney(post.price);
    _depositCtrl.text = _formatMoney(post.deposit ?? 0);
    _utilityCtrl.text = _formatMoney(post.electricityWaterCost ?? 0);
    _descriptionCtrl.text = post.description;
    _areaCtrl.text = post.hasKnownArea ? post.areaM2.toString() : '';
    _maxOccupants = post.maxOccupants;
    _amenities
      ..clear()
      ..addAll(post.amenities);
    _imageUrl = post.imageUrl;
    _imageObjectKey = null;
  }

  double _money(TextEditingController controller) {
    final value = double.tryParse(
      controller.text.replaceAll('.', '').replaceAll('đ', '').trim(),
    );
    if (value == null || !value.isFinite || value < 0) {
      throw const FormatException(
        'Chi phí phải là số tiền không âm, không kèm đơn vị khác.',
      );
    }
    return value;
  }

  void _validatePost() {
    _validateArea();
    final currentOccupants = _editingExisting
        ? (_selectedPost?.currentOccupants ?? 0)
        : 0;
    if (_maxOccupants < 1 ||
        currentOccupants < 0 ||
        currentOccupants > _maxOccupants) {
      throw const FormatException(
        'Số người tối đa không được nhỏ hơn số người đang ở.',
      );
    }
    if (_titleCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty ||
        _districtCtrl.text.trim().isEmpty ||
        _descriptionCtrl.text.trim().isEmpty ||
        _money(_priceCtrl) <= 0) {
      throw const FormatException(
        'Vui lòng nhập đủ thông tin, giá thuê và diện tích lớn hơn 0.',
      );
    }
    if (_money(_priceCtrl) < 100000) {
      throw const FormatException('Giá thuê tối thiểu là 100.000 VNĐ.');
    }
    if (_titleCtrl.text.trim().length > 200 ||
        _addressCtrl.text.trim().length > 255 ||
        _districtCtrl.text.trim().length > 100 ||
        _amenities.join(',').length > 500) {
      throw const FormatException(
        'Tiêu đề, địa chỉ, khu vực hoặc tiện ích vượt quá độ dài cho phép.',
      );
    }
    _money(_depositCtrl);
    _money(_utilityCtrl);
  }

  void _validateArea() {
    if (!_area.isFinite || _area <= 0) {
      throw const FormatException('Vui lòng nhập diện tích lớn hơn 0.');
    }
  }

  void _continueFromBasicInfo() {
    try {
      _validateArea();
      _goTo(ListingFlowMode.photosAmenities);
    } on FormatException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pickImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 90,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw const FormatException('Ảnh phải nhỏ hơn hoặc bằng 5 MB.');
      }
      final name = image.name.toLowerCase();
      final ticket = await _api.uploadImage(
        bytes: bytes,
        fileName: image.name,
        contentType: name.endsWith('.png')
            ? 'image/png'
            : name.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg',
        purpose: 'room-post',
      );
      if (mounted) {
        setState(() {
          _imageObjectKey = ticket.objectKey;
          _imageUrl = ticket.publicUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tải ảnh: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleSaveEdit() async {
    if (_busy) return;
    final post = _selectedPost;
    if (post != null) {
      if (!_api.hasAuthToken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng đăng nhập để cập nhật tin.'),
            ),
          );
        }
        return;
      }
      setState(() => _busy = true);
      try {
        _validatePost();
        await _api.updateRoomPost(
          postId: post.id,
          title: _titleCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          price: _money(_priceCtrl),
          address: _addressCtrl.text.trim(),
          district: _districtCtrl.text.trim(),
          deposit: _money(_depositCtrl),
          electricityWaterCost: _utilityCtrl.text.trim(),
          area: _area,
          maxOccupants: _maxOccupants,
          currentOccupants: post.currentOccupants,
          amenities: _amenities.toList(),
          imageObjectKey: _imageObjectKey,
        );
        if (!mounted) return;
        await _loadData();
        if (!mounted) return;
        _goTo(ListingFlowMode.submitted);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi khi cập nhật tin: ${e.toString().replaceAll("Exception: ", "")}',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Future<void> _handleSubmitNewPost() async {
    if (_busy) return;
    if (!_api.hasAuthToken) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để gửi tin đăng.')),
        );
      }
      return;
    }

    setState(() => _busy = true);
    try {
      _validatePost();
      await _api.createRoomPost({
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'price': _money(_priceCtrl),
        'address': _addressCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'deposit': _money(_depositCtrl),
        'electricityWaterCost': _money(_utilityCtrl),
        if (_imageObjectKey != null) 'imageObjectKey': _imageObjectKey,
        'area': _area,
        'maxOccupants': _maxOccupants,
        'currentOccupants': 0,
        'amenities': _amenities.join(','),
      });
      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      _goTo(ListingFlowMode.submitted);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi đăng tin: ${e.toString().replaceAll("Exception: ", "")}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleCloseListing() async {
    if (_busy) return;
    final post = _selectedPost;
    if (post != null) {
      if (!_api.hasAuthToken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng đăng nhập để đóng tin đăng.'),
            ),
          );
        }
        return;
      }
      setState(() => _busy = true);
      try {
        await _api.closeRoomPost(post.id);
        if (!mounted) return;
        await _loadData();
        if (!mounted) return;
        _goTo(ListingFlowMode.closed);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi khi đóng tin: ${e.toString().replaceAll("Exception: ", "")}',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _districtCtrl.dispose();
    _priceCtrl.dispose();
    _depositCtrl.dispose();
    _utilityCtrl.dispose();
    _descriptionCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (_mode) {
      case ListingFlowMode.myListings:
        return 'Tin đăng của tôi';
      case ListingFlowMode.create:
        return 'Đăng phòng mới';
      case ListingFlowMode.photosAmenities:
        return 'Ảnh & tiện ích';
      case ListingFlowMode.priceRules:
        return 'Giá & nội quy';
      case ListingFlowMode.preview:
        return 'Xem trước tin đăng';
      case ListingFlowMode.submitted:
        return 'Đã gửi tin đăng';
      case ListingFlowMode.edit:
        return 'Chỉnh sửa tin đăng';
      case ListingFlowMode.viewingRequest:
        return 'Yêu cầu xem phòng';
      case ListingFlowMode.reportReceived:
        return 'Thông tin báo cáo';
      case ListingFlowMode.confirmedViewing:
        return 'Đã xác nhận lịch';
      case ListingFlowMode.close:
        return 'Đóng tin đăng';
      case ListingFlowMode.closed:
        return 'Tin đã đóng';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        leading: PenpotBackButton(onPressed: _handleBack),
        title: Text(_title),
        backgroundColor: _canvas,
        foregroundColor: _ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: _body(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goTo(ListingFlowMode next) {
    if (_mode == next) return;
    _history.add(_mode);
    setState(() => _mode = next);
  }

  void _handleBack() {
    if (_history.isNotEmpty) {
      final previous = _history.removeLast();
      setState(() => _mode = previous);
      return;
    }
    Navigator.maybePop(context);
  }

  Widget _body(BuildContext context) {
    switch (_mode) {
      case ListingFlowMode.myListings:
        return _myListings(context);
      case ListingFlowMode.create:
        return _createForm(context);
      case ListingFlowMode.photosAmenities:
        return _photos(context);
      case ListingFlowMode.priceRules:
        return _priceRules(context);
      case ListingFlowMode.preview:
        return _preview(context);
      case ListingFlowMode.submitted:
        return _submitted(context);
      case ListingFlowMode.edit:
        return _editForm(context);
      case ListingFlowMode.viewingRequest:
        return _viewingRequest(context);
      case ListingFlowMode.reportReceived:
        return _reportReceived(context);
      case ListingFlowMode.confirmedViewing:
        return _confirmedViewing(context);
      case ListingFlowMode.close:
        return _close(context);
      case ListingFlowMode.closed:
        return _closed(context);
    }
  }

  Widget _myListings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Quản lý phòng và yêu cầu xem phòng',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        if (_loadError != null)
          Text(_loadError!, style: const TextStyle(color: Colors.red)),
        if (_myPosts.isEmpty)
          _emptyState(
            context,
            Icons.post_add_outlined,
            'Bạn chưa có tin đăng nào',
            'Tạo tin đầu tiên để tìm người ở ghép phù hợp.',
          )
        else
          ..._myPosts.map((post) => _postCard(context, post)),
        const SizedBox(height: 18),
        _button('+ Đăng phòng mới', () {
          _editingExisting = false;
          _selectedPost = null;
          for (final controller in [
            _titleCtrl,
            _addressCtrl,
            _districtCtrl,
            _priceCtrl,
            _descriptionCtrl,
          ]) {
            controller.clear();
          }
          _depositCtrl.text = '0';
          _utilityCtrl.text = '0';
          _areaCtrl.clear();
          _maxOccupants = 2;
          _amenities.clear();
          _imageObjectKey = null;
          _imageUrl = null;
          _goTo(ListingFlowMode.create);
        }),
      ],
    );
  }

  String _postStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'CHỜ DUYỆT';
      case 'REJECTED':
        return 'CẦN SỬA';
      case 'CLOSED':
        return 'ĐÃ ĐÓNG';
      case 'APPROVED':
      case 'AVAILABLE':
        return 'ĐANG HIỂN THỊ';
      default:
        return 'CHƯA RÕ TRẠNG THÁI';
    }
  }

  Widget _postCard(BuildContext context, RoomPost post) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    post.title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _statusBadge(_postStatusLabel(post.status)),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              '${_formatMoney(post.price)}đ / tháng · ${post.areaLabel}',
              style: const TextStyle(color: _muted),
            ),
            if (post.moderationReason != null)
              Text('Phản hồi kiểm duyệt: ${post.moderationReason}'),
            const SizedBox(height: 3),
            Text(
              post.address,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: () {
                    _selectPost(post);
                    _editingExisting = true;
                    _goTo(ListingFlowMode.edit);
                  },
                  child: const Text('Chỉnh sửa tin đăng'),
                ),
                OutlinedButton(
                  onPressed: () {
                    _selectedPost = post;
                    _goTo(ListingFlowMode.viewingRequest);
                  },
                  child: Text(
                    'Yêu cầu xem phòng · ${_appointments.where((a) => a.roomPostId == post.id && a.hostId == widget.authorId && a.status == 'PENDING').length}',
                  ),
                ),
                if (post.status != 'CLOSED')
                  TextButton(
                    onPressed: () {
                      _selectedPost = post;
                      _goTo(ListingFlowMode.close);
                    },
                    child: const Text('Đóng tin đăng'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _createForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _stageHeader(
          '1 / 3 · Thông tin cơ bản',
          'Bắt đầu bằng những thông tin người xem cần biết.',
        ),
        _input(
          'Tiêu đề bài đăng',
          _titleCtrl,
          hint: 'Studio ngập nắng, có ban công',
        ),
        _input(
          'Địa chỉ / khu vực',
          _addressCtrl,
          hint: 'Nguyễn Gia Trí, Bình Thạnh, TP.HCM',
        ),
        _input('Quận / huyện', _districtCtrl),
        _input('Mô tả', _descriptionCtrl, maxLines: 4),
        Row(
          children: <Widget>[
            Expanded(
              child: _input(
                'Diện tích (m²)',
                _areaCtrl,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                hint: 'Ví dụ: 25,5',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _numberInput(
                'Số người tối đa',
                '$_maxOccupants người',
                () => setState(
                  () => _maxOccupants = _maxOccupants >= 6
                      ? 1
                      : _maxOccupants + 1,
                ),
              ),
            ),
          ],
        ),
        const Text('Ngày nhận phòng: ghi cụ thể trong mô tả nếu cần.'),
        const SizedBox(height: 6),
        _button('Tiếp tục · Ảnh & tiện ích', _continueFromBasicInfo),
      ],
    );
  }

  Widget _photos(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _stageHeader(
          '2 / 3 · Giúp người xem hiểu căn phòng',
          'Hình ảnh rõ ràng giúp tin đăng đáng tin cậy hơn.',
        ),
        const SizedBox(height: 14),
        const Text(
          'Ảnh bìa',
          style: TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _busy ? null : _pickImage,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 164,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: _imageUrl == null
                ? const Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: _primary,
                      size: 52,
                    ),
                  )
                : Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        const Center(child: Text('Không tải được ảnh')),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_imageUrl == null ? 0 : 1} ảnh bìa · JPG, PNG · Tối đa 5 MB',
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 20),
        const Text(
          'Tiện ích có sẵn',
          style: TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _amenityOptions.map((amenity) {
            final selected = _amenities.contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: selected,
              selectedColor: _soft,
              checkmarkColor: _primary,
              onSelected: (value) => setState(
                () => value
                    ? _amenities.add(amenity)
                    : _amenities.remove(amenity),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text(
          'Chọn ảnh bìa rõ, đủ sáng và đúng thực tế.',
          style: TextStyle(color: _muted, height: 1.4),
        ),
        const SizedBox(height: 24),
        _button(
          'Tiếp tục · Giá & nội quy',
          () => _goTo(ListingFlowMode.priceRules),
        ),
      ],
    );
  }

  Widget _priceRules(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _stageHeader(
          '3 / 3 · Minh bạch trước khi kết nối',
          'Nêu rõ chi phí và nguyên tắc sống chung.',
        ),
        _input(
          'Tiền thuê / tháng',
          _priceCtrl,
          keyboard: TextInputType.number,
          hint: '3.500.000đ',
        ),
        _input('Tiền cọc (đ)', _depositCtrl, keyboard: TextInputType.number),
        _input(
          'Tổng điện / nước / phí dịch vụ mỗi tháng (đ)',
          _utilityCtrl,
          keyboard: TextInputType.number,
        ),
        _input('Mô tả và nội quy', _descriptionCtrl, maxLines: 4),
        const SizedBox(height: 24),
        _button('Xem trước tin đăng', () => _goTo(ListingFlowMode.preview)),
      ],
    );
  }

  Widget _preview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.home_work_outlined, color: _primary, size: 62),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _titleCtrl.text.trim(),
          style: const TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_addressCtrl.text.trim()} · ${RoomPost.formatArea(_area)} · Tối đa $_maxOccupants người',
          style: const TextStyle(color: _muted),
        ),
        const SizedBox(height: 14),
        _previewRow('Giá thuê', '${_priceCtrl.text.trim()} / tháng'),
        _previewRow('Tiền cọc', '${_depositCtrl.text}đ'),
        _previewRow('Chi phí', '${_utilityCtrl.text}đ / tháng'),
        _previewRow('Mô tả', _descriptionCtrl.text.trim()),
        const SizedBox(height: 10),
        const Text(
          'Kiểm tra kỹ thông tin trước khi gửi',
          style: TextStyle(color: _muted, height: 1.4),
        ),
        const SizedBox(height: 24),
        _button(
          _editingExisting ? 'Lưu & gửi kiểm duyệt' : 'Gửi tin để duyệt',
          _editingExisting ? _handleSaveEdit : _handleSubmitNewPost,
        ),
      ],
    );
  }

  Widget _editForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _infoCard(
          Icons.home_work_outlined,
          _selectedPost?.title ?? 'Chưa chọn tin',
          'Chỉnh sửa sẽ gửi tin để kiểm duyệt lại.',
        ),
        const SizedBox(height: 14),
        _input('Tiêu đề', _titleCtrl),
        _input('Giá thuê / tháng', _priceCtrl, keyboard: TextInputType.number),
        _input(
          'Diện tích (m²)',
          _areaCtrl,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          hint: 'Nhập diện tích thực tế',
        ),
        _input('Địa chỉ / khu vực', _addressCtrl),
        _input('Quận / huyện', _districtCtrl),
        _input('Tiền cọc (đ)', _depositCtrl, keyboard: TextInputType.number),
        _input(
          'Tổng chi phí điện / nước mỗi tháng (đ)',
          _utilityCtrl,
          keyboard: TextInputType.number,
        ),
        const Text('Để ngừng cho thuê, dùng thao tác Đóng tin đăng.'),
        const SizedBox(height: 14),
        _input('Mô tả', _descriptionCtrl, maxLines: 4),
        const SizedBox(height: 6),
        _button('Lưu & gửi kiểm duyệt', _handleSaveEdit),
      ],
    );
  }

  Widget _submitted(BuildContext context) {
    return _emptyState(
      context,
      Icons.check_circle_outline,
      'Tin của bạn đang chờ kiểm duyệt',
      'Bạn sẽ nhận thông báo khi có kết quả. Tin chưa hiển thị trong danh sách phòng.',
      badge: 'Chờ duyệt',
      action: _button(
        'Về tin đăng của tôi',
        () => _goTo(ListingFlowMode.myListings),
      ),
    );
  }

  Widget _viewingRequest(BuildContext context) {
    if (_loadingData) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Column(
        children: [
          Text(_loadError!),
          TextButton(onPressed: _loadData, child: const Text('Thử lại')),
        ],
      );
    }
    final appointments = _appointments
        .where(
          (apt) =>
              apt.hostId == widget.authorId &&
              apt.roomPostId == _selectedPost?.id,
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Lịch hẹn tại phòng bạn đang đăng',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        if (appointments.isNotEmpty)
          ...appointments.map((apt) {
            final timeStr = DateFormat(
              'dd / MM, HH:mm',
            ).format(apt.appointmentTime);
            return Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: _border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${apt.requesterName} · $timeStr',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _statusBadge(
                      '${apt.status == 'PENDING' ? 'Chờ xác nhận' : apt.status} · ${apt.roomTitle}',
                    ),
                    if (apt.note != null && apt.note!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        '“${apt.note}”',
                        style: const TextStyle(color: _muted, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        if (apt.status == 'PENDING')
                          FilledButton(
                            onPressed: () async {
                              if (!_api.hasAuthToken) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vui lòng đăng nhập để xác nhận lịch hẹn.',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }
                              try {
                                await _api.updateAppointmentStatus(
                                  apt.id,
                                  'CONFIRMED',
                                );
                                if (!context.mounted) return;
                                _selectedAppointment = apt;
                                await _loadData();
                                if (!context.mounted) return;
                                _goTo(ListingFlowMode.confirmedViewing);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Lỗi khi xác nhận lịch hẹn: ${e.toString().replaceAll("Exception: ", "")}',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                            ),
                            child: const Text('Xác nhận lịch hẹn'),
                          ),
                        if (apt.status == 'PENDING' ||
                            apt.status == 'CONFIRMED')
                          OutlinedButton(
                            onPressed: () async {
                              if (!_api.hasAuthToken) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vui lòng đăng nhập để từ chối lịch hẹn.',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }
                              try {
                                await _api.updateAppointmentStatus(
                                  apt.id,
                                  'CANCELLED',
                                );
                                if (!context.mounted) return;
                                await _loadData();
                                if (!context.mounted) return;
                                _goTo(ListingFlowMode.myListings);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Lỗi khi từ chối lịch hẹn: ${e.toString().replaceAll("Exception: ", "")}',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Từ chối / hủy lịch'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          })
        else
          const Text('Tin này chưa có lịch xem phòng.'),
        const SizedBox(height: 12),
        const Text(
          'Kiểm tra thông tin lịch hẹn, trao đổi điểm hẹn và chuẩn bị trước khi đón khách.',
          style: TextStyle(color: _muted, height: 1.4),
        ),
      ],
    );
  }

  Widget _reportReceived(BuildContext context) {
    return _emptyState(
      context,
      Icons.info_outline,
      'Chưa có mã tiếp nhận',
      'Mở báo cáo từ hồ sơ người dùng hoặc chi tiết liên hệ. Mã tiếp nhận chỉ hiển thị sau khi máy chủ xác nhận.',
      action: _button('Về hồ sơ', () => Navigator.maybePop(context)),
    );
  }

  Widget _confirmedViewing(BuildContext context) {
    final firstApt = _selectedAppointment;
    final info = firstApt != null
        ? '${firstApt.requesterName} · ${DateFormat('dd / MM / yyyy · HH:mm').format(firstApt.appointmentTime)}'
        : 'Chưa có lịch hẹn được xác nhận.';
    return _emptyState(
      context,
      Icons.check_circle_outline,
      'Hẹn gặp tại căn phòng!',
      info,
      action: _button(
        'Quản lý tin đăng',
        () => _goTo(ListingFlowMode.myListings),
      ),
    );
  }

  Widget _close(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 24),
        const Text(
          'Bạn đã tìm được người thuê?',
          style: TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tin sẽ ngừng xuất hiện trong danh sách. Hãy xử lý các lịch xem phòng đang chờ trước khi đóng.',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 26),
        _button('Xác nhận đóng tin', _handleCloseListing),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _handleBack,
            child: const Text('Giữ tin đăng'),
          ),
        ),
      ],
    );
  }

  Widget _closed(BuildContext context) {
    return _emptyState(
      context,
      Icons.check_circle_outline,
      'Căn phòng đã ngừng hiển thị',
      'Bạn vẫn có thể xem lại nội dung và đăng tin mới khi có phòng.',
      action: _button(
        'Về tin đăng của tôi',
        () => _goTo(ListingFlowMode.myListings),
      ),
    );
  }

  Widget _stageHeader(String label, String helper) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: _primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(helper, style: const TextStyle(color: _muted, height: 1.4)),
        ],
      ),
    );
  }

  Widget _numberInput(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: _fieldDecoration(label),
          child: Text(value, style: const TextStyle(color: _ink)),
        ),
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: _fieldDecoration(label, hint: hint),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    String label, {
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: _muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: _primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 104,
            child: Text(label, style: const TextStyle(color: _muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _emptyState(
    BuildContext context,
    IconData icon,
    String title,
    String description, {
    Widget? action,
    String? badge,
  }) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 38),
        Icon(icon, color: _primary, size: 64),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (badge != null) ...<Widget>[
          const SizedBox(height: 10),
          _statusBadge(badge),
        ],
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, height: 1.5),
        ),
        if (action != null) ...<Widget>[const SizedBox(height: 24), action],
      ],
    );
  }

  Widget _button(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          _busy ? 'Đang xử lý…' : label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _formatMoney(num value) =>
      NumberFormat('#,###', 'en_US').format(value).replaceAll(',', '.');
}
