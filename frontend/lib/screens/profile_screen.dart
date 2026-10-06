import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_user.dart';
import '../models/user_preference.dart';
import '../navigation/app_routes.dart';
import '../services/api_service.dart';
import '../state/auth_session.dart';

class ProfileScreen extends StatefulWidget {
  final AuthUser currentUser;
  final ApiService? apiService;

  const ProfileScreen({super.key, required this.currentUser, this.apiService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ApiService _api;
  late AuthUser _currentUser;
  AuthSession? _session;
  int? _sessionGeneration;
  bool get _currentSession =>
      _session == null ||
      _session!.isCurrentSession(
        _sessionGeneration!,
        widget.currentUser.userId,
      );

  UserPreference? _preference;
  bool _isLoadingPreferences = true;
  String? _preferencesError;
  int _preferencesRequestId = 0;
  bool? _searchActive;
  bool _searchStatusError = false;
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _currentUser = widget.currentUser;
    _session = context.read<AuthSession?>();
    _sessionGeneration = _session?.generation;
    _loadPreferences();
    _loadSearchStatus();
  }

  Future<void> _loadSearchStatus() async {
    if (!mounted || !_currentSession) return;
    final requestId = ++_searchRequestId;
    setState(() {
      _searchActive = null;
      _searchStatusError = false;
    });
    try {
      final active = await _api.getSearchStatus();
      if (!mounted || !_currentSession || requestId != _searchRequestId) return;
      setState(() => _searchActive = active);
    } catch (_) {
      if (!mounted || !_currentSession || requestId != _searchRequestId) return;
      setState(() => _searchStatusError = true);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_loadPreferences(), _loadSearchStatus()]);
  }

  Future<void> _loadPreferences() async {
    if (!mounted || !_currentSession) return;
    final requestId = ++_preferencesRequestId;
    setState(() {
      _isLoadingPreferences = true;
      _preferencesError = null;
    });

    try {
      final data = await _api.getPreferences(_currentUser.userId);
      if (!mounted || !_currentSession || requestId != _preferencesRequestId) {
        return;
      }
      final preference = data != null ? UserPreference.fromJson(data) : null;
      setState(() {
        _preference = preference;
        _isLoadingPreferences = false;
      });
    } catch (_) {
      if (!mounted || !_currentSession || requestId != _preferencesRequestId) {
        return;
      }
      setState(() {
        _isLoadingPreferences = false;
        _preferencesError = 'Không tải được tiêu chí. Vui lòng thử lại.';
      });
    }
  }

  String _getPreferenceSummary() {
    if (_isLoadingPreferences) return 'Đang tải...';
    if (_preferencesError != null) return _preferencesError!;
    if (_preference == null) return 'Chưa thiết lập tiêu chí ghép trọ';

    // Example: "2–4 triệu · Bình Thạnh · Không hút thuốc"
    final budget = _preference!.budgetDisplay;
    final district = _preference!.districtDisplay;
    final smoke = _preference!.isSmoking ? 'Có hút thuốc' : 'Không hút thuốc';

    return '$budget · $district · $smoke';
  }

  Future<void> _navigateToEditProfile() async {
    final updatedUser = await Navigator.pushNamed(
      context,
      AppRoutes.editProfile,
    );
    if (!mounted ||
        !_currentSession ||
        updatedUser is! AuthUser ||
        updatedUser.userId != widget.currentUser.userId) {
      return;
    }
    setState(() => _currentUser = _session?.user ?? updatedUser);
    await _loadPreferences();
  }

  Future<void> _navigateToCriteria() async {
    final saved = await Navigator.pushNamed(context, AppRoutes.survey);
    // Survey returns true only after the server confirms a successful save.
    if (!mounted || !_currentSession || saved != true) return;
    await _loadPreferences();
  }

  void _navigateToAppointments() {
    Navigator.pushNamed(context, AppRoutes.viewingAppointments);
  }

  void _navigateToMyPosts() {
    Navigator.pushNamed(context, AppRoutes.listingManagement);
  }

  void _navigateToNotifications() {
    Navigator.pushNamed(context, AppRoutes.notifications);
  }

  Future<void> _navigateToSettings() async {
    await Navigator.pushNamed(context, AppRoutes.settings);
    if (!mounted || !_currentSession) return;
    await _refresh();
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // No shadow in Penpot or very light if any, we'll keep it flat as per design
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SourceSansPro',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'SourceSansPro',
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession?>();
    if (!_currentSession) {
      return const Scaffold(
        body: Center(
          child: Text('Phiên đăng nhập đã thay đổi. Vui lòng mở lại hồ sơ.'),
        ),
      );
    }
    if (session?.user != null) _currentUser = session!.user!;
    final avatarUrl = _currentUser.avatarUrl;
    final hasValidAvatar =
        avatarUrl != null &&
        (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7), // Match Penpot background
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            children: [
              // Header
              const Text(
                'Hồ sơ của tôi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SourceSansPro',
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quản lý hành trình tìm bạn ở ghép',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'SourceSansPro',
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 32),

              // User Info Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: hasValidAvatar
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: !hasValidAvatar
                        ? Text(
                            _currentUser.fullName.isNotEmpty
                                ? _currentUser.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser.fullName,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SourceSansPro',
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser.email,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'SourceSansPro',
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Status and Edit buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8F5), // Surface from Penpot
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        _searchStatusError
                            ? 'Chưa tải được trạng thái tìm bạn'
                            : _searchActive == null
                            ? 'Đang tải trạng thái tìm bạn...'
                            : _searchActive!
                            ? 'Đang tìm bạn ở ghép'
                            : 'Đã tắt tìm bạn ở ghép',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SourceSansPro',
                          color: Color(0xFF0D5C46), // Darker green text
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _navigateToEditProfile,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8F5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Chỉnh sửa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SourceSansPro',
                          color: Color(0xFF0D5C46),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_searchStatusError)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loadSearchStatus,
                    child: const Text('Thử lại trạng thái'),
                  ),
                ),
              const SizedBox(height: 32),

              // Menu List
              _buildMenuCard(
                title: 'Tiêu chí của tôi',
                subtitle: _getPreferenceSummary(),
                onTap: _navigateToCriteria,
              ),
              if (_preferencesError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _loadPreferences,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ),
                ),
              _buildMenuCard(
                title: 'Lịch xem phòng',
                subtitle: 'Theo dõi lịch bạn đã đặt',
                onTap: _navigateToAppointments,
              ),
              _buildMenuCard(
                title: 'Tin đăng của tôi',
                subtitle: 'Quản lý phòng, ảnh và lịch hẹn',
                onTap: _navigateToMyPosts,
              ),
              _buildMenuCard(
                title: 'Thông báo',
                subtitle: 'Lời mời, lịch xem phòng và cập nhật',
                onTap: _navigateToNotifications,
              ),
              _buildMenuCard(
                title: 'Cài đặt & quyền riêng tư',
                subtitle: 'Tài khoản, bảo mật và hỗ trợ',
                onTap: _navigateToSettings,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: 3,
        onDestinationSelected: (index) {
          if (index == 3) return;
          Navigator.pushReplacementNamed(
            context,
            index == 2 ? AppRoutes.requests : AppRoutes.home,
            arguments: index == 2 ? null : {'initialTab': index},
          );
        },
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
