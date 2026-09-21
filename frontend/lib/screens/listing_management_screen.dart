import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/room_post.dart';
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
    super.key,
  });

  final ListingFlowMode mode;
  final int authorId;
  final List<RoomPost> posts;

  @override
  State<ListingManagementScreen> createState() => _ListingManagementScreenState();
}

class _ListingManagementScreenState extends State<ListingManagementScreen> {
  static const _canvas = Color(0xFFF5F8F7);
  static const _primary = Color(0xFF087E6B);
  static const _ink = Color(0xFF142523);
  static const _muted = Color(0xFF65746F);
  static const _soft = Color(0xFFE8F4F1);
  static const _border = Color(0xFFDCE6E3);
  static const _amenityOptions = <String>[
    'Máy lạnh',
    'Bếp riêng',
    'Giữ xe',
    'Wi-Fi',
    'Nội thất',
    'Máy giặt',
  ];

  late ListingFlowMode _mode;
  final List<ListingFlowMode> _history = <ListingFlowMode>[];
  late bool _editingExisting;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _depositCtrl;
  late final TextEditingController _utilityCtrl;
  late final TextEditingController _descriptionCtrl;
  DateTime _availableDate = DateTime(2026, 10, 1);
  double _area = 28;
  int _maxOccupants = 2;
  int _photoCount = 4;
  String _roomStatus = 'Còn phòng';
  final Set<String> _amenities = Set<String>.from(_amenityOptions);

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _editingExisting = widget.mode == ListingFlowMode.edit;
    final post = widget.posts.isEmpty ? null : widget.posts.first;
    _titleCtrl = TextEditingController(text: post?.title ?? 'Studio ngập nắng, có ban công');
    _addressCtrl = TextEditingController(text: post?.address ?? 'Nguyễn Gia Trí, Bình Thạnh, TP.HCM');
    _priceCtrl = TextEditingController(text: post == null ? '3.500.000đ' : '${_formatMoney(post.price)}đ');
    _depositCtrl = TextEditingController(text: '3.500.000đ · 1 tháng');
    _utilityCtrl = TextEditingController(text: '3.800đ / kWh · 100.000đ / người · 150.000đ');
    _descriptionCtrl = TextEditingController(text: post?.description ?? 'Ban công riêng, đủ nội thất, bếp nhỏ');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _depositCtrl.dispose();
    _utilityCtrl.dispose();
    _descriptionCtrl.dispose();
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
        return 'Đã nhận báo cáo';
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
        const Text('Quản lý phòng và yêu cầu xem phòng', style: TextStyle(color: _muted, height: 1.5)),
        const SizedBox(height: 18),
        if (widget.posts.isEmpty)
          _emptyState(context, Icons.post_add_outlined, 'Bạn chưa có tin đăng nào', 'Tạo tin đầu tiên để tìm người ở ghép phù hợp.')
        else
          ...widget.posts.map((post) => _postCard(context, post)),
        const SizedBox(height: 18),
        _button('+ Đăng phòng mới', () => _goTo(ListingFlowMode.create)),
      ],
    );
  }

  Widget _postCard(BuildContext context, RoomPost post) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[Expanded(child: Text(post.title, style: const TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w800))), _statusBadge('ĐANG HIỂN THỊ')]),
            const SizedBox(height: 7),
            Text('${_formatMoney(post.price)}đ / tháng · 28 m²', style: const TextStyle(color: _muted)),
            const SizedBox(height: 3),
            Text(post.address, style: const TextStyle(color: _muted, fontSize: 13)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(onPressed: () { _editingExisting = true; _goTo(ListingFlowMode.edit); }, child: const Text('Chỉnh sửa tin đăng')),
                OutlinedButton(onPressed: () => _goTo(ListingFlowMode.viewingRequest), child: const Text('Yêu cầu xem phòng · 1')),
                TextButton(onPressed: () => _goTo(ListingFlowMode.close), child: const Text('Đóng tin đăng')),
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
        _stageHeader('1 / 3 · Thông tin cơ bản', 'Bắt đầu bằng những thông tin người xem cần biết.'),
        _input('Tiêu đề bài đăng', _titleCtrl, hint: 'Studio ngập nắng, có ban công'),
        _input('Địa chỉ / khu vực', _addressCtrl, hint: 'Nguyễn Gia Trí, Bình Thạnh, TP.HCM'),
        Row(children: <Widget>[
          Expanded(child: _numberInput('Diện tích', '${_area.toStringAsFixed(0)} m²', () => setState(() => _area = _area >= 60 ? 18 : _area + 2))),
          const SizedBox(width: 12),
          Expanded(child: _numberInput('Số người tối đa', '$_maxOccupants người', () => setState(() => _maxOccupants = _maxOccupants >= 6 ? 1 : _maxOccupants + 1))),
        ]),
        _dateField(),
        const SizedBox(height: 6),
        _button('Tiếp tục · Ảnh & tiện ích', () => _goTo(ListingFlowMode.photosAmenities)),
      ],
    );
  }

  Widget _photos(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _stageHeader('2 / 3 · Giúp người xem hiểu căn phòng', 'Hình ảnh rõ ràng giúp tin đăng đáng tin cậy hơn.'),
        const SizedBox(height: 14),
        const Text('Ảnh bìa', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => setState(() => _photoCount = _photoCount >= 10 ? 1 : _photoCount + 1),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 164,
            width: double.infinity,
            decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
            child: const Center(child: Icon(Icons.add_photo_alternate_outlined, color: _primary, size: 52)),
          ),
        ),
        const SizedBox(height: 8),
        Text('$_photoCount / 10 ảnh · JPG, PNG · Tối đa 5 MB / ảnh', style: const TextStyle(color: _muted, fontSize: 13)),
        const SizedBox(height: 20),
        const Text('Tiện ích có sẵn', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
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
              onSelected: (value) => setState(() => value ? _amenities.add(amenity) : _amenities.remove(amenity)),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text('Chọn ảnh bìa rõ, đủ sáng và đúng thực tế.', style: TextStyle(color: _muted, height: 1.4)),
        const SizedBox(height: 24),
        _button('Tiếp tục · Giá & nội quy', () => _goTo(ListingFlowMode.priceRules)),
      ],
    );
  }

  Widget _priceRules(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _stageHeader('3 / 3 · Minh bạch trước khi kết nối', 'Nêu rõ chi phí và nguyên tắc sống chung.'),
        _input('Tiền thuê / tháng', _priceCtrl, keyboard: TextInputType.number, hint: '3.500.000đ'),
        _input('Tiền cọc', _depositCtrl, hint: '3.500.000đ · 1 tháng'),
        _input('Điện / nước / phí dịch vụ', _utilityCtrl, hint: '3.800đ / kWh · 100.000đ / người · 150.000đ'),
        _infoCard(Icons.rule_outlined, 'Nội quy', 'Không hút thuốc · Yên tĩnh sau 23h'),
        const SizedBox(height: 24),
        _button('Xem trước tin đăng', () => _goTo(ListingFlowMode.preview)),
      ],
    );
  }

  Widget _preview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(height: 180, decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(16)), child: const Center(child: Icon(Icons.home_work_outlined, color: _primary, size: 62))),
        const SizedBox(height: 18),
        Text(_titleCtrl.text.trim(), style: const TextStyle(color: _ink, fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('${_addressCtrl.text.trim()} · ${_area.toStringAsFixed(0)} m² · Tối đa $_maxOccupants người', style: const TextStyle(color: _muted)),
        const SizedBox(height: 14),
        _previewRow('Giá thuê', '${_priceCtrl.text.trim()} / tháng'),
        _previewRow('Tiền cọc', 'Cọc 1 tháng · Có nội thất'),
        _previewRow('Chi phí', 'Điện, nước và phí dịch vụ tính riêng'),
        _previewRow('Mô tả', _descriptionCtrl.text.trim()),
        const SizedBox(height: 10),
        const Text('Kiểm tra kỹ thông tin trước khi gửi', style: TextStyle(color: _muted, height: 1.4)),
        const SizedBox(height: 24),
        _button(_editingExisting ? 'Lưu & gửi kiểm duyệt' : 'Gửi tin để duyệt', () => _goTo(ListingFlowMode.submitted)),
      ],
    );
  }

  Widget _editForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _infoCard(Icons.home_work_outlined, 'Studio ngập nắng · RH-028', 'Thông tin đang hiển thị trên tin đăng của bạn.'),
        const SizedBox(height: 14),
        _input('Tiêu đề', _titleCtrl),
        _input('Giá thuê / tháng', _priceCtrl, keyboard: TextInputType.number),
        DropdownButtonFormField<String>(
          initialValue: _roomStatus,
          decoration: _fieldDecoration('Trạng thái phòng'),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem(value: 'Còn phòng', child: Text('Còn phòng')),
            DropdownMenuItem(value: 'Đã có người', child: Text('Đã có người')),
          ],
          onChanged: (value) => setState(() => _roomStatus = value ?? _roomStatus),
        ),
        const SizedBox(height: 14),
        _input('Mô tả', _descriptionCtrl, maxLines: 4),
        const SizedBox(height: 6),
        _button('Lưu & gửi kiểm duyệt', () => _goTo(ListingFlowMode.submitted)),
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
      action: _button('Về tin đăng của tôi', () => _goTo(ListingFlowMode.myListings)),
    );
  }

  Widget _viewingRequest(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Lịch hẹn tại phòng bạn đang đăng', style: TextStyle(color: _muted, height: 1.5)),
        const SizedBox(height: 16),
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              const Text('Quang Huy · 21 / 09, 14:00', style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _statusBadge('Chờ xác nhận · 2 người xem'),
              const SizedBox(height: 14),
              const Text('“Mình muốn xem phòng cùng một người bạn.”', style: TextStyle(color: _muted, height: 1.4)),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                FilledButton(onPressed: () => _goTo(ListingFlowMode.confirmedViewing), style: FilledButton.styleFrom(backgroundColor: _primary), child: const Text('Xác nhận lịch hẹn')),
                OutlinedButton(onPressed: () => _goTo(ListingFlowMode.myListings), child: const Text('Từ chối / hủy lịch')),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Kiểm tra thông tin lịch hẹn, trao đổi điểm hẹn và chuẩn bị trước khi đón khách.', style: TextStyle(color: _muted, height: 1.4)),
      ],
    );
  }

  Widget _reportReceived(BuildContext context) {
    return _emptyState(
      context,
      Icons.check_circle_outline,
      'Cảm ơn bạn đã phản hồi',
      'Báo cáo #BC-028 đang chờ xem xét. Bạn sẽ nhận thông báo khi có kết quả.',
      action: _button('Về hồ sơ', () => Navigator.maybePop(context)),
    );
  }

  Widget _confirmedViewing(BuildContext context) {
    return _emptyState(
      context,
      Icons.check_circle_outline,
      'Hẹn gặp tại căn phòng!',
      'Quang Huy · 21 / 09 / 2026 · 14:00',
      action: _button('Quản lý tin đăng', () => _goTo(ListingFlowMode.myListings)),
    );
  }

  Widget _close(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 24),
        const Text('Bạn đã tìm được người thuê?', style: TextStyle(color: _ink, fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const Text('Tin sẽ ngừng xuất hiện trong danh sách. Hãy xử lý các lịch xem phòng đang chờ trước khi đóng.', style: TextStyle(color: _muted, height: 1.5)),
        const SizedBox(height: 26),
        _button('Xác nhận đóng tin', () => _goTo(ListingFlowMode.closed)),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _handleBack, child: const Text('Giữ tin đăng'))),
      ],
    );
  }

  Widget _closed(BuildContext context) {
    return _emptyState(
      context,
      Icons.check_circle_outline,
      'Căn phòng đã ngừng hiển thị',
      'Bạn vẫn có thể xem lại nội dung và đăng tin mới khi có phòng.',
      action: _button('Về tin đăng của tôi', () => _goTo(ListingFlowMode.myListings)),
    );
  }

  Widget _stageHeader(String label, String helper) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(label, style: const TextStyle(color: _primary, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(helper, style: const TextStyle(color: _muted, height: 1.4)),
      ]),
    );
  }

  Widget _numberInput(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(decoration: _fieldDecoration(label), child: Text(value, style: const TextStyle(color: _ink))),
      ),
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(context: context, firstDate: DateTime(2026), lastDate: DateTime(2030), initialDate: _availableDate);
        if (selected != null) setState(() => _availableDate = selected);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: InputDecorator(decoration: _fieldDecoration('Ngày có thể nhận phòng').copyWith(suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18)), child: Text(DateFormat('dd / MM / yyyy').format(_availableDate))),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller, {TextInputType? keyboard, int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(controller: controller, keyboardType: keyboard, maxLines: maxLines, decoration: _fieldDecoration(label, hint: hint)),
    );
  }

  InputDecoration _fieldDecoration(String label, {String? hint, Widget? suffixIcon}) {
    return InputDecoration(labelText: label, hintText: hint, suffixIcon: suffixIcon, filled: true, fillColor: Colors.white, labelStyle: const TextStyle(color: _muted), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)));
  }

  Widget _infoCard(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Icon(icon, color: _primary),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: _muted, height: 1.35))])),
      ]),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[SizedBox(width: 104, child: Text(label, style: const TextStyle(color: _muted))), Expanded(child: Text(value, style: const TextStyle(color: _ink, fontWeight: FontWeight.w600)))]));
  }

  Widget _statusBadge(String text) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(30)), child: Text(text, style: const TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w800)));
  }

  Widget _emptyState(BuildContext context, IconData icon, String title, String description, {Widget? action, String? badge}) {
    return Column(children: <Widget>[
      const SizedBox(height: 38),
      Icon(icon, color: _primary, size: 64),
      const SizedBox(height: 16),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w800)),
      if (badge != null) ...<Widget>[const SizedBox(height: 10), _statusBadge(badge)],
      const SizedBox(height: 10),
      Text(description, textAlign: TextAlign.center, style: const TextStyle(color: _muted, height: 1.5)),
      if (action != null) ...<Widget>[const SizedBox(height: 24), action],
    ]);
  }

  Widget _button(String label, VoidCallback onPressed) {
    return SizedBox(width: double.infinity, child: FilledButton(onPressed: onPressed, style: FilledButton.styleFrom(backgroundColor: _primary, minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))));
  }

  String _formatMoney(num value) => NumberFormat('#,###', 'en_US').format(value).replaceAll(',', '.');
}
