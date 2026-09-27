import 'package:flutter/material.dart';

enum PenpotStateMode {
  blockedUsers,
  noResults,
  offline,
  roomUnavailable,
  loadingRoom,
}

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({
    super.key,
    this.blockedNames = const ['Người dùng #028'],
  });

  final List<String> blockedNames;

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late final List<String> _blockedNames = [...widget.blockedNames];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PenpotColors.canvas,
      appBar: AppBar(
        title: const Text('Người đã chặn'),
        backgroundColor: _PenpotColors.canvas,
        foregroundColor: _PenpotColors.ink,
        elevation: 0,
      ),
      body: _blockedNames.isEmpty
          ? const PenpotStateView(
              icon: Icons.person_off_outlined,
              title: 'Bạn chưa chặn ai',
              description: 'Những người bạn chặn sẽ xuất hiện ở đây.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                const Text(
                  'Quản lý ai có thể tìm thấy bạn',
                  style: TextStyle(color: _PenpotColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 18),
                for (final name in _blockedNames)
                  _BlockedUserCard(
                    name: name,
                    onUnblock: () => setState(() => _blockedNames.remove(name)),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Người bị chặn không nhận thông báo.\nBạn có thể thay đổi quyết định bất cứ lúc nào.',
                  style: TextStyle(color: _PenpotColors.muted, height: 1.5),
                ),
              ],
            ),
    );
  }
}

class _BlockedUserCard extends StatelessWidget {
  const _BlockedUserCard({required this.name, required this.onUnblock});

  final String name;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _PenpotColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: _PenpotColors.soft,
            child: Icon(Icons.person_outline, color: _PenpotColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _PenpotColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Đã chặn · Không thể gửi lời mời',
                  style: TextStyle(color: _PenpotColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onUnblock,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _PenpotColors.primary,
                    side: const BorderSide(color: _PenpotColors.primary),
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Bỏ chặn người dùng'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    this.items = _defaultItems,
    this.onItemTap,
  });

  final List<PenpotNotificationItem> items;
  final ValueChanged<PenpotNotificationItem>? onItemTap;

  static const _defaultItems = <PenpotNotificationItem>[
    PenpotNotificationItem(
      title: 'Minh Anh gửi lời mời kết nối',
      description: 'Đã đọc · 94% phù hợp',
      icon: Icons.person_add_alt_1_outlined,
    ),
    PenpotNotificationItem(
      title: 'Lịch xem phòng đang chờ xác nhận',
      description: 'Đã đọc · Studio ngập nắng',
      icon: Icons.calendar_today_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PenpotColors.canvas,
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: _PenpotColors.canvas,
        foregroundColor: _PenpotColors.ink,
        elevation: 0,
      ),
      body: items.isEmpty
          ? const PenpotStateView(
              icon: Icons.notifications_none_outlined,
              title: 'Chưa có thông báo',
              description:
                  'Thông báo về kết nối, lịch hẹn và tin đăng sẽ xuất hiện ở đây.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                const Text(
                  'Tất cả thông báo đã được đọc',
                  style: TextStyle(color: _PenpotColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 18),
                for (final item in items)
                  _NotificationCard(
                    item: item,
                    onTap: onItemTap == null ? null : () => onItemTap!(item),
                  ),
              ],
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, this.onTap});

  final PenpotNotificationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _PenpotColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: _PenpotColors.soft,
              foregroundColor: _PenpotColors.primary,
              child: Icon(item.icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: _PenpotColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: _PenpotColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: _PenpotColors.muted),
          ],
        ),
      ),
    );
  }
}

class PenpotNotificationItem {
  const PenpotNotificationItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class PenpotStateScreen extends StatelessWidget {
  const PenpotStateScreen({required this.mode, super.key});

  final PenpotStateMode mode;

  @override
  Widget build(BuildContext context) {
    final state = _stateFor(mode);
    return Scaffold(
      backgroundColor: _PenpotColors.canvas,
      appBar: AppBar(
        title: Text(state.appBarTitle),
        backgroundColor: _PenpotColors.canvas,
        foregroundColor: _PenpotColors.ink,
        elevation: 0,
      ),
      body: PenpotStateView(
        icon: state.icon,
        title: state.title,
        description: state.description,
        actionLabel: state.actionLabel,
        secondaryActionLabel: state.secondaryActionLabel,
        onAction: state.actionLabel == null
            ? null
            : () => Navigator.maybePop(context),
        onSecondaryAction: state.secondaryActionLabel == null
            ? null
            : () => Navigator.maybePop(context),
        loading: mode == PenpotStateMode.loadingRoom,
      ),
    );
  }

  _PenpotStateCopy _stateFor(PenpotStateMode value) {
    switch (value) {
      case PenpotStateMode.blockedUsers:
        return const _PenpotStateCopy(
          'Người đã chặn',
          Icons.person_off_outlined,
          'Người đã chặn',
          'Danh sách người bạn đã chặn sẽ hiển thị ở đây.',
          null,
          null,
        );
      case PenpotStateMode.noResults:
        return const _PenpotStateCopy(
          'Không có kết quả',
          Icons.check_circle_outline,
          'Chưa tìm thấy phòng phù hợp',
          'Thử tăng khoảng giá hoặc chọn thêm\nkhu vực lân cận để có nhiều lựa chọn hơn.',
          'Điều chỉnh bộ lọc',
          'Xem tất cả phòng',
        );
      case PenpotStateMode.offline:
        return const _PenpotStateCopy(
          'Mất kết nối',
          Icons.priority_high_rounded,
          'Chưa tải được dữ liệu',
          'Kiểm tra kết nối mạng rồi thử lại.\nCác thông tin bạn đã lưu vẫn được giữ.',
          'Thử tải lại',
          null,
        );
      case PenpotStateMode.roomUnavailable:
        return const _PenpotStateCopy(
          'Phòng không còn trống',
          Icons.check_circle_outline,
          'Tin đăng này đã đóng',
          'Người đăng đã tìm được người thuê.\nKhám phá những căn phòng tương tự nhé.',
          'Tìm phòng khác',
          null,
        );
      case PenpotStateMode.loadingRoom:
        return const _PenpotStateCopy(
          'Đang tải phòng',
          Icons.home_work_outlined,
          'Đang tìm những lựa chọn dành cho bạn',
          null,
          null,
          null,
        );
    }
  }
}

class PenpotStateView extends StatelessWidget {
  const PenpotStateView({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.secondaryActionLabel,
    this.onAction,
    this.onSecondaryAction,
    this.loading = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onSecondaryAction;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const _LoadingRoomSkeleton()
            else
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: _PenpotColors.soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _PenpotColors.primary, size: 42),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _PenpotColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 10),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _PenpotColors.muted, height: 1.5),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: _PenpotColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ),
            ],
            if (secondaryActionLabel != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: onSecondaryAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _PenpotColors.primary,
                    side: const BorderSide(color: _PenpotColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(secondaryActionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton preview used by Penpot screen 64 ("Đang tải phòng").
///
/// The design shows room cards while recommendations are loading rather than
/// a standalone spinner, so the loading state keeps the same visual rhythm as
/// the discovery feed.
class _LoadingRoomSkeleton extends StatelessWidget {
  const _LoadingRoomSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('penpot_loading_skeleton'),
      children: [
        for (var index = 0; index < 6; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 68,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _PenpotColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: _PenpotColors.soft,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 11,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _PenpotColors.soft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FractionallySizedBox(
                          widthFactor: index.isEven ? .62 : .42,
                          child: Container(
                            height: 9,
                            decoration: BoxDecoration(
                              color: _PenpotColors.soft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PenpotStateCopy {
  const _PenpotStateCopy(
    this.appBarTitle,
    this.icon,
    this.title,
    this.description,
    this.actionLabel,
    this.secondaryActionLabel,
  );

  final String appBarTitle;
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final String? secondaryActionLabel;
}

class _PenpotColors {
  static const canvas = Color(0xFFF5F8F7);
  static const soft = Color(0xFFE8F4F1);
  static const primary = Color(0xFF087E6B);
  static const ink = Color(0xFF142523);
  static const muted = Color(0xFF52625F);
  static const border = Color(0xFFDCE6E3);
}
