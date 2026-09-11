import 'package:flutter/material.dart';
import '../models/match_request_item.dart';
import '../services/api_service.dart';

class RequestsScreen extends StatefulWidget {
  final int currentUserId;
  const RequestsScreen({super.key, required this.currentUserId});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final ApiService _api = ApiService();
  late Future<List<MatchRequestItem>> _receivedFuture;
  late Future<List<MatchRequestItem>> _sentFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _receivedFuture = _api.getReceivedRequests(widget.currentUserId);
      _sentFuture = _api.getSentRequests(widget.currentUserId);
    });
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    String text;
    switch (status) {
      case 'ACCEPTED':
        bg = Colors.green;
        text = 'Đã chấp nhận';
        break;
      case 'REJECTED':
        bg = Colors.red;
        text = 'Đã từ chối';
        break;
      default:
        bg = Colors.orange;
        text = 'Đang chờ';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildContactBox(MatchRequestItem item) {
    if (item.status != 'ACCEPTED') return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_open, size: 16, color: Colors.green),
              SizedBox(width: 6),
              Text('Đã mở khóa thông tin liên lạc (Double Opt-in):',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText('📞 Số điện thoại: ${item.contactPhone ?? "Chưa có"}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          SelectableText('✉️ Email: ${item.contactEmail ?? "Chưa có"}',
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hộp Thư Yêu Cầu Kết Nối'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amberAccent,
            tabs: [
              Tab(icon: Icon(Icons.call_received), text: 'Lời Mời Nhận Được'),
              Tab(icon: Icon(Icons.call_made), text: 'Lời Mời Đã Gửi'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: LỜI MỜI NHẬN ĐƯỢC
            FutureBuilder<List<MatchRequestItem>>(
              future: _receivedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text('Bạn chưa nhận được lời mời nào.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final item = list[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.indigo.shade100,
                                  child: Text(item.partnerName.isNotEmpty ? item.partnerName[0] : '?'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.partnerName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('Độ phù hợp: ${item.matchScore}%',
                                          style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                _buildStatusBadge(item.status),
                              ],
                            ),
                            _buildContactBox(item),
                            if (item.status == 'PENDING') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await _api.respondMatchRequest(item.requestId, false);
                                        _refresh();
                                      },
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Từ chối'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await _api.respondMatchRequest(item.requestId, true);
                                        _refresh();
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      child: const Text('Chấp nhận'),
                                    ),
                                  ),
                                ],
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // TAB 2: LỜI MỜI ĐÃ GỬI
            FutureBuilder<List<MatchRequestItem>>(
              future: _sentFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text('Bạn chưa gửi lời mời kết nối nào.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final item = list[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.grey.shade200,
                                  child: Text(item.partnerName.isNotEmpty ? item.partnerName[0] : '?'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.partnerName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('Độ phù hợp: ${item.matchScore}%',
                                          style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                _buildStatusBadge(item.status),
                              ],
                            ),
                            _buildContactBox(item),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}