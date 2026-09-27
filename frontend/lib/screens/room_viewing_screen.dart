import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/room_post.dart';

class RoomViewingScreen extends StatefulWidget {
  const RoomViewingScreen({required this.post, super.key});

  final RoomPost post;

  @override
  State<RoomViewingScreen> createState() => _RoomViewingScreenState();
}

class _RoomViewingScreenState extends State<RoomViewingScreen> {
  static const _canvas = Color(0xFFF5F8F7);
  static const _primary = Color(0xFF087E6B);
  static const _ink = Color(0xFF142523);
  static const _muted = Color(0xFF52625F);
  late DateTime _selectedDate;
  String? _selectedTime;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    // Keep the same sample week as the Penpot prototype while still allowing
    // the user to choose another day in the flow.
    _selectedDate = DateTime(2026, 9, 21);
    _messageController = TextEditingController(
      text: 'Mình muốn xem phòng cùng một người bạn.',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  List<DateTime> get _dates =>
      List.generate(5, (index) => DateTime(2026, 9, 20 + index));

  void _submit() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khung giờ xem phòng.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đặt lịch đang chờ API backend.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthlyPrice = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(widget.post.price);
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Đặt lịch xem phòng'),
        backgroundColor: _canvas,
        foregroundColor: _ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text(
            'Chọn thời gian phù hợp với bạn',
            style: TextStyle(color: _muted, fontSize: 15),
          ),
          const SizedBox(height: 22),
          Text(
            widget.post.title,
            style: const TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.post.address} • $monthlyPrice/tháng',
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 26),
          const Text(
            'Tháng 9, 2026',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final date = _dates[index];
                final selected = DateUtils.isSameDay(date, _selectedDate);
                return InkWell(
                  onTap: () => setState(() => _selectedDate = date),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? _primary : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? _primary : const Color(0xFFDCE6E3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekday(date.weekday),
                          style: TextStyle(
                            color: selected ? Colors.white : _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: selected ? Colors.white : _ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Khung giờ',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['09:00', '10:30', '14:00', '16:30'].map((time) {
              final selected = time == _selectedTime;
              return ChoiceChip(
                selected: selected,
                label: Text(time),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _ink,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: _primary,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected ? _primary : const Color(0xFFDCE6E3),
                ),
                onSelected: (_) => setState(() => _selectedTime = time),
              );
            }).toList(),
          ),
          const SizedBox(height: 26),
          const Text(
            'Lời nhắn cho người đăng',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDCE6E3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDCE6E3)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Lịch chỉ được xác nhận khi người đăng đồng ý.\nBạn có thể hủy trong mục Lịch xem phòng.',
            style: TextStyle(color: _muted, height: 1.5),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Gửi yêu cầu xem phòng',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  String _weekday(int weekday) {
    const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return names[weekday - 1];
  }
}
