import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../navigation/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/penpot_back_button.dart';

class RoommateProfileScreen extends StatefulWidget {
  const RoommateProfileScreen({super.key, this.userId, this.displayName});
  final int? userId;
  final String? displayName;

  @override
  State<RoommateProfileScreen> createState() => _RoommateProfileScreenState();
}

class _RoommateProfileScreenState extends State<RoommateProfileScreen> {
  Map<String, dynamic>? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.userId;
    if (id == null || id <= 0) {
      setState(() => _error = 'Không xác định được người dùng.');
      return;
    }
    try {
      final profile = await ApiService().getPublicProfile(id);
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted) setState(() => _error = 'Không tải được hồ sơ: $e');
    }
  }

  String _money(dynamic value) => value is num
      ? NumberFormat.currency(
          locale: 'vi_VN',
          symbol: 'đ',
          decimalDigits: 0,
        ).format(value)
      : 'Chưa thiết lập';

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        title: const Text('Hồ sơ bạn ở ghép'),
        leading: const PenpotBackButton(),
        backgroundColor: const Color(0xFFF5F8F7),
        foregroundColor: const Color(0xFF142523),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage:
                          (profile['avatarUrl'] as String?)?.isNotEmpty == true
                          ? NetworkImage(profile['avatarUrl'] as String)
                          : null,
                      child:
                          (profile['avatarUrl'] as String?)?.isNotEmpty == true
                          ? null
                          : const Icon(Icons.person, size: 48),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile['fullName'] as String? ??
                                widget.displayName ??
                                'Người dùng',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if ((profile['university'] as String?)?.isNotEmpty ==
                              true)
                            Text(profile['university'] as String),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if ((profile['bioDescription'] as String?)?.isNotEmpty ==
                    true) ...[
                  const Text(
                    'Một chút về mình',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Text(profile['bioDescription'] as String),
                  const SizedBox(height: 20),
                ],
                const Text(
                  'Mong muốn ở ghép',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                ListTile(
                  title: const Text('Khu vực'),
                  subtitle: Text(
                    profile['targetDistrict'] as String? ?? 'Chưa thiết lập',
                  ),
                ),
                ListTile(
                  title: const Text('Ngân sách'),
                  subtitle: Text(
                    '${_money(profile['budgetMin'])} – ${_money(profile['budgetMax'])}',
                  ),
                ),
                ListTile(
                  title: const Text('Hút thuốc'),
                  subtitle: Text(
                    profile['isSmoking'] == null
                        ? 'Chưa thiết lập'
                        : profile['isSmoking'] == true
                        ? 'Có'
                        : 'Không',
                  ),
                ),
                ListTile(
                  title: const Text('Thú cưng'),
                  subtitle: Text(
                    profile['allowPets'] == null
                        ? 'Chưa thiết lập'
                        : profile['allowPets'] == true
                        ? 'Chấp nhận'
                        : 'Không',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.sendRequest,
                    arguments: {
                      'partnerId': widget.userId,
                      'partnerName': profile['fullName'],
                    },
                  ),
                  child: const Text('Gửi lời mời kết nối'),
                ),
              ],
            ),
    );
  }
}
