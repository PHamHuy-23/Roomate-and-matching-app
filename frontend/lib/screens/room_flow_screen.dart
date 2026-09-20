import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/room_post.dart';
import 'room_details_screen.dart';

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

class RoomFlowScreen extends StatelessWidget {
  const RoomFlowScreen({required this.post, required this.mode, super.key});

  final RoomPost post;
  final RoomFlowMode mode;

  static const _canvas = Color(0xFFF5F8F7);
  static const _primary = Color(0xFF087E6B);
  static const _ink = Color(0xFF142523);
  static const _muted = Color(0xFF52625F);
  static const _soft = Color(0xFFE8F4F1);

  String get _title {
    switch (mode) {
      case RoomFlowMode.landing:
        return 'Một nơi để gọi là nhà';
      case RoomFlowMode.roomInfo:
        return 'Thông tin căn phòng';
      case RoomFlowMode.roomPhotos:
        return 'Ảnh căn phòng';
      case RoomFlowMode.livingRoom:
        return 'Phòng khách';
      case RoomFlowMode.bedroom:
        return 'Phòng ngủ';
      case RoomFlowMode.kitchen:
        return 'Khu bếp';
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
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: _canvas,
        foregroundColor: _ink,
        elevation: 0,
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
                    () => _push(context, RoomFlowMode.location),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (mode) {
      case RoomFlowMode.landing:
        return _landing(context);
      case RoomFlowMode.roomInfo:
        return _roomInfo(context);
      case RoomFlowMode.roomPhotos:
        return _photoGallery(context, 'Ảnh căn phòng');
      case RoomFlowMode.livingRoom:
        return _photoGallery(context, 'Không gian phòng khách');
      case RoomFlowMode.bedroom:
        return _photoGallery(context, 'Không gian phòng ngủ');
      case RoomFlowMode.kitchen:
        return _photoGallery(context, 'Không gian khu bếp');
      case RoomFlowMode.requestSent:
        return _requestSent(context);
      case RoomFlowMode.viewingSchedule:
        return _schedulePlaceholder(context);
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
        _button(
          'Khám phá phòng',
          () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => RoomDetailsScreen(post: post),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roomInfo(BuildContext context) {
    final price = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(post.price);
    final amenities = post.amenities.isEmpty
        ? const [
            'Điều hòa',
            'Giường & tủ',
            'Wi-Fi',
            'Bếp riêng',
            'Máy giặt',
            'Giữ xe',
          ]
        : post.amenities;
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
          post.description.isEmpty
              ? 'Phòng thoáng, cửa sổ lớn và ban công riêng.'
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
        _infoRow(Icons.account_balance_wallet_outlined, 'Tiền cọc', price),
        _infoRow(Icons.bolt_outlined, 'Điện', '3.800đ / kWh'),
        _infoRow(Icons.water_drop_outlined, 'Nước', '100.000đ / người'),
        _infoRow(Icons.wifi_outlined, 'Internet & giữ xe', '150.000đ / tháng'),
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
          'Không hút thuốc trong phòng. Giữ yên tĩnh sau 23:00. Trao đổi trước nếu có thú cưng.',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _photoGallery(BuildContext context, String caption) {
    final nextMode = switch (mode) {
      RoomFlowMode.roomPhotos => RoomFlowMode.livingRoom,
      RoomFlowMode.livingRoom => RoomFlowMode.bedroom,
      RoomFlowMode.bedroom => RoomFlowMode.kitchen,
      _ => RoomFlowMode.roomPhotos,
    };
    final meta = mode == RoomFlowMode.roomPhotos
        ? '01 / 04 • Không gian chính'
        : 'Ảnh minh họa cho bản thiết kế.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _photoPreview(),
        const SizedBox(height: 18),
        Text(
          caption,
          style: const TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(meta, style: const TextStyle(color: _muted)),
        const SizedBox(height: 8),
        const Text(
          'Ánh sáng tự nhiên & ban công riêng',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _outlineButton(context, 'Phòng khách', RoomFlowMode.livingRoom),
            _outlineButton(context, 'Phòng ngủ', RoomFlowMode.bedroom),
            _outlineButton(context, 'Khu bếp', RoomFlowMode.kitchen),
          ],
        ),
        const SizedBox(height: 18),
        _outlineButton(context, 'Ảnh tiếp theo →', nextMode),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _push(context, RoomFlowMode.roomPhotos),
          child: const Text('Tất cả ảnh'),
        ),
        const SizedBox(height: 10),
        _button(
          'Xem thông tin căn phòng',
          () => _push(context, RoomFlowMode.roomInfo),
        ),
      ],
    );
  }

  Widget _requestSent(BuildContext context) {
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
          'Chờ người đăng xác nhận\n'
          '14:00 · Thứ Hai, 21/09/2026\n'
          '${post.title}\n'
          '${post.authorName.isEmpty ? 'Minh Anh' : post.authorName}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 28),
        _button(
          'Xem lịch xem phòng',
          () => _push(context, RoomFlowMode.viewingSchedule),
        ),
      ],
    );
  }

  Widget _schedulePlaceholder(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theo dõi lịch hẹn và phản hồi',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _tabLabel('Sắp tới', true),
            const SizedBox(width: 20),
            _tabLabel('Đã hủy', false),
          ],
        ),
        const SizedBox(height: 18),
        _appointmentCard(
          context,
          '21/09 · 14:00 · Chờ xác nhận',
          post.title,
          false,
        ),
        _appointmentCard(
          context,
          '22/09 · 10:30 · Đã xác nhận',
          'Phòng gần HUTECH · Bình Thạnh',
          true,
        ),
      ],
    );
  }

  Widget _appointmentDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chờ xác nhận',
          style: TextStyle(color: _primary, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Text(
          post.title,
          style: const TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Thứ Hai, 21/09/2026 · 14:00\n${post.address}',
          style: const TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 10),
        Text(
          'Người đăng: ${post.authorName.isEmpty ? 'Minh Anh' : post.authorName}',
          style: const TextStyle(color: _muted),
        ),
        const SizedBox(height: 14),
        _appointmentCard(
          context,
          'Thứ Hai, 21/09/2026 · 14:00',
          post.title,
          false,
        ),
        const SizedBox(height: 18),
        _button('Xem phòng', () => _push(context, RoomFlowMode.roomInfo)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _push(context, RoomFlowMode.cancelAppointment),
          icon: const Icon(Icons.event_busy_outlined),
          label: const Text('Hủy lịch hẹn'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _cancelAppointment(BuildContext context) {
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
        const Text('21/09/2026 · 14:00', style: TextStyle(color: _muted)),
        const SizedBox(height: 18),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Lý do hủy (không bắt buộc)',
            hintText: 'Mình có thay đổi kế hoạch.',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Người đăng sẽ nhận được thông báo hủy.\nBạn vẫn có thể đặt lịch khác sau này.',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 22),
        _button(
          'Xác nhận hủy lịch',
          () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API hủy lịch chưa được backend hỗ trợ.'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Giữ lịch hẹn'),
        ),
      ],
    );
  }

  Widget _location(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 210,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Icon(Icons.location_on_outlined, color: _primary, size: 70),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Bình Thạnh, TP. Hồ Chí Minh',
          style: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nguyễn Gia Trí',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        _locationFact('HUTECH', 'Khoảng 700 m · 10 phút đi bộ'),
        _locationFact('Chợ & cửa hàng tiện lợi', 'Khoảng 300 m · 4 phút đi bộ'),
        const SizedBox(height: 12),
        const Text(
          'Địa chỉ cụ thể được trao đổi với người đăng\nsau khi lịch xem được xác nhận.',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 20),
        _button(
          'Đặt lịch xem phòng',
          () => _push(context, RoomFlowMode.viewingSchedule),
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

  Widget _tabLabel(String label, bool selected) => Text(
    label,
    style: TextStyle(
      color: selected ? _primary : _muted,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
    ),
  );

  Widget _appointmentCard(
    BuildContext context,
    String date,
    String room,
    bool confirmed,
  ) => InkWell(
    onTap: () => _push(context, RoomFlowMode.appointmentDetails),
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
            date,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(room, style: const TextStyle(color: _muted)),
          const SizedBox(height: 6),
          Text(
            confirmed ? 'Đã xác nhận' : 'Chờ xác nhận',
            style: TextStyle(
              color: confirmed ? _primary : _muted,
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

  Widget _button(String label, VoidCallback onPressed) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: _primary,
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  Widget _outlineButton(
    BuildContext context,
    String label,
    RoomFlowMode next,
  ) => OutlinedButton(
    onPressed: () => _push(context, next),
    style: OutlinedButton.styleFrom(
      foregroundColor: _primary,
      side: const BorderSide(color: _primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(label),
  );

  void _push(BuildContext context, RoomFlowMode next) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RoomFlowScreen(post: post, mode: next),
      ),
    );
  }
}
