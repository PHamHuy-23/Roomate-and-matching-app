import 'package:flutter/material.dart';
import '../models/match_request_item.dart';
import '../models/viewing_appointment.dart';
import '../services/api_service.dart';
import '../navigation/app_routes.dart';

class RequestsScreen extends StatefulWidget {
  final int currentUserId;
  final ApiService? apiService;
  const RequestsScreen({
    super.key,
    required this.currentUserId,
    this.apiService,
  });

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();

  List<MatchRequestItem> _receivedRequests = [];
  List<MatchRequestItem> _sentRequests = [];
  List<ViewingAppointment> _appointments = [];
  bool _isLoading = false;
  String? _error;

  // 0: Đã kết nối, 1: Lịch xem phòng, 2: Đã nhận, 3: Đã gửi
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final received = await _api.getReceivedRequests(widget.currentUserId);
      final sent = await _api.getSentRequests(widget.currentUserId);

      List<ViewingAppointment> apts = [];
      try {
        apts = await _api.getMyAppointments();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _receivedRequests = received;
          _sentRequests = sent;
          _appointments = apts;
          _isLoading = false;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = error.message.trim().isNotEmpty
              ? error.message
              : 'Không thể tải kết nối, vui lòng thử lại.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không thể tải kết nối, vui lòng thử lại.';
      });
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
            color: isSelected
                ? const Color(0xFF087E6B)
                : const Color(0xFF65746F),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionItem({
    required String name,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onChatTap,
    String? avatarUrl,
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
                color: const Color(0xFFE8F4F1),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: Color(0xFF087E6B),
                        ),
                      )
                    : const Icon(Icons.person, color: Color(0xFF087E6B)),
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
            if (onChatTap != null)
              IconButton(
                tooltip: 'Nhắn tin',
                onPressed: onChatTap,
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF087E6B),
                ),
              )
            else
              const Icon(Icons.chevron_right, color: Color(0xFFB0BEC5)),
          ],
        ),
      ),
    );
  }

  void _selectNavigationDestination(int index) {
    if (index == 2) return;

    if (index == 3) {
      Navigator.pushReplacementNamed(context, AppRoutes.profile);
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.home,
      arguments: {'initialTab': index},
    );
  }

  @override
  Widget build(BuildContext context) {
    final received = _error == null && !_isLoading
        ? _receivedRequests
        : <MatchRequestItem>[];
    final sent = _error == null && !_isLoading
        ? _sentRequests
        : <MatchRequestItem>[];
    final pendingReceived = received
        .where((r) => r.status == 'PENDING')
        .toList();
    final pendingSent = sent.where((r) => r.status == 'PENDING').toList();

    final connected = [
      ...received.where((r) => r.status == 'ACCEPTED'),
      ...sent.where((r) => r.status == 'ACCEPTED'),
    ];

    List<MatchRequestItem> currentList = [];
    if (_selectedTabIndex == 0) {
      currentList = connected;
    } else if (_selectedTabIndex == 2) {
      currentList = pendingReceived;
    } else if (_selectedTabIndex == 3) {
      currentList = pendingSent;
    }

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
                  _buildFilterChip(
                    1,
                    _appointments.isNotEmpty
                        ? 'Lịch xem phòng · ${_appointments.length}'
                        : 'Lịch xem phòng',
                  ),
                  _buildFilterChip(
                    2,
                    pendingReceived.isNotEmpty
                        ? 'Đã nhận · ${pendingReceived.length}'
                        : 'Đã nhận',
                  ),
                  _buildFilterChip(
                    3,
                    pendingSent.isNotEmpty
                        ? 'Đã gửi · ${pendingSent.length}'
                        : 'Đã gửi',
                  ),
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
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.cloud_off_outlined,
                                    color: Color(0xFF65746F),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(_error!, textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: _loadData,
                                    child: const Text('Thử lại'),
                                  ),
                                ],
                              ),
                            ),
                          if (_error == null && _selectedTabIndex == 1 && _appointments.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'Chưa có lịch xem phòng nào',
                                  style: TextStyle(color: Color(0xFF65746F)),
                                ),
                              ),
                            ),
                          if (_error == null && _selectedTabIndex != 1 && currentList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'Không có kết nối nào',
                                  style: TextStyle(color: Color(0xFF65746F)),
                                ),
                              ),
                            ),

                          if (_selectedTabIndex == 1)
                            ..._appointments.map((apt) {
                              final isHost = apt.hostId == widget.currentUserId;
                              final partnerName = isHost ? apt.requesterName : apt.hostName;
                              final partnerId = isHost ? apt.requesterId : apt.hostId;
                              final avatar = isHost ? apt.requesterAvatar : apt.hostAvatar;
                              final roleLabel = isHost ? 'Khách thuê' : 'Chủ phòng';
                              final statusLabel = apt.status == 'CONFIRMED'
                                  ? 'Đã xác nhận'
                                  : (apt.status == 'PENDING' ? 'Chờ xác nhận' : 'Đã hủy');

                              return _buildConnectionItem(
                                name: partnerName,
                                subtitle: '$roleLabel · $statusLabel · ${apt.roomTitle}',
                                avatarUrl: avatar,
                                onChatTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.chat,
                                  arguments: {
                                    'partnerId': partnerId,
                                    'partnerName': partnerName,
                                  },
                                ),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  isHost ? AppRoutes.listingManagement : AppRoutes.viewingAppointments,
                                  arguments: isHost
                                      ? {'roomPostId': apt.roomPostId}
                                      : {'appointmentId': apt.id},
                                ),
                              );
                            })
                          else
                            ...currentList.map((item) {
                              String subtitle = '';
                              if (_selectedTabIndex == 0) {
                                subtitle = 'Đã kết nối · Xem thông tin liên hệ';
                              } else if (_selectedTabIndex == 2) {
                                subtitle =
                                    'Lời mời mới · ${item.matchScore}% phù hợp';
                              } else {
                                subtitle =
                                    'Chờ chấp nhận · ${item.matchScore}% phù hợp';
                              }

                              return _buildConnectionItem(
                                name: item.partnerName,
                                subtitle: subtitle,
                                avatarUrl: item.partnerAvatar,
                                onChatTap: _selectedTabIndex == 0
                                    ? () => Navigator.pushNamed(
                                        context,
                                        AppRoutes.chat,
                                        arguments: {
                                          'partnerId': item.partnerId,
                                          'partnerName': item.partnerName,
                                        },
                                      )
                                    : null,
                                onTap: () async {
                                  if (_selectedTabIndex == 0) {
                                    final res = await Navigator.pushNamed(
                                      context,
                                      AppRoutes.contactDetails,
                                      arguments: {
                                        'contactId': item.partnerId,
                                        'partnerName': item.partnerName,
                                        'phone': item.contactPhone,
                                        'email': item.contactEmail,
                                        'avatarUrl': item.partnerAvatar,
                                      },
                                    );
                                    if (res == true && mounted) {
                                      _loadData();
                                    }
                                  } else if (_selectedTabIndex == 2) {
                                    await Navigator.pushNamed(
                                      context,
                                      AppRoutes.receivedRequests,
                                    );
                                    if (mounted) {
                                      _loadData();
                                    }
                                  } else {
                                    final res = await Navigator.pushNamed(
                                      context,
                                      AppRoutes.sentRequest,
                                      arguments: {
                                        'partnerId': item.partnerId,
                                        'partnerName': item.partnerName,
                                      },
                                    );
                                    if (res == true && mounted) {
                                      _loadData();
                                    }
                                  }
                                },
                              );
                            }),

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
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: 2,
        onDestinationSelected: _selectNavigationDestination,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEAF8F5),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Color(0xFF087E6B)),
            label: 'Khám phá',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work, color: Color(0xFF087E6B)),
            label: 'Phòng trọ',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum, color: Color(0xFF087E6B)),
            label: 'Kết nối',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF087E6B)),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
