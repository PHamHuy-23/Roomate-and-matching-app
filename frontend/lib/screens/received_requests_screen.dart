import 'package:flutter/material.dart';

import '../models/match_request_item.dart';
import '../services/api_service.dart';
import '../widgets/penpot_back_button.dart';

/// Displays pending requests from the authenticated user's account.
///
/// The Penpot screen is still used for the visual layout, but the list and
/// accept/reject actions now come from the match-request API instead of a
/// hard-coded sample user.
class ReceivedRequestsScreen extends StatefulWidget {
  final int? currentUserId;

  const ReceivedRequestsScreen({super.key, this.currentUserId});

  @override
  State<ReceivedRequestsScreen> createState() => _ReceivedRequestsScreenState();
}

class _ReceivedRequestsScreenState extends State<ReceivedRequestsScreen> {
  final ApiService _api = ApiService();
  List<MatchRequestItem> _requests = const [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.currentUserId != null) {
      _loadRequests();
    } else {
      _error = 'Không xác định được tài khoản hiện tại.';
    }
  }

  Future<void> _loadRequests() async {
    final userId = widget.currentUserId;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final requests = await _api.getReceivedRequests(userId);
      if (!mounted) return;
      setState(() {
        _requests = requests.where((item) => item.status == 'PENDING').toList();
        _isLoading = false;
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
        _error = 'Không thể tải lời mời, vui lòng thử lại.';
      });
    }
  }

  Future<void> _respond(MatchRequestItem request, bool accept) async {
    try {
      await _api.respondMatchRequest(request.requestId, accept);
      if (!mounted) return;
      setState(() => _requests.removeWhere((item) => item.requestId == request.requestId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Đã chấp nhận kết nối.' : 'Đã từ chối lời mời.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể phản hồi lời mời, vui lòng thử lại.')),
      );
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
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  const PenpotBackButton(),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lời mời đã nhận',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF142523),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Bạn quyết định ai có thể kết nối',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF65746F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tải lại',
                    onPressed: _isLoading ? null : _loadRequests,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
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
              OutlinedButton(onPressed: _loadRequests, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (_requests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Bạn chưa có lời mời kết nối nào.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF65746F)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      itemCount: _requests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 18),
      itemBuilder: (_, index) => _buildRequestCard(_requests[index]),
    );
  }

  Widget _buildRequestCard(MatchRequestItem request) {
    final score = request.matchScore.toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                      request.partnerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SourceSansPro',
                        color: Color(0xFF142523),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$score% phù hợp${request.createdAt == null ? '' : ' · ${_formatDate(request.createdAt!)}'}',
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
        if (request.contactEmail != null || request.contactPhone != null) ...[
          const SizedBox(height: 12),
          Text(
            [request.contactEmail, request.contactPhone].whereType<String>().join(' · '),
            style: const TextStyle(color: Color(0xFF65746F)),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _respond(request, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF087E6B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Chấp nhận kết nối'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _respond(request, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF087E6B),
                  side: const BorderSide(color: Color(0xFF087E6B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Từ chối'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final local = date.toLocal();
    return '${local.day}/${local.month}';
  }
}
