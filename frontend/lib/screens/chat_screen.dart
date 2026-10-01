import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../widgets/penpot_back_button.dart';

class ChatScreen extends StatefulWidget {
  final int? partnerId;
  final String? partnerName;
  final ApiService? apiService;

  const ChatScreen({
    super.key,
    this.partnerId,
    this.partnerName,
    this.apiService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isFetching = false;
  int _messageRevision = 0;
  bool _hasLoadedMessages = false;
  String? _loadError;
  bool get _hasPartner => widget.partnerId != null && widget.partnerId! > 0;
  bool _isSending = false;
  bool _isUploadingImage = false;
  Timer? _pollingTimer;

  final ImagePicker _picker = ImagePicker();
  XFile? _stagedImageFile;
  Uint8List? _stagedImageBytes;
  String? _stagedImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Polling định kỳ mỗi 3 giây để cập nhật tin nhắn mới
    if (_hasPartner) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) _fetchMessages(silent: true);
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (_isFetching || _isSending) return;
    final partnerId = widget.partnerId;
    if (!_hasPartner) {
      setState(() {
        _isLoading = false;
        _loadError = 'Không xác định được người nhận tin nhắn.';
      });
      return;
    }
    _isFetching = true;
    final revision = _messageRevision;
    if (!silent) setState(() => _isLoading = !_hasLoadedMessages);
    try {
      final list = await _api.getChatMessages(partnerId!);
      if (!mounted) return;
      // A response started before a successful send must not erase that message.
      if (revision != _messageRevision) return;
      final previousCount = _messages.length;
      setState(() {
        _messages = list;
        _isLoading = false;
        _hasLoadedMessages = true;
        _loadError = null;
      });

      // Nếu có tin nhắn mới, tự động cuộn xuống cuối
      if (list.length > previousCount) {
        _scrollToBottom();
      }
    } on ApiException catch (error) {
      _showLoadError(error.message);
    } catch (_) {
      _showLoadError('Không thể tải tin nhắn, vui lòng thử lại.');
    } finally {
      _isFetching = false;
    }
  }

  void _showLoadError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadError = message.trim().isNotEmpty
          ? message
          : 'Không thể tải tin nhắn, vui lòng thử lại.';
    });
  }

  Widget _buildLoadError() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_loadError!, textAlign: TextAlign.center),
        if (_hasLoadedMessages)
          const Text(
            'Đang hiển thị lịch sử đã tải trước đó.',
            textAlign: TextAlign.center,
          ),
        if (_hasPartner)
          TextButton(onPressed: _fetchMessages, child: const Text('Thử lại')),
      ],
    ),
  );

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

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _clearStagedImage() {
    setState(() {
      _stagedImageFile = null;
      _stagedImageBytes = null;
      _stagedImageUrl = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ảnh phải nhỏ hơn hoặc bằng 5 MB')),
        );
        return;
      }
      setState(() {
        _stagedImageFile = file;
        _stagedImageBytes = bytes;
        _stagedImageUrl = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e')));
    }
  }

  Future<void> _promptImageUrl() async {
    final urlCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Nhập link hình ảnh',
          style: TextStyle(
            fontFamily: 'SourceSansPro',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF087E6B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final link = urlCtrl.text.trim();
              if (link.isNotEmpty) {
                Navigator.pop(ctx, link);
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _stagedImageUrl = result;
        _stagedImageFile = null;
        _stagedImageBytes = null;
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Đính kèm hình ảnh',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF142523),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF8F5),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF087E6B),
                  ),
                ),
                title: const Text(
                  'Thư viện ảnh',
                  style: TextStyle(
                    fontFamily: 'SourceSansPro',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Chọn ảnh từ bộ nhớ thiết bị',
                  style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF8F5),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    color: Color(0xFF087E6B),
                  ),
                ),
                title: const Text(
                  'Chụp ảnh mới',
                  style: TextStyle(
                    fontFamily: 'SourceSansPro',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Mở máy ảnh để chụp ảnh phòng',
                  style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF8F5),
                  child: Icon(Icons.link_rounded, color: Color(0xFF087E6B)),
                ),
                title: const Text(
                  'Dán link ảnh (URL)',
                  style: TextStyle(
                    fontFamily: 'SourceSansPro',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Nhập liên kết hình ảnh trực tiếp',
                  style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _promptImageUrl();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final partnerId = widget.partnerId;
    final hasImage =
        _stagedImageBytes != null ||
        (_stagedImageUrl != null && _stagedImageUrl!.isNotEmpty);

    if ((text.isEmpty && !hasImage) || !_hasPartner || _isSending) return;

    setState(() => _isSending = true);

    String? finalImageUrl = _stagedImageUrl;

    // Upload local file if staged
    if (_stagedImageBytes != null && _stagedImageFile != null) {
      setState(() => _isUploadingImage = true);
      try {
        final ticket = await _api.uploadImage(
          bytes: _stagedImageBytes!,
          fileName: _stagedImageFile!.name,
          contentType: _contentType(_stagedImageFile!.name),
          purpose: 'chat',
        );
        finalImageUrl = ticket.publicUrl;
        if (!mounted) return;
        setState(() {
          _stagedImageUrl = finalImageUrl;
          _stagedImageFile = null;
        });
      } catch (uploadError) {
        if (!mounted) return;
        setState(() {
          _isSending = false;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể tải ảnh lên máy chủ: $uploadError. Bạn có thể chọn cách dán link ảnh.',
            ),
          ),
        );
        return;
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }

    try {
      final sent = await _api.sendChatMessage(
        receiverId: partnerId!,
        content: text.isNotEmpty ? text : '[Hình ảnh]',
        imageUrl: finalImageUrl,
      );
      if (!mounted) return;
      _messageController.clear();
      _clearStagedImage();
      setState(() {
        _messages.add(sent);
        _messageRevision++;
        _hasLoadedMessages = true;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể gửi tin nhắn: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _viewFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text(
                    'Không thể tải hình ảnh',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageAttachment(String imageUrl, {required bool isMe}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => _viewFullScreenImage(context, imageUrl),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 240, maxHeight: 240),
            color: Colors.black12,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 160,
                      color: isMe
                          ? const Color(0xFFD7EFEA)
                          : const Color(0xFFE2EBE8),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF087E6B),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_rounded,
                            color: Colors.grey,
                            size: 32,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Lỗi tải ảnh',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.zoom_in_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedMessage(ChatMessage msg) {
    final timeStr = DateFormat('HH:mm').format(msg.createdAt.toLocal());
    final hasImage = msg.imageUrl != null && msg.imageUrl!.isNotEmpty;
    final showText = msg.content.isNotEmpty && msg.content != '[Hình ảnh]';

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(10),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasImage) _buildImageAttachment(msg.imageUrl!, isMe: false),
                if (showText)
                  Padding(
                    padding: EdgeInsets.only(
                      left: 6,
                      right: 6,
                      top: hasImage ? 4 : 2,
                      bottom: 2,
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
              ],
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
    final hasImage = msg.imageUrl != null && msg.imageUrl!.isNotEmpty;
    final showText = msg.content.isNotEmpty && msg.content != '[Hình ảnh]';

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(10),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasImage) _buildImageAttachment(msg.imageUrl!, isMe: true),
                if (showText)
                  Padding(
                    padding: EdgeInsets.only(
                      left: 6,
                      right: 6,
                      top: hasImage ? 4 : 2,
                      bottom: 2,
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
              ],
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

  Widget _buildStagedImagePreview() {
    if (_stagedImageBytes == null &&
        (_stagedImageUrl == null || _stagedImageUrl!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF0F5F3),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 56,
              height: 56,
              color: Colors.grey.shade200,
              child: _stagedImageBytes != null
                  ? Image.memory(_stagedImageBytes!, fit: BoxFit.cover)
                  : Image.network(
                      _stagedImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _stagedImageFile != null
                      ? _stagedImageFile!.name
                      : 'Ảnh từ liên kết web',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SourceSansPro',
                    color: Color(0xFF142523),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _isUploadingImage
                      ? 'Đang chuẩn bị tải lên…'
                      : 'Sẵn sàng gửi kèm tin nhắn',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'SourceSansPro',
                    color: _isUploadingImage
                        ? const Color(0xFFE58B20)
                        : const Color(0xFF087E6B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF65746F)),
            onPressed: _isSending ? null : _clearStagedImage,
            tooltip: 'Hủy ảnh đính kèm',
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
                          'Trò chuyện',
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
            if (_loadError != null && _hasLoadedMessages) _buildLoadError(),

            // Chat List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null && !_hasLoadedMessages
                  ? Center(child: _buildLoadError())
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

            // Staged Image Preview
            _buildStagedImagePreview(),

            // Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 16, 12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: Color(0xFF087E6B),
                      size: 26,
                    ),
                    onPressed: _isSending || !_hasPartner
                        ? null
                        : _showImageOptions,
                    tooltip: 'Đính kèm hình ảnh',
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5F3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        enabled: _hasPartner,
                        readOnly: _isSending,
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText:
                              _stagedImageBytes != null ||
                                  (_stagedImageUrl != null &&
                                      _stagedImageUrl!.isNotEmpty)
                              ? 'Thêm chú thích ảnh…'
                              : 'Nhập tin nhắn…',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF65746F),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isSending || !_hasPartner ? null : _sendMessage,
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
