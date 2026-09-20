import 'package:flutter/material.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, this.contactName = 'Minh Anh'});

  final String contactName;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationMessage {
  const _ConversationMessage({required this.text, required this.fromMe, this.status});

  final String text;
  final bool fromMe;
  final String? status;
}

class _ConversationScreenState extends State<ConversationScreen> {
  static const _canvas = Color(0xFFF5F8F7);
  static const _ink = Color(0xFF142523);
  static const _muted = Color(0xFF65746F);
  static const _primary = Color(0xFF087E6B);
  static const _soft = Color(0xFFE8F4F1);

  final _messageCtrl = TextEditingController();
  final _messages = <_ConversationMessage>[
    const _ConversationMessage(text: 'Chào Huy! Bạn muốn xem phòng\nvào chiều thứ Hai phải không?', fromMe: false),
    const _ConversationMessage(text: 'Đúng rồi, khoảng 14:00 nhé.', fromMe: true),
    const _ConversationMessage(text: 'Phòng có chỗ để xe không bạn?', fromMe: false),
    const _ConversationMessage(text: 'Có nhé, mình gửi thêm ảnh cho bạn.', fromMe: true, status: '14:24 · Đã xem'),
  ];

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final value = _messageCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _messages.add(_ConversationMessage(text: value, fromMe: true));
      _messageCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        foregroundColor: _ink,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contactName, style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            const Text('Đã kết nối · Trao đổi về phòng trọ', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                const Center(child: Text('HÔM NAY · 14:20', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .4))),
                const SizedBox(height: 18),
                for (final message in _messages) _MessageBubble(message: message),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn…',
                        hintStyle: const TextStyle(color: _muted),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFDCE6E3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFDCE6E3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: _primary, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: FilledButton(
                      onPressed: _send,
                      style: FilledButton.styleFrom(backgroundColor: _primary, padding: EdgeInsets.zero, shape: const CircleBorder()),
                      child: const Icon(Icons.arrow_upward_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: message.fromMe ? _ConversationScreenState._soft : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(message.fromMe ? 16 : 4),
          bottomRight: Radius.circular(message.fromMe ? 4 : 16),
        ),
      ),
      child: Text(message.text, style: const TextStyle(color: _ConversationScreenState._ink, height: 1.35)),
    );

    return Align(
      alignment: message.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: message.fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            bubble,
            if (message.status != null) ...[
              const SizedBox(height: 4),
              Text(message.status!, style: const TextStyle(color: _ConversationScreenState._muted, fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }
}
