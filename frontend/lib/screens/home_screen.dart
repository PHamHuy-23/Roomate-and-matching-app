import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/auth_user.dart';
import '../models/match_recommendation.dart';
import '../models/room_post.dart';
import '../navigation/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/compatibility_bottom_sheet.dart';
import '../widgets/match_card.dart';

class HomeScreen extends StatefulWidget {
  final AuthUser currentUser;
  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _discoveryPrimary = Color(0xFF008F7A);

  final ApiService _api = ApiService();
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  late Future<List<MatchRecommendation>> _matchesFuture;
  late int _currentUserId;

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
          color: const Color(0xFFF5F8F7),
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
                    minimumScore: _minimumMatchScore,
                    district: _districtFilter,
                    districts: districts,
                    onSearchChanged: (value) {
                      setState(() => _matchSearchKeyword = value);
                    },
                    onMinimumScoreChanged: (value) {
                      setState(() => _minimumMatchScore = value);
                    },
                    onDistrictChanged: (value) {
                      setState(() => _districtFilter = value);
                    },
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    sliver: SliverList.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final item = matches[index];
                        return MatchCard(
                          item: item,
                          isConnecting: _connectingUserIds.contains(
                            item.userId,
                          ),
                          requestSent: _sentRequestUserIds.contains(
                            item.userId,
                          ),
                          onViewDetails: () => _showCompatibility(item),
                          onConnect: () => _sendMatchRequest(item),
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Roommate Hub',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          actions: [
            if (widget.currentUser.role == 'ROLE_ADMIN' ||
                widget.currentUser.role == 'ADMIN')
              IconButton(
                tooltip: 'Trang Quản Trị Viên',
                icon: const Icon(Icons.admin_panel_settings),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.admin);
                },
              ),
            IconButton(
              tooltip: 'Hộp thư kết nối',
              icon: const Icon(Icons.mail_outline),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.requests);
              },
            ),
            IconButton(
              tooltip: 'Cập nhật tiêu chí bạn trọ',
              icon: const Icon(Icons.tune),
              onPressed: () async {
                final updated = await Navigator.pushNamed(
                  context,
                  AppRoutes.survey,
                );
                if (updated == true) {
                  _loadData();
                }
              },
            ),
            IconButton(
              tooltip: 'Thông tin cá nhân & Đăng xuất',
              icon: const Icon(Icons.account_circle),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amberAccent,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Gợi Ý Bạn Ở Ghép'),
              Tab(icon: Icon(Icons.home_work), text: 'Bài Đăng Phòng'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: GỢI Ý BẠN TRỌ
            _buildDiscoveryTab(),

            // TAB 2: BÀI ĐĂNG PHÒNG CÓ BỘ LỌC TÌM KIẾM
            Column(
              children: [
                // Khung tìm kiếm & Lọc theo giá
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_home_work),
          label: const Text('Đăng Tin'),
          onPressed: () async {
            final created = await Navigator.pushNamed(
              context,
              AppRoutes.createPost,
            );
            if (created == true) {
              _loadData();
            }
          },
        ),
      ),
    );
  }
}

class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader({
    required this.userName,
    required this.resultCount,
    required this.minimumScore,
    required this.district,
    required this.districts,
    required this.onSearchChanged,
    required this.onMinimumScoreChanged,
    required this.onDistrictChanged,
  });

  final String userName;
  final int resultCount;
  final double minimumScore;
  final String district;
  final List<String> districts;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<double> onMinimumScoreChanged;
  final ValueChanged<String> onDistrictChanged;

  @override
  Widget build(BuildContext context) {
    final nameParts = userName.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isEmpty ? userName : nameParts.last;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chào $firstName 👋',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17342F),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$resultCount người phù hợp với bộ lọc hiện tại',
            style: const TextStyle(color: Color(0xFF687873)),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('match-search-field'),
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, trường hoặc khu vực...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF61746F)),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDDE7E4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDDE7E4)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                PopupMenuButton<double>(
                  key: const Key('minimum-score-filter'),
                  initialValue: minimumScore,
                  onSelected: onMinimumScoreChanged,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 0, child: Text('Tất cả mức điểm')),
                    PopupMenuItem(value: 60, child: Text('Từ 60% phù hợp')),
                    PopupMenuItem(value: 70, child: Text('Từ 70% phù hợp')),
                    PopupMenuItem(value: 80, child: Text('Từ 80% phù hợp')),
                  ],
                  child: _FilterPill(
                    icon: Icons.bolt,
                    label: minimumScore == 0
                        ? 'Mức phù hợp'
                        : 'Từ ${minimumScore.toStringAsFixed(0)}%',
                    active: minimumScore > 0,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  key: const Key('district-filter'),
                  initialValue: district,
                  onSelected: onDistrictChanged,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'Tất cả',
                      child: Text('Tất cả khu vực'),
                    ),
                    for (final value in districts)
                      PopupMenuItem(value: value, child: Text(value)),
                  ],
                  child: _FilterPill(
                    icon: Icons.location_on_outlined,
                    label: district == 'Tất cả' ? 'Khu vực' : district,
                    active: district != 'Tất cả',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF008F7A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDDF4EE) : Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: active ? primary : const Color(0xFFD8E3E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: active ? primary : const Color(0xFF526761),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? primary : const Color(0xFF425A54),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 17),
        ],
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
            Icon(icon, size: 46, color: const Color(0xFF7A918B)),
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
              style: const TextStyle(color: Color(0xFF687873)),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF008F7A),
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
