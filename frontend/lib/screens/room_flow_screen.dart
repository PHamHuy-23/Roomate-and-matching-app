import 'package:flutter/material.dart';
import '../models/district_names.dart';
import 'package:intl/intl.dart';

import '../models/room_post.dart';
import '../models/viewing_appointment.dart';
import '../navigation/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/room_location_map.dart';
import 'room_details_screen.dart';
import 'room_viewing_screen.dart';

enum RoomFlowMode {
  landing,
  roomInfo,
  roomPhotos,
  livingRoom,
  bedroom,
  kitchen,
  requestSent,
  viewingSchedule,
  appointmentDetails,
  cancelAppointment,
  location,
}

class RoomFlowScreen extends StatefulWidget {
  const RoomFlowScreen({
    this.post,
    required this.mode,
    this.currentUserId,
    this.appointmentId,
    this.appointment,
    this.apiService,
    super.key,
  }) : assert(
         post != null ||
             mode == RoomFlowMode.viewingSchedule ||
             mode == RoomFlowMode.appointmentDetails ||
             mode == RoomFlowMode.cancelAppointment ||
             mode == RoomFlowMode.requestSent,
       );

  final RoomPost? post;
  final RoomFlowMode mode;
  final int? currentUserId;
  final int? appointmentId;
  final ViewingAppointment? appointment;
  final ApiService? apiService;

  @override
  State<RoomFlowScreen> createState() => _RoomFlowScreenState();
}

class _RoomFlowScreenState extends State<RoomFlowScreen> {
  static const _canvas = Color(0xFFF5F8F7);
  static const _primary = Color(0xFF087E6B);
  static const _ink = Color(0xFF142523);
  static const _muted = Color(0xFF52625F);
  static const _soft = Color(0xFFE8F4F1);

  late RoomFlowMode _mode;
  final List<RoomFlowMode> _history = [];
  ApiService get _api => widget.apiService ?? ApiService();
  List<ViewingAppointment> _appointments = [];
  ViewingAppointment? _selectedAppointment;
  bool _loadingAppointments = false;
  bool _busy = false;
  String? _appointmentError;
  int _scheduleTab = 0;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    final appointment = widget.appointment;
    if (appointment != null &&
        appointment.requesterId == widget.currentUserId) {
      _selectedAppointment = appointment;
    }
    if (_isAppointmentMode(_mode) && _mode != RoomFlowMode.requestSent) {
      _loadAppointments();
    }
  }

  RoomPost get post => widget.post!;
  RoomFlowMode get mode => _mode;

  bool _isAppointmentMode(RoomFlowMode mode) => {
    RoomFlowMode.requestSent,
    RoomFlowMode.viewingSchedule,
    RoomFlowMode.appointmentDetails,
    RoomFlowMode.cancelAppointment,
  }.contains(mode);

  Future<void> _loadAppointments() async {
    if (_loadingAppointments || _busy) return;
    setState(() {
      _loadingAppointments = true;
      _appointmentError = null;
    });
    try {
      final userId = widget.currentUserId;
      if (userId == null) {
        throw const ApiException('Không xác định được tài khoản đặt lịch.');
      }
      final data = await _api.getMyAppointments();
      if (!mounted) return;
      final owned = data.where((apt) => apt.requesterId == userId).toList();
      final selectedId = _selectedAppointment?.id ?? widget.appointmentId;
      setState(() {
        _appointments = owned;
        final selected = owned.where((apt) => apt.id == selectedId);
        _selectedAppointment = selected.isEmpty ? null : selected.first;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _appointmentError = e is ApiException
              ? e.message
              : 'Không tải được lịch xem phòng.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAppointments = false);
    }
  }

  String _status(ViewingAppointment apt) => switch (apt.status) {
    'PENDING' => 'Chờ xác nhận',
    'CONFIRMED' => 'Đã xác nhận',
    'COMPLETED' => 'Đã hoàn tất',
    'CANCELLED' => 'Đã hủy',
    _ => 'Trạng thái chưa xác định',
  };
  bool _canCancel(ViewingAppointment apt) =>
      apt.requesterId == widget.currentUserId &&
      {'PENDING', 'CONFIRMED'}.contains(apt.status);
  String _time(ViewingAppointment apt) =>
      DateFormat('dd/MM/yyyy · HH:mm').format(apt.appointmentTime);

  Future<void> _cancelSelectedAppointment() async {
    final apt = _selectedAppointment;
    if (_busy || apt == null || !_canCancel(apt)) return;
    setState(() => _busy = true);
    try {
      final updated = await _api.updateAppointmentStatus(apt.id, 'CANCELLED');
      if (updated.id != apt.id ||
          updated.requesterId != widget.currentUserId ||
          updated.status != 'CANCELLED') {
        throw const ApiException('Máy chủ chưa xác nhận hủy lịch hẹn.');
      }
      if (!mounted) return;
      setState(() {
        _selectedAppointment = updated;
        _appointments = _appointments
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
        _mode = RoomFlowMode.appointmentDetails;
        _history.removeWhere(
          (item) =>
              item == RoomFlowMode.appointmentDetails ||
              item == RoomFlowMode.cancelAppointment,
        );
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Đã hủy lịch hẹn')));
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException
                  ? e.message
                  : 'Không thể hủy lịch hẹn. Vui lòng thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAppointmentRoom() async {
    final apt = _selectedAppointment;
    if (_busy || apt == null) return;
    setState(() => _busy = true);
    try {
      final room = await _api.getRoomPost(apt.roomPostId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RoomDetailsScreen(post: room)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException
                  ? e.message
                  : 'Không thể mở phòng. Tin có thể không còn hiển thị.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isPhotoMode(RoomFlowMode m) =>
      m == RoomFlowMode.roomPhotos ||
      m == RoomFlowMode.livingRoom ||
      m == RoomFlowMode.bedroom ||
      m == RoomFlowMode.kitchen;

  void _changeMode(RoomFlowMode next) {
    if (_mode == next) return;
    // Don't accumulate photo-to-photo switches in history.
    // Switching photos in gallery is browsing views, not opening a new screen.
    if (!(_isPhotoMode(_mode) && _isPhotoMode(next))) {
      _history.add(_mode);
    }
    setState(() => _mode = next);
    if (next == RoomFlowMode.viewingSchedule) _loadAppointments();
  }

  void _handleBack() {
    if (_busy) return;
    if (_history.isNotEmpty) {
      final prev = _history.removeLast();
      setState(() => _mode = prev);
      return;
    }
    Navigator.pop(context);
  }

  String get _title {
    switch (mode) {
      case RoomFlowMode.landing:
        return 'Một nơi để gọi là nhà';
      case RoomFlowMode.roomInfo:
        return 'Thông tin căn phòng';
      case RoomFlowMode.roomPhotos:
      case RoomFlowMode.livingRoom:
      case RoomFlowMode.bedroom:
      case RoomFlowMode.kitchen:
        return 'Ảnh căn phòng';
      case RoomFlowMode.requestSent:
        return 'Đã gửi yêu cầu';
      case RoomFlowMode.viewingSchedule:
        return 'Lịch xem phòng';
      case RoomFlowMode.appointmentDetails:
        return 'Chi tiết lịch hẹn';
      case RoomFlowMode.cancelAppointment:
        return 'Hủy lịch hẹn';
      case RoomFlowMode.location:
        return 'Vị trí & khu vực';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _history.isEmpty && !_busy,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: _canvas,
        appBar: AppBar(
          title: Text(_title),
          backgroundColor: _canvas,
          foregroundColor: _ink,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Quay lại',
            onPressed: _busy ? null : _handleBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Đóng',
              onPressed: _busy ? null : () => Navigator.pop(context),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [_buildBody(context)],
          ),
        ),
        bottomNavigationBar: mode == RoomFlowMode.roomInfo
            ? SafeArea(
                minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _button(
                      'Xem vị trí & khu vực',
                      () => _changeMode(RoomFlowMode.location),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isAppointmentMode(mode) && mode != RoomFlowMode.requestSent) {
      if (_loadingAppointments) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_appointmentError != null) {
        return Column(
          children: [
            Text(_appointmentError!),
            TextButton(
              onPressed: _loadAppointments,
              child: const Text('Thử lại'),
            ),
          ],
        );
      }
      if (mode != RoomFlowMode.viewingSchedule &&
          _selectedAppointment == null) {
        return const Text('Không tìm thấy lịch hẹn của bạn.');
      }
    }
    switch (mode) {
      case RoomFlowMode.landing:
        return _landing(context);
      case RoomFlowMode.roomInfo:
        return _roomInfo(context);
      case RoomFlowMode.roomPhotos:
      case RoomFlowMode.livingRoom:
      case RoomFlowMode.bedroom:
      case RoomFlowMode.kitchen:
        return _photoGallery(context);
      case RoomFlowMode.requestSent:
        return _requestSent(context);
      case RoomFlowMode.viewingSchedule:
        return _viewingSchedule(context);
      case RoomFlowMode.appointmentDetails:
        return _appointmentDetails(context);
      case RoomFlowMode.cancelAppointment:
        return _cancelAppointment(context);
      case RoomFlowMode.location:
        return _location(context);
    }
  }

  Widget _landing(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          height: 230,
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: Icon(Icons.home_work_outlined, color: _primary, size: 96),
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Tìm một căn phòng phù hợp với nhịp sống của bạn.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 28),
        _button('Khám phá phòng', () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement<void, void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => RoomDetailsScreen(post: post),
              ),
            );
          }
        }),
      ],
    );
  }

  Widget _roomInfo(BuildContext context) {
    final price = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(post.price);
    final amenities = post.amenities
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    String cost(double? value) => value == null
        ? 'Chưa cập nhật'
        : NumberFormat.currency(
            locale: 'vi_VN',
            symbol: 'đ',
            decimalDigits: 0,
          ).format(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.title,
          style: const TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(post.address, style: const TextStyle(color: _muted)),
        const SizedBox(height: 18),
        const Text(
          'Không gian dành cho bạn',
          style: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          post.description.trim().isEmpty
              ? 'Chưa cập nhật mô tả phòng.'
              : post.description,
          style: const TextStyle(color: _muted, height: 1.55),
        ),
        const SizedBox(height: 22),
        const Text(
          'Tiện ích',
          style: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (amenities.isEmpty)
          const Text('Chưa cập nhật tiện ích.', style: TextStyle(color: _muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amenities.map((item) => _amenity(item)).toList(),
          ),
        const SizedBox(height: 22),
        const Text(
          'Chi phí minh bạch',
          style: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _infoRow(Icons.payments_outlined, 'Tiền phòng', '$price / tháng'),
        _infoRow(
          Icons.account_balance_wallet_outlined,
          'Tiền cọc',
          cost(post.deposit),
        ),
        _infoRow(
          Icons.bolt_outlined,
          'Tổng điện nước / phí dịch vụ mỗi tháng',
          cost(post.electricityWaterCost),
        ),
        const SizedBox(height: 12),
        const Text(
          'Nội quy',
          style: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nội quy chưa được cung cấp. Vui lòng trao đổi với người đăng.',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _photoGallery(BuildContext context) {
    final hasImage = post.imageUrl?.trim().isNotEmpty == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _photoPreview(),
        const SizedBox(height: 18),
        const Text(
          'Ảnh người đăng cung cấp',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasImage ? '1 ảnh phòng' : 'Người đăng chưa cập nhật ảnh phòng.',
          style: const TextStyle(color: _muted),
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 10),
        _button(
          'Xem thông tin căn phòng',
          () => _changeMode(RoomFlowMode.roomInfo),
        ),
      ],
    );
  }

  Widget _requestSent(BuildContext context) {
    final apt = _selectedAppointment;
    if (apt == null) return const Text('Không xác định được lịch hẹn đã gửi.');
    return Column(
      children: [
        const SizedBox(height: 30),
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(color: _soft, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: _primary, size: 48),
        ),
        const SizedBox(height: 22),
        const Text(
          'Đã gửi yêu cầu',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${_status(apt)}\n${_time(apt)}\n${apt.roomTitle}\n${apt.hostName}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 28),
        _button(
          'Xem lịch xem phòng',
          () => _changeMode(RoomFlowMode.viewingSchedule),
        ),
      ],
    );
  }

  Widget _viewingSchedule(BuildContext context) {
    final now = DateTime.now();
    bool upcoming(ViewingAppointment apt) =>
        {'PENDING', 'CONFIRMED'}.contains(apt.status) &&
        apt.appointmentTime.isAfter(now);
    final appointments =
        _appointments
            .where(
              (apt) => switch (_scheduleTab) {
                0 => upcoming(apt),
                1 => apt.status != 'CANCELLED' && !upcoming(apt),
                _ => apt.status == 'CANCELLED',
              },
            )
            .toList()
          ..sort(
            (a, b) => _scheduleTab == 0
                ? a.appointmentTime.compareTo(b.appointmentTime)
                : b.appointmentTime.compareTo(a.appointmentTime),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theo dõi lịch hẹn và phản hồi',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          children: [
            _scheduleChip('Sắp tới', 0),
            _scheduleChip('Lịch sử', 1),
            _scheduleChip('Đã hủy', 2),
          ],
        ),
        const SizedBox(height: 18),
        if (appointments.isEmpty) const Text('Chưa có lịch hẹn trong mục này.'),
        ...appointments.map((apt) => _appointmentCard(apt)),
        TextButton.icon(
          onPressed: _loadAppointments,
          icon: const Icon(Icons.refresh),
          label: const Text('Tải lại lịch hẹn'),
        ),
      ],
    );
  }

  Widget _appointmentDetails(BuildContext context) {
    final apt = _selectedAppointment!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _status(apt),
          style: const TextStyle(color: _primary, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Text(
          apt.roomTitle,
          style: const TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_time(apt)}\n${apt.roomAddress}',
          style: const TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 10),
        Text(
          'Người đăng: ${apt.hostName}',
          style: const TextStyle(color: _muted),
        ),
        const SizedBox(height: 14),
        if (apt.note?.trim().isNotEmpty == true) Text('Lời nhắn: ${apt.note}'),
        const SizedBox(height: 18),
        _button('Xem phòng', _busy ? null : _openAppointmentRoom),
        if (apt.status == 'CONFIRMED') ...[
          const SizedBox(height: 8),
          _button(
            'Nhắn người đăng',
            _busy
                ? null
                : () => Navigator.pushNamed(
                    context,
                    AppRoutes.chat,
                    arguments: {
                      'partnerId': apt.hostId,
                      'partnerName': apt.hostName,
                    },
                  ),
          ),
        ],
        const SizedBox(height: 8),
        if (_canCancel(apt))
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _changeMode(RoomFlowMode.cancelAppointment),
            icon: const Icon(Icons.event_busy_outlined),
            label: const Text('Hủy lịch hẹn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        TextButton(
          onPressed: _busy ? null : _loadAppointments,
          child: const Text('Tải lại lịch hẹn'),
        ),
      ],
    );
  }

  Widget _cancelAppointment(BuildContext context) {
    final apt = _selectedAppointment!;
    if (!_canCancel(apt)) return _appointmentDetails(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bạn có chắc muốn hủy lịch này?',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${apt.roomTitle}\n${_time(apt)}',
          style: const TextStyle(color: _muted),
        ),
        const SizedBox(height: 18),
        const Text(
          'Lịch sẽ chuyển sang trạng thái đã hủy sau khi máy chủ xác nhận.\nBạn vẫn có thể đặt lịch khác sau này.',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 22),
        _button('Xác nhận hủy lịch', _busy ? null : _cancelSelectedAppointment),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy ? null : _handleBack,
          child: const Text('Giữ lịch hẹn'),
        ),
      ],
    );
  }

  Widget _location(BuildContext context) {
    final districtName = post.district.isNotEmpty
        ? DistrictNames.display(post.district)
        : 'TP. Hồ Chí Minh';
    final addressText = post.address.isNotEmpty
        ? post.address
        : 'Khu vực gần trung tâm';

    final lower = '${post.address} ${DistrictNames.display(post.district)}'
        .toLowerCase();
    String landmark1Title = 'Trường đại học lân cận';
    String landmark1Dist = 'Khoảng 700 m · 10 phút đi bộ';
    String landmark2Title = 'Chợ & cửa hàng tiện lợi';
    String landmark2Dist = 'Khoảng 300 m · 4 phút đi bộ';

    if (lower.contains('bình thạnh') ||
        lower.contains('nguyễn gia trí') ||
        lower.contains('hutech')) {
      landmark1Title = 'Đại học HUTECH / GTVT';
      landmark1Dist = 'Khoảng 650 m · 8 phút đi bộ';
      landmark2Title = 'Landmark 81 & Chợ Văn Thánh';
      landmark2Dist = 'Khoảng 1.2 km · 4 phút xe máy';
    } else if (lower.contains('quận 1')) {
      landmark1Title = 'Đại học Khoa học Xã hội & Nhân văn';
      landmark1Dist = 'Khoảng 800 m · 10 phút đi bộ';
      landmark2Title = 'Phố đi bộ Nguyễn Huệ & Chợ Bến Thành';
      landmark2Dist = 'Khoảng 1 km · 5 phút xe máy';
    } else if (lower.contains('quận 3')) {
      landmark1Title = 'Đại học Kinh tế TP.HCM (UEH)';
      landmark1Dist = 'Khoảng 500 m · 6 phút đi bộ';
      landmark2Title = 'Hồ Con Rùa & Công viên Lê Văn Tám';
      landmark2Dist = 'Khoảng 700 m · 9 phút đi bộ';
    } else if (lower.contains('quận 7')) {
      landmark1Title = 'Đại học Tôn Đức Thắng / RMIT';
      landmark1Dist = 'Khoảng 900 m · 12 phút đi bộ';
      landmark2Title = 'TTTM SC VivoCity & Crescent Mall';
      landmark2Dist = 'Khoảng 1.5 km · 5 phút xe máy';
    } else if (lower.contains('thủ đức')) {
      landmark1Title = 'Làng Đại học Quốc Gia TP.HCM';
      landmark1Dist = 'Khoảng 1.2 km · 4 phút xe máy';
      landmark2Title = 'Trạm Metro & Chợ Đêm Đại học';
      landmark2Dist = 'Khoảng 600 m · 8 phút đi bộ';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bản đồ OpenStreetMap tương tác trực tiếp
        RoomLocationMap(post: post, height: 240, showControls: true),
        const SizedBox(height: 18),
        Text(
          districtName,
          style: const TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(addressText, style: const TextStyle(color: _muted, height: 1.5)),
        const SizedBox(height: 18),
        _locationFact(landmark1Title, landmark1Dist),
        _locationFact(landmark2Title, landmark2Dist),
        const SizedBox(height: 12),
        const Text(
          'Địa chỉ cụ thể được trao đổi với người đăng\nsau khi lịch xem được xác nhận.',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 20),
        _button(
          'Đặt lịch xem phòng',
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RoomViewingScreen(post: post)),
          ),
        ),
      ],
    );
  }

  Widget _photoPreview() {
    final url = post.imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _photoFallback(),
              )
            : _photoFallback(),
      ),
    );
  }

  Widget _photoFallback() => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFFD7EDE7), Color(0xFF9BC8BC)]),
    ),
    child: Center(
      child: Icon(Icons.photo_library_outlined, color: _primary, size: 72),
    ),
  );

  Widget _amenity(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: _soft,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _ink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _scheduleChip(String label, int index) => ChoiceChip(
    label: Text(label),
    selected: _scheduleTab == index,
    onSelected: (_) => setState(() => _scheduleTab = index),
  );

  Widget _appointmentCard(ViewingAppointment apt) => InkWell(
    key: ValueKey('appointment-${apt.id}'),
    onTap: _busy
        ? null
        : () {
            _selectedAppointment = apt;
            _changeMode(RoomFlowMode.appointmentDetails);
          },
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _time(apt),
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(apt.roomTitle, style: const TextStyle(color: _muted)),
          const SizedBox(height: 6),
          Text(
            _status(apt),
            style: TextStyle(
              color: apt.status == 'CONFIRMED' ? _primary : _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _locationFact(String title, String detail) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(detail, style: const TextStyle(color: _muted)),
      ],
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: _primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(color: _muted)),
        ),
        Text(
          value,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _button(String label, VoidCallback? onPressed) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: _primary,
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}
