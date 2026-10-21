import 'package:flutter/material.dart';

import '../models/blocked_user.dart';
import '../services/api_service.dart';
import '../widgets/penpot_back_button.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<BlockedUser> _blockedUsers = [];
  final Set<int> _unblockingIds = {};

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiService.getBlockedUsers();
      if (mounted) {
        setState(() {
          _blockedUsers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleUnblock(BlockedUser user) async {
    setState(() => _unblockingIds.add(user.blockedUserId));
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _apiService.unblockUser(user.blockedUserId);
      if (mounted) {
        setState(() {
          _blockedUsers.removeWhere((u) => u.blockedUserId == user.blockedUserId);
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Đã bỏ chặn ${user.blockedUserName}.'),
            backgroundColor: const Color(0xFF087E6B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _unblockingIds.remove(user.blockedUserId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          'Người đã chặn',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF142523),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Quản lý ai có thể tìm thấy bạn',
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
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF087E6B)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFF65746F)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadBlockedUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF087E6B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_blockedUsers.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: const [
          SizedBox(height: 48),
          Center(
            child: Icon(Icons.block, size: 48, color: Color(0xFF65746F)),
          ),
          SizedBox(height: 16),
          Text(
            'Chưa có ai trong danh sách chặn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'SourceSansPro',
              color: Color(0xFF142523),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Người bị chặn sẽ không thể gửi lời mời hoặc nhắn tin cho bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF65746F),
              height: 1.4,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        ..._blockedUsers.map((user) => _buildBlockedUserItem(user)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'Người bị chặn không nhận thông báo.\nBạn có thể thay đổi quyết định bất cứ lúc nào.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: 'SourceSansPro',
              color: Color(0xFF142523),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockedUserItem(BlockedUser user) {
    final isUnblocking = _unblockingIds.contains(user.blockedUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFEAF8F5),
                  backgroundImage: user.blockedUserAvatar != null &&
                          user.blockedUserAvatar!.isNotEmpty
                      ? NetworkImage(user.blockedUserAvatar!)
                      : null,
                  child: user.blockedUserAvatar == null ||
                          user.blockedUserAvatar!.isEmpty
                      ? const Icon(Icons.person, color: Color(0xFF087E6B))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.blockedUserName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SourceSansPro',
                          color: Color(0xFF142523),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Đã chặn · Không thể gửi lời mời',
                        style: TextStyle(
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isUnblocking ? null : () => _handleUnblock(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAF8F5),
                foregroundColor: const Color(0xFF087E6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: isUnblocking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF087E6B)),
                      ),
                    )
                  : const Text(
                      'Bỏ chặn người dùng',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SourceSansPro',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
