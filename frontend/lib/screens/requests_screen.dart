import 'package:flutter/material.dart';
import '../models/match_request_item.dart';
import '../services/api_service.dart';
import '../navigation/app_routes.dart';

class RequestsScreen extends StatefulWidget {
  final int currentUserId;
  const RequestsScreen({super.key, required this.currentUserId});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final ApiService _api = ApiService();
  
  List<MatchRequestItem> _receivedRequests = [];
  List<MatchRequestItem> _sentRequests = [];
  bool _isLoading = true;
  
  // 0: Đã kết nối, 1: Đã nhận, 2: Đã gửi
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final received = await _api.getReceivedRequests(widget.currentUserId);
      final sent = await _api.getSentRequests(widget.currentUserId);
      
      if (mounted) {
        setState(() {
          _receivedRequests = received;
          _sentRequests = sent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF8F5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'SourceSansPro',
            color: isSelected ? const Color(0xFF087E6B) : const Color(0xFF65746F),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionItem({
    required String name,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                color: Colors.grey.shade300,
                child: const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
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
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingReceived = _receivedRequests.where((r) => r.status == 'PENDING').toList();
    final pendingSent = _sentRequests.where((r) => r.status == 'PENDING').toList();
    
    final connected = [
      ..._receivedRequests.where((r) => r.status == 'ACCEPTED'),
      ..._sentRequests.where((r) => r.status == 'ACCEPTED'),
    ];

    List<MatchRequestItem> currentList = [];
    if (_selectedTabIndex == 0) currentList = connected;
    else if (_selectedTabIndex == 1) currentList = pendingReceived;
    else currentList = pendingSent;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Kết nối của bạn',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF142523),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Những cuộc trò chuyện bắt đầu ở đây',
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
            
            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildFilterChip(0, 'Đã kết nối'),
                  _buildFilterChip(1, pendingReceived.isNotEmpty ? 'Đã nhận · ${pendingReceived.length}' : 'Đã nhận'),
                  _buildFilterChip(2, pendingSent.isNotEmpty ? 'Đã gửi · ${pendingSent.length}' : 'Đã gửi'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // List
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        if (currentList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'Không có kết nối nào',
                                style: TextStyle(
                                  color: Color(0xFF65746F),
                                ),
                              ),
                            ),
                          ),
                          
                        ...currentList.map((item) {
                          String subtitle = '';
                          if (_selectedTabIndex == 0) subtitle = 'Đã kết nối · Xem thông tin liên hệ';
                          else if (_selectedTabIndex == 1) subtitle = 'Lời mời mới · ${item.matchScore}% phù hợp';
                          else subtitle = 'Chờ chấp nhận · ${item.matchScore}% phù hợp';
                          
                          return _buildConnectionItem(
                            name: item.partnerName,
                            subtitle: subtitle,
                            onTap: () {
                              if (_selectedTabIndex == 0) {
                                Navigator.pushNamed(context, AppRoutes.contactDetails, arguments: {'contactId': item.partnerId});
                              } else if (_selectedTabIndex == 1) {
                                Navigator.pushNamed(context, AppRoutes.receivedRequests);
                              } else {
                                Navigator.pushNamed(context, AppRoutes.sentRequest, arguments: {'partnerId': item.partnerId});
                              }
                            },
                          );
                        }).toList(),
                        
                        const SizedBox(height: 16),
                        
                        // Privacy Info Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF8F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Kết nối có sự đồng thuận',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'SourceSansPro',
                                  color: Color(0xFF142523),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Trao đổi nhu cầu, xem phòng trực tiếp\nvà thống nhất chi phí',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'SourceSansPro',
                                  color: Color(0xFF142523),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}