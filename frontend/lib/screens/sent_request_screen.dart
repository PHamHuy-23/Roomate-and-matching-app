import 'package:flutter/material.dart';

import '../models/match_request_item.dart';
import '../services/api_service.dart';
import '../widgets/penpot_back_button.dart';

class SentRequestScreen extends StatefulWidget {
  final int? currentUserId;
  final int? partnerId;
  final String? partnerName;
  final ApiService? apiService;

  const SentRequestScreen({
    super.key,
    this.currentUserId,
    this.partnerId,
    this.partnerName,
    this.apiService,
  });

  @override
  State<SentRequestScreen> createState() => _SentRequestScreenState();
}

class _SentRequestScreenState extends State<SentRequestScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  MatchRequestItem? _request;
  bool _isLoading = false;
  bool _isCancelling = false;
  String? _error;
  String get _statusLabel => switch (_request?.status) {
    'PENDING' => 'Đang chờ phản hồi',
    'ACCEPTED' => 'Đã kết nối',
    'REJECTED' => 'Đã từ chối',
    _ => '',
  };

  Future<void> _handleCancelRequest() async {
    if (_request?.status != 'PENDING' || _isCancelling) return;
    final targetId = widget.partnerId ?? _request?.partnerId;
    if (targetId == null) {
      Navigator.pop(context, true);
      return;
    }

    setState(() => _isCancelling = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      await _api.cancelSentRequest(targetId);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã hủy lời mời kết nối thành công.'),
          backgroundColor: Color(0xFF087E6B),
        ),
      );
      nav.pop(true);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    final userId = widget.currentUserId;
    if (userId == null) {
      setState(() => _error = 'Không xác định được tài khoản hiện tại.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final requests = await _api.getSentRequests(userId);
      final matching = widget.partnerId == null
          ? requests
          : requests.where((item) => item.partnerId == widget.partnerId);
      if (!mounted) return;
      setState(() {
        _request = matching.isEmpty ? null : matching.first;
        _isLoading = false;
        if (_request == null) {
          _error = 'Không tìm thấy lời mời đang chờ phản hồi.';
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không thể tải lời mời đã gửi, vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  const PenpotBackButton(),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Lời mời đã gửi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'SourceSansPro',
                        color: Color(0xFF142523),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tải lại',
                    onPressed: _isLoading ? null : _loadRequest,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _statusLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'SourceSansPro',
                    color: Color(0xFF65746F),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: Color(0xFF65746F),
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadRequest,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final request = _request!;
    final name = request.partnerName.isEmpty
        ? (widget.partnerName ?? 'Người dùng Roommate Hub')
        : request.partnerName;
    final score = request.matchScore.toStringAsFixed(0);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: request.partnerAvatar == null
                    ? null
                    : NetworkImage(request.partnerAvatar!),
                child: request.partnerAvatar == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SourceSansPro',
                        color: Color(0xFF142523),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$score% phù hợp · $_statusLabel',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'SourceSansPro',
                        color: Color(0xFF65746F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          switch (request.status) {
            'ACCEPTED' => 'Hai bạn đã kết nối. Xem liên hệ tại mục Kết nối.',
            'REJECTED' => '$name đã từ chối lời mời kết nối.',
            'PENDING' => 'Lời mời đang chờ $name phản hồi.',
            _ => 'Trạng thái lời mời chưa được hỗ trợ.',
          },
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'SourceSansPro',
            color: Color(0xFF142523),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 48),
        if (request.status == 'PENDING')
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isCancelling ? null : _handleCancelRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAF8F5),
                foregroundColor: const Color(0xFF087E6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isCancelling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF087E6B),
                      ),
                    )
                  : const Text('Hủy lời mời'),
            ),
          ),
      ],
    );
  }
}
