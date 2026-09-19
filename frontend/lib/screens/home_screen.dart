import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/auth_user.dart';
import '../models/match_recommendation.dart';
import '../models/room_post.dart';
import '../navigation/app_routes.dart';
import '../services/api_service.dart';
import '../theme/discovery_palette.dart';
import '../widgets/compatibility_bottom_sheet.dart';
import '../widgets/match_card.dart';

class HomeScreen extends StatefulWidget {
  final AuthUser currentUser;
  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _discoveryPrimary = DiscoveryPalette.primary;

  final ApiService _api = ApiService();
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  late Future<List<MatchRecommendation>> _matchesFuture;
  late int _currentUserId;
  int _selectedHomeTab = 0;

  // Trạng thái cho bộ lọc phòng trọ
  List<RoomPost> _allPosts = [];
  List<RoomPost> _filteredPosts = [];
  bool _isLoadingPosts = true;
  String _searchKeyword = '';
  double _maxPriceFilter = 10000000; // Bộ lọc giá tối đa (mặc định 10 triệu)

  // Trạng thái tìm kiếm và lọc ứng viên bạn trọ.
  String _matchSearchKeyword = '';
  double _minimumMatchScore = 0;
  String _districtFilter = 'Tất cả';
  final Set<int> _connectingUserIds = {};
  final Set<int> _sentRequestUserIds = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.currentUser.userId;
    _loadData();
  }

  void _loadData() {
    setState(() {
      _matchesFuture = _api.getRecommendations(_currentUserId);
      _isLoadingPosts = true;
    });

    _api
        .getRoomPosts()
        .then((posts) {
          if (mounted) {
            setState(() {
              _allPosts = posts;
              _applyPostFilters();
              _isLoadingPosts = false;
            });
          }
        })
        .catchError((err) {
          if (mounted) {
            setState(() => _isLoadingPosts = false);
          }
        });
  }

  void _applyPostFilters() {
    _filteredPosts = _allPosts.where((p) {
      final matchAddress =
          p.address.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
          p.title.toLowerCase().contains(_searchKeyword.toLowerCase());
      final matchPrice = p.price <= _maxPriceFilter;
      return matchAddress && matchPrice;
    }).toList();
  }

  Future<void> _refreshMatches() async {
    final refreshed = _api.getRecommendations(_currentUserId);
    setState(() => _matchesFuture = refreshed);
    await refreshed;
  }

  Future<void> _sendMatchRequest(MatchRecommendation item) async {
    if (_connectingUserIds.contains(item.userId) ||
        _sentRequestUserIds.contains(item.userId)) {
      return;
    }

    setState(() => _connectingUserIds.add(item.userId));
    final messenger = ScaffoldMessenger.of(context);
    try {
      final sent = await _api.sendMatchRequest(
        _currentUserId,
        item.userId,
        item.totalScore,
      );
      if (!mounted) return;
      if (sent) {
        setState(() => _sentRequestUserIds.add(item.userId));
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? 'Đã gửi lời mời tới ${item.fullName}!'
                : 'Không thể gửi lời mời, vui lòng thử lại.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không thể gửi lời mời, vui lòng thử lại.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _connectingUserIds.remove(item.userId));
      }
    }
  }

  void _showCompatibility(MatchRecommendation item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => CompatibilityBottomSheet(
        item: item,
        requestSent: _sentRequestUserIds.contains(item.userId),
        onConnect: () async {
          Navigator.pop(sheetContext);
          await _sendMatchRequest(item);
        },
      ),
    );
  }

  Future<void> _openSurvey() async {
    final updated = await Navigator.pushNamed(context, AppRoutes.survey);
    if (updated == true) {
      _loadData();
    }
  }

  Future<void> _showDiscoveryFilters(List<String> districts) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _DiscoveryFiltersSheet(
        districts: districts,
        initialDistrict: _districtFilter,
        initialMinimumScore: _minimumMatchScore,
        onApply: (district, score) {
          setState(() {
            _districtFilter = district;
            _minimumMatchScore = score;
          });
        },
      ),
    );
  }

  List<MatchRecommendation> _filterMatches(List<MatchRecommendation> source) {
    final query = _matchSearchKeyword.trim().toLowerCase();
    final filtered = source.where((item) {
      final matchesSearch =
          query.isEmpty ||
          item.fullName.toLowerCase().contains(query) ||
          item.targetDistrict.toLowerCase().contains(query) ||
          (item.university?.toLowerCase().contains(query) ?? false);
      final matchesScore = item.totalScore >= _minimumMatchScore;
      final matchesDistrict =
          _districtFilter == 'Tất cả' || item.targetDistrict == _districtFilter;
      return matchesSearch && matchesScore && matchesDistrict;
    }).toList()..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return filtered;
  }

  Widget _buildDiscoveryTab() {
    return FutureBuilder<List<MatchRecommendation>>(
      future: _matchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _discoveryPrimary),
          );
        }
        if (snapshot.hasError) {
          return _DiscoveryMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Chưa tải được gợi ý',
            description: '${snapshot.error}',
            actionLabel: 'Thử lại',
            onAction: _refreshMatches,
          );
        }

        final allMatches = snapshot.data ?? const <MatchRecommendation>[];
        final districts =
            allMatches
                .map((item) => item.targetDistrict)
                .where((district) => district.trim().isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        if (_districtFilter != 'Tất cả' &&
            !districts.contains(_districtFilter)) {
          _districtFilter = 'Tất cả';
        }
        final matches = _filterMatches(allMatches);
        return ColoredBox(
          color: DiscoveryPalette.canvas,
          child: RefreshIndicator(
            color: _discoveryPrimary,
            onRefresh: _refreshMatches,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _DiscoveryHeader(
                    userName: widget.currentUser.fullName,
                    resultCount: matches.length,
                    selectedDistrict: _districtFilter,
                    filtersActive:
                        _minimumMatchScore > 0 || _districtFilter != 'Tất cả',
                    onSearchChanged: (value) {
                      setState(() => _matchSearchKeyword = value);
                    },
                    onFiltersPressed: () => _showDiscoveryFilters(districts),
                    onPreferencesPressed: _openSurvey,
                    onAdminPressed:
                        widget.currentUser.role == 'ROLE_ADMIN' ||
                            widget.currentUser.role == 'ADMIN'
                        ? () => Navigator.pushNamed(context, AppRoutes.admin)
                        : null,
                  ),
                ),
                if (matches.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _DiscoveryMessage(
                      icon: Icons.person_search_outlined,
                      title: 'Không tìm thấy người phù hợp',
                      description: 'Hãy giảm mức điểm hoặc chọn khu vực khác.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 96),
                    sliver: SliverList.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final item = matches[index];
                        return MatchCard(
                          item: item,
                          onViewDetails: () => _showCompatibility(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomTab() {
    return SafeArea(
      bottom: false,
      child: ColoredBox(
        color: const Color(0xFFF5F8F7),
        child: Column(
          children: [
            // Khung tìm kiếm & Lọc theo giá
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo khu vực, đường, tên bài...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchKeyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchKeyword = '';
                                  _applyPostFilters();
                                });
                              },
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchKeyword = val.trim();
                        _applyPostFilters();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Giá tối đa: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _maxPriceFilter >= 10000000
                            ? 'Tất cả'
                            : fmt.format(_maxPriceFilter),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                          fontSize: 13,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _maxPriceFilter,
                          min: 1000000,
                          max: 10000000,
                          divisions: 9,
                          label: fmt.format(_maxPriceFilter),
                          onChanged: (val) {
                            setState(() {
                              _maxPriceFilter = val;
                              _applyPostFilters();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Danh sách bài đăng sau khi lọc
            Expanded(
              child: _isLoadingPosts
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPosts.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy phòng phù hợp với tiêu chí lọc.',
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filteredPosts.length,
                      itemBuilder: (context, i) {
                        final p = _filteredPosts[i];
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
                                Text(
                                  p.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Giá: ${fmt.format(p.price)}/tháng',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Địa chỉ: ${p.address}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  p.description,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Người đăng: ${p.authorName}',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    Text(
                                      'Tối đa: ${p.maxOccupants} người',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createRoomPost() async {
    final created = await Navigator.pushNamed(context, AppRoutes.createPost);
    if (created == true) {
      _loadData();
    }
  }

  void _selectHomeDestination(int index) {
    if (index <= 1) {
      setState(() => _selectedHomeTab = index);
      return;
    }
    Navigator.pushNamed(
      context,
      index == 2 ? AppRoutes.requests : AppRoutes.profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiscoveryPalette.canvas,
      body: IndexedStack(
        index: _selectedHomeTab,
        children: [_buildDiscoveryTab(), _buildRoomTab()],
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: _selectedHomeTab,
        onDestinationSelected: _selectHomeDestination,
        backgroundColor: Colors.white,
        indicatorColor: DiscoveryPalette.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: _discoveryPrimary),
            label: 'Khám phá',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work, color: _discoveryPrimary),
            label: 'Phòng',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum, color: _discoveryPrimary),
            label: 'Kết nối',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: _discoveryPrimary),
            label: 'Hồ sơ',
          ),
        ],
      ),
      floatingActionButton: _selectedHomeTab == 1
          ? FloatingActionButton.extended(
              backgroundColor: _discoveryPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_home_work),
              label: const Text('Đăng tin'),
              onPressed: _createRoomPost,
            )
          : null,
    );
  }
}

class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader({
    required this.userName,
    required this.resultCount,
    required this.selectedDistrict,
    required this.filtersActive,
    required this.onSearchChanged,
    required this.onFiltersPressed,
    required this.onPreferencesPressed,
    this.onAdminPressed,
  });

  final String userName;
  final int resultCount;
  final String selectedDistrict;
  final bool filtersActive;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFiltersPressed;
  final VoidCallback onPreferencesPressed;
  final VoidCallback? onAdminPressed;

  @override
  Widget build(BuildContext context) {
    final nameParts = userName.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isEmpty ? userName : nameParts.last;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.paddingOf(context).top + 16,
        22,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Khám phá',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: DiscoveryPalette.text,
                  ),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('match-filter-button'),
                onPressed: onFiltersPressed,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Bộ lọc'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: filtersActive
                      ? DiscoveryPalette.primary
                      : DiscoveryPalette.muted,
                  backgroundColor: filtersActive
                      ? DiscoveryPalette.primarySoft
                      : DiscoveryPalette.surface,
                  side: const BorderSide(color: DiscoveryPalette.border),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Tùy chọn',
                icon: const Icon(
                  Icons.more_horiz,
                  color: DiscoveryPalette.muted,
                ),
                onSelected: (value) {
                  if (value == 'preferences') {
                    onPreferencesPressed();
                  } else if (value == 'admin') {
                    onAdminPressed?.call();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'preferences',
                    child: Text('Cập nhật tiêu chí bạn trọ'),
                  ),
                  if (onAdminPressed != null)
                    const PopupMenuItem(
                      value: 'admin',
                      child: Text('Trang quản trị'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            selectedDistrict == 'Tất cả'
                ? '$resultCount gợi ý dành cho $firstName'
                : '$resultCount gợi ý tại $selectedDistrict',
            style: const TextStyle(
              color: DiscoveryPalette.muted,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('match-search-field'),
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm tên, trường hoặc khu vực...',
              prefixIcon: const Icon(
                Icons.search,
                color: DiscoveryPalette.muted,
              ),
              filled: true,
              fillColor: DiscoveryPalette.surface,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: DiscoveryPalette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: DiscoveryPalette.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryFiltersSheet extends StatefulWidget {
  const _DiscoveryFiltersSheet({
    required this.districts,
    required this.initialDistrict,
    required this.initialMinimumScore,
    required this.onApply,
  });

  final List<String> districts;
  final String initialDistrict;
  final double initialMinimumScore;
  final void Function(String district, double score) onApply;

  @override
  State<_DiscoveryFiltersSheet> createState() => _DiscoveryFiltersSheetState();
}

class _DiscoveryFiltersSheetState extends State<_DiscoveryFiltersSheet> {
  static const _primary = DiscoveryPalette.primary;

  late String _district;
  late double _minimumScore;

  @override
  void initState() {
    super.initState();
    _district = widget.initialDistrict;
    _minimumScore = widget.initialMinimumScore;
  }

  void _apply() {
    widget.onApply(_district, _minimumScore);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _district = 'Tất cả';
      _minimumScore = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: DiscoveryPalette.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bộ lọc tìm kiếm',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: DiscoveryPalette.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Điều chỉnh để thu hẹp kết quả phù hợp.',
              style: TextStyle(color: DiscoveryPalette.muted),
            ),
            const SizedBox(height: 22),
            const Text(
              'Khu vực',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const Key('district-filter'),
              initialValue: _district,
              decoration: InputDecoration(
                filled: true,
                fillColor: DiscoveryPalette.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DiscoveryPalette.border),
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'Tất cả',
                  child: Text('Tất cả khu vực'),
                ),
                for (final district in widget.districts)
                  DropdownMenuItem(value: district, child: Text(district)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _district = value);
              },
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Điểm tương thích tối thiểu',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  _minimumScore == 0
                      ? 'Tất cả'
                      : '${_minimumScore.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Slider(
              key: const Key('minimum-score-filter'),
              value: _minimumScore,
              min: 0,
              max: 90,
              divisions: 9,
              activeColor: _primary,
              label: _minimumScore == 0
                  ? 'Tất cả'
                  : '${_minimumScore.toStringAsFixed(0)}%',
              onChanged: (value) => setState(() => _minimumScore = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _reset,
                    child: const Text('Đặt lại'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Xem kết quả'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryMessage extends StatelessWidget {
  const _DiscoveryMessage({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: DiscoveryPalette.muted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: DiscoveryPalette.muted),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: DiscoveryPalette.primary,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
