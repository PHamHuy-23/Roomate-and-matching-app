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

  const ProfileScreen({
    super.key,
    required this.currentUser,
    this.apiService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ApiService _api;
  late AuthUser _currentUser;
  
  UserPreference? _preference;
  bool _isLoadingPreferences = true;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _currentUser = widget.currentUser;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoadingPreferences = true;
    });

    try {
      final data = await _api.getPreferences(_currentUser.userId);
      if (mounted) {
        setState(() {
          _preference = data != null ? UserPreference.fromJson(data) : null;
          _isLoadingPreferences = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPreferences = false;
        });
      }
    }
  }

  String _getPreferenceSummary() {
    if (_isLoadingPreferences) return 'Đang tải...';
    if (_preference == null) return 'Chưa thiết lập tiêu chí ghép trọ';
    
    // Example: "2–4 triệu · Bình Thạnh · Không hút thuốc"
    final budget = _preference!.budgetDisplay;
    final district = _preference!.districtDisplay;
    final smoke = _preference!.isSmoking ? 'Có hút thuốc' : 'Không hút thuốc';
    
    return '$budget · $district · $smoke';
  }

  void _navigateToEditProfile() {
    Navigator.pushNamed(context, AppRoutes.editProfile);
  }

  void _navigateToCriteria() {
    // Navigate to SurveyScreen to edit criteria
    Navigator.pushNamed(context, AppRoutes.survey);
  }

  void _navigateToAppointments() {
    Navigator.pushNamed(context, AppRoutes.requests);
  }

  void _navigateToMyPosts() {
    Navigator.pushNamed(context, AppRoutes.createPost);
  }

  void _navigateToNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng thông báo đang phát triển')),
    );
  }

  void _navigateToSettings() {
    Navigator.pushNamed(context, AppRoutes.settings);
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
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _currentUser.avatarUrl;
    final hasValidAvatar = avatarUrl != null &&
        (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7), // Match Penpot background
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPreferences,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
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
                    backgroundImage: hasValidAvatar ? NetworkImage(avatarUrl) : null,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F5), // Surface from Penpot
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'Đang tìm bạn ở ghép',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SourceSansPro',
                        color: Color(0xFF0D5C46), // Darker green text
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _navigateToEditProfile,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
              const SizedBox(height: 32),

              // Menu List
              _buildMenuCard(
                title: 'Tiêu chí của tôi',
                subtitle: _getPreferenceSummary(),
                onTap: _navigateToCriteria,
              ),
              _buildMenuCard(
                title: 'Lịch xem phòng',
                subtitle: '1 lịch đang chờ xác nhận', // Hardcoded for now based on Penpot
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
    );
  }
}
