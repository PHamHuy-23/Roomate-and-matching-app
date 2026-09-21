import 'package:flutter/material.dart';

import '../models/match_request_item.dart';
import '../services/api_service.dart';
import '../widgets/penpot_back_button.dart';

class SentRequestScreen extends StatefulWidget {
  final int? currentUserId;
  final int? partnerId;
  final String? partnerName;

  const SentRequestScreen({
    super.key,
    this.currentUserId,
    this.partnerId,
    this.partnerName,
  });

  @override
  State<SentRequestScreen> createState() => _SentRequestScreenState();
}

class _SentRequestScreenState extends State<SentRequestScreen> {
  final ApiService _api = ApiService();
  MatchRequestItem? _request;
  bool _isLoading = false;
  String? _error;

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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Đang chờ phản hồi',
                  style: TextStyle(
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
              const Icon(Icons.cloud_off_outlined, size: 42, color: Color(0xFF65746F)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _loadRequest, child: const Text('Thử lại')),
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
                      '$score% phù hợp · Chờ chấp nhận',
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
          'Bạn sẽ nhận thông báo khi $name phản hồi.',
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'SourceSansPro',
            color: Color(0xFF142523),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Hủy lời mời sẽ khả dụng khi backend bổ sung API.',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEAF8F5),
              foregroundColor: const Color(0xFF087E6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Hủy lời mời'),
          ),
        ),
      ],
    );
  }
}
