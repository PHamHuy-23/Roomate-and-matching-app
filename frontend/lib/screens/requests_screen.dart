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

  // Trạng thái SegmentedButton của Lời mời ghép đôi
  Set<String> _selectedMatchTab = {'received'};

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
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
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
              Text(
                'Đã mở khóa thông tin liên lạc (Double Opt-in):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            '📞 Số điện thoại: ${item.contactPhone ?? "Chưa có"}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          SelectableText(
            '✉️ Email: ${item.contactEmail ?? "Chưa có"}',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
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
          title: const Text('Quản Lý Lời Mời & Lịch Hẹn'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amberAccent,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Lời Mời Ghép Đôi'),
              Tab(icon: Icon(Icons.calendar_month), text: 'Lịch Hẹn Xem Phòng'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: LỜI MỜI GHÉP ĐÔI
            _buildMatchRequestsTab(),

            // TAB 2: LỊCH HẸN XEM PHÒNG
            _buildAppointmentsTab(),
          ],
        ),
      ),
    );
  }

  // ===== GIAO DIỆN TAB 1: LỜI MỜI GHÉP ĐÔI =====
  Widget _buildMatchRequestsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'received',
                label: Text('Lời mời nhận được'),
                icon: Icon(Icons.call_received),
              ),
              ButtonSegment(
                value: 'sent',
                label: Text('Lời mời đã gửi'),
                icon: Icon(Icons.call_made),
              ),
            ],
            selected: _selectedMatchTab,
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedMatchTab = newSelection;
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.indigo.shade100;
                }
                return Colors.transparent;
              }),
            ),
          ),
        ),
        Expanded(
          child: _selectedMatchTab.first == 'received'
              ? _buildReceivedRequests()
              : _buildSentRequests(),
        ),
      ],
    );
  }

  Widget _buildReceivedRequests() {
    return FutureBuilder<List<MatchRequestItem>>(
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
            return _buildMatchRequestCard(item, isReceived: true);
          },
        );
      },
    );
  }

  Widget _buildSentRequests() {
    return FutureBuilder<List<MatchRequestItem>>(
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
            return _buildMatchRequestCard(item, isReceived: false);
          },
        );
      },
    );
  }

  Widget _buildMatchRequestCard(
    MatchRequestItem item, {
    required bool isReceived,
  }) {
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
                  backgroundColor: isReceived
                      ? Colors.indigo.shade100
                      : Colors.grey.shade200,
                  child: Text(
                    item.partnerName.isNotEmpty ? item.partnerName[0] : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.partnerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Độ phù hợp: ${item.matchScore}%',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(item.status),
              ],
            ),
            _buildContactBox(item),
            if (isReceived && item.status == 'PENDING') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _api.respondMatchRequest(item.requestId, false);
                        _refresh();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
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
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Chấp nhận'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===== GIAO DIỆN TAB 2: LỊCH HẸN XEM PHÒNG (MOCK) =====
  Widget _buildAppointmentsTab() {
    // Dữ liệu giả định do Backend chưa triển khai API
    final mockAppointments = [
      {
        'roomName': 'Phòng trọ cao cấp gần ĐH Sư Phạm Kỹ Thuật',
        'address': '123 Võ Văn Ngân, TP. Thủ Đức',
        'dateTime': '15:30 Thứ Bảy, 19/09',
        'status': 'PENDING',
        'note': 'Nhớ gọi trước khi qua 30 phút.',
      },
      {
        'roomName': 'Phòng có máy lạnh, giờ giấc tự do',
        'address': '45 Nguyễn Văn Bá, Bình Thạnh',
        'dateTime': '09:00 Chủ Nhật, 20/09',
        'status': 'CONFIRMED',
        'note': '',
      },
      {
        'roomName': 'Ký túc xá sinh viên',
        'address': '10 Lê Văn Việt, TP. Thủ Đức',
        'dateTime': '10:00 Thứ Ba, 15/09',
        'status': 'COMPLETED',
        'note': 'Đã xem phòng và đặt cọc.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: mockAppointments.length,
      itemBuilder: (context, i) {
        final apt = mockAppointments[i];

        Color statusColor;
        String statusText;
        switch (apt['status']) {
          case 'CONFIRMED':
            statusColor = Colors.green;
            statusText = 'Đã xác nhận lịch';
            break;
          case 'COMPLETED':
            statusColor = Colors.blue;
            statusText = 'Đã xong';
            break;
          default:
            statusColor = Colors.orange;
            statusText = 'Chờ chủ nhà xác nhận';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Name & Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        apt['roomName']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Details
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        apt['address']!,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      apt['dateTime']!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if ((apt['note'] as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ghi chú: ${apt['note']}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                // Actions
                if (apt['status'] == 'PENDING')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tính năng Hủy lịch hẹn sẽ được kết nối ở GĐ4.',
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Hủy lịch hẹn'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tính năng Xác nhận lịch hẹn sẽ được kết nối ở GĐ4.',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Xác nhận lịch hẹn'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
