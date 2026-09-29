import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../widgets/penpot_back_button.dart';

class ChatScreen extends StatefulWidget {
  final int? partnerId;
  final String? partnerName;

  const ChatScreen({super.key, this.partnerId, this.partnerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Polling định kỳ mỗi 3 giây để cập nhật tin nhắn mới
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _fetchMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    final partnerId = widget.partnerId;
    if (partnerId == null) {
      if (!silent && mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final list = await _api.getChatMessages(partnerId);
      if (!mounted) return;
      final previousCount = _messages.length;
      setState(() {
        _messages = list;
        _isLoading = false;
      });

      // Nếu có tin nhắn mới, tự động cuộn xuống cuối
      if (list.length > previousCount) {
        _scrollToBottom();
      }
    } catch (_) {
      if (!silent && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final partnerId = widget.partnerId;
    if (text.isEmpty || partnerId == null || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final sent = await _api.sendChatMessage(
        receiverId: partnerId,
        content: text,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(sent);
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi tin nhắn: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildReceivedMessage(ChatMessage msg) {
    final timeStr = DateFormat('HH:mm').format(msg.createdAt.toLocal());
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Text(
              msg.content,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: 'SourceSansPro',
                color: Color(0xFF142523),
                height: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              timeStr,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF65746F),
                fontFamily: 'SourceSansPro',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentMessage(ChatMessage msg) {
    final timeStr = DateFormat('HH:mm').format(msg.createdAt.toLocal());
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF8F5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              msg.content,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: 'SourceSansPro',
                color: Color(0xFF142523),
                height: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 12),
            child: Text(
              '$timeStr · Đã gửi',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF65746F),
                fontFamily: 'SourceSansPro',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.partnerName ?? 'Người dùng Roommate Hub';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar area
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Row(
                children: [
                  const PenpotBackButton(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF142523),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Đã kết nối · Trực tuyến',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF087E6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2EBE8)),

            // Chat List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Hãy gửi lời chào tới $name!',
                                style: const TextStyle(
                                  color: Color(0xFF65746F),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            if (msg.fromMe) {
                              return _buildSentMessage(msg);
                            } else {
                              return _buildReceivedMessage(msg);
                            }
                          },
                        ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5F3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Nhập tin nhắn…',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF65746F),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF087E6B),
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
