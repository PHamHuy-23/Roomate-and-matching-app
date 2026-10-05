import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/penpot_back_button.dart';
import '../services/api_service.dart';
import '../state/auth_session.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key, this.apiService});
  final ApiService? apiService;

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late final ApiService _api;
  AuthSession? _session;
  int? _generation;
  int? _userId;
  bool _isSearchActive = false;
  bool? _confirmedStatus;
  bool _busy = true;
  String? _loadError;

  bool get _currentSession =>
      _session != null &&
      _userId != null &&
      _session!.isCurrentSession(_generation!, _userId!);

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _session = context.read<AuthSession?>();
    _generation = _session?.generation;
    _userId = _session?.user?.userId;
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    if (!_currentSession) return;
    setState(() {
      _busy = true;
      _loadError = null;
    });
    try {
      final value = await _api.getSearchStatus();
      if (mounted && _currentSession) {
        setState(() {
          _isSearchActive = value;
          _confirmedStatus = value;
        });
      }
    } catch (e) {
      if (mounted && _currentSession) {
        setState(
          () => _loadError = 'Không tải được trạng thái. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted && _currentSession) setState(() => _busy = false);
    }
  }

  Future<void> _saveStatus() async {
    if (_busy ||
        _confirmedStatus == null ||
        _loadError != null ||
        !_currentSession) {
      return;
    }
    final value = _isSearchActive;
    setState(() => _busy = true);
    try {
      final confirmed = await _api.updateSearchStatus(value);
      if (!mounted || !_currentSession) return;
      _confirmedStatus = confirmed;
      if (confirmed != value) {
        throw const ApiException(
          'Máy chủ chưa xác nhận trạng thái đã chọn. Vui lòng thử lại.',
        );
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu cài đặt.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted && _currentSession) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không lưu được trạng thái: $e'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          ),
        );
      }
    } finally {
      if (mounted && _currentSession) setState(() => _busy = false);
    }
  }

  Widget _buildSettingItem(
    String title,
    String subtitle, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            ?trailing,
          ],
        ),
      ),
    );
  }

  void _showPrivacyDetails(String title, String message) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF5F8F7),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF142523),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF65746F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthSession?>();
    if (!_currentSession) {
      return const Scaffold(
        body: Center(
          child: Text('Phiên đăng nhập đã thay đổi. Vui lòng mở lại cài đặt.'),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                          'Quyền riêng tư',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF142523),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Bạn kiểm soát thông tin được chia sẻ',
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
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                children: [
                  // Settings list
                  _buildSettingItem(
                    'Trạng thái tìm bạn',
                    _busy && _confirmedStatus == null
                        ? 'Đang tải trạng thái...'
                        : _loadError != null
                        ? 'Chưa tải được trạng thái'
                        : _isSearchActive != _confirmedStatus
                        ? 'Chưa lưu thay đổi'
                        : _isSearchActive
                        ? 'Đang bật · Hiển thị trong gợi ý'
                        : 'Đã tắt · Ẩn khỏi gợi ý',
                    trailing: Switch(
                      value: _isSearchActive,
                      onChanged:
                          _busy ||
                              _confirmedStatus == null ||
                              _loadError != null
                          ? null
                          : (value) => setState(() => _isSearchActive = value),
                      activeTrackColor: const Color(0xFF087E6B),
                    ),
                  ),

                  if (_loadError != null) ...[
                    Text(_loadError!),
                    TextButton(
                      onPressed: _busy ? null : _loadStatus,
                      child: const Text('Thử lại'),
                    ),
                  ],

                  _buildSettingItem(
                    'Thông tin liên hệ',
                    'Chỉ chia sẻ với người đã kết nối',
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () => _showPrivacyDetails(
                      'Thông tin liên hệ',
                      'Email và số điện thoại chỉ được hiển thị sau khi cả hai người đồng ý kết nối.',
                    ),
                  ),

                  _buildSettingItem(
                    'Hồ sơ công khai',
                    'Tên, avatar, giới thiệu & tiêu chí',
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () => _showPrivacyDetails(
                      'Hồ sơ công khai',
                      'Bạn có thể kiểm soát trạng thái tìm bạn và những thông tin được hiển thị trên hồ sơ.',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Riêng tư ngay từ đầu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF142523),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Email và số điện thoại không xuất hiện\ntrên hồ sơ công khai',
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
                ],
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _busy || _confirmedStatus == null || _loadError != null
                      ? null
                      : _saveStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF087E6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _busy && _confirmedStatus != null
                        ? 'Đang lưu...'
                        : 'Lưu cài đặt',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SourceSansPro',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
