import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/auth_user.dart';
import '../models/match_recommendation.dart';
import '../models/room_post.dart';
import '../navigation/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/match_card.dart';

class HomeScreen extends StatefulWidget {
  final AuthUser currentUser;
  final ApiService? apiService;
  const HomeScreen({super.key, required this.currentUser, this.apiService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiService _api;
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  late Future<List<MatchRecommendation>> _matchesFuture;
  late int _currentUserId;
  final Set<int> _connectingUsers = {};
  final Set<int> _sentRequests = {};

  // Trạng thái cho bộ lọc phòng trọ
  List<RoomPost> _allPosts = [];
  List<RoomPost> _filteredPosts = [];
  bool _isLoadingPosts = true;
  String _searchKeyword = '';
  double _maxPriceFilter = 10000000; // Bộ lọc giá tối đa (mặc định 10 triệu)

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _currentUserId = widget.currentUser.userId;
    _loadData();
  }

  void _loadData() {
    setState(() {
      _matchesFuture = _fetchMatches();
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

  Future<List<MatchRecommendation>> _fetchMatches() async {
    final matches = List<MatchRecommendation>.of(
      await _api.getRecommendations(_currentUserId),
    );
    matches.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return matches;
  }

  Future<void> _refreshMatches() async {
    final future = _fetchMatches();
    setState(() {
      _matchesFuture = future;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder hiển thị lỗi và nút thử lại.
    }
  }

  Future<void> _connect(MatchRecommendation item) async {
    if (_connectingUsers.contains(item.userId) ||
        _sentRequests.contains(item.userId)) {
      return;
    }
    setState(() => _connectingUsers.add(item.userId));
    try {
      final ok = await _api.sendMatchRequest(
        _currentUserId,
        item.userId,
        item.totalScore,
      );
      if (!mounted) return;
      if (ok) setState(() => _sentRequests.add(item.userId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Đã gửi yêu cầu tới ${item.fullName}.'
                : 'Không thể gửi yêu cầu. Vui lòng thử lại.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      // ApiService đã xử lý điều hướng cho phiên hết hạn.
      if (error is! ApiException || error.statusCode != 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Không thể gửi yêu cầu. Vui lòng thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _connectingUsers.remove(item.userId));
    }
  }

  Widget _feedState(
    IconData icon,
    String title,
    String message,
    String buttonLabel,
    VoidCallback action,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Colors.indigo.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: action, child: Text(buttonLabel)),
        ],
      ),
    );
  }

  Widget _buildDiscoveryFeed() {
    return ColoredBox(
      color: const Color(0xFFF5F7FB),
      child: FutureBuilder<List<MatchRecommendation>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final list = !loading && !snapshot.hasError
              ? snapshot.data ?? <MatchRecommendation>[]
              : <MatchRecommendation>[];
          return RefreshIndicator(
            onRefresh: _refreshMatches,
            child: ListView.builder(
              key: const PageStorageKey('discovery-feed'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
              itemCount: list.isEmpty ? 2 : list.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Khám phá bạn trọ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tìm người phù hợp để cùng xây dựng không gian sống.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        if (list.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            '${list.length} ứng viên • Tương thích cao nhất trước',
                            style: TextStyle(
                              color: Colors.indigo.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                if (loading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Đang tìm bạn trọ phù hợp...'),
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return _feedState(
                    Icons.wifi_off_rounded,
                    'Chưa tải được gợi ý',
                    error is ApiException
                        ? error.message
                        : 'Vui lòng kiểm tra kết nối và thử lại.',
                    'Thử lại',
                    _refreshMatches,
                  );
                }
                if (list.isEmpty) {
                  return _feedState(
                    Icons.people_outline,
                    'Chưa có ứng viên phù hợp',
                    'Cập nhật tiêu chí tìm bạn trọ hoặc kéo xuống để làm mới gợi ý.',
                    'Cập nhật tiêu chí',
                    () async {
                      final updated = await Navigator.pushNamed(
                        context,
                        AppRoutes.survey,
                      );
                      if (updated == true && mounted) await _refreshMatches();
                    },
                  );
                }
                final item = list[index - 1];
                return MatchCard(
                  key: ValueKey(item.userId),
                  item: item,
                  isConnecting: _connectingUsers.contains(item.userId),
                  isRequestSent: _sentRequests.contains(item.userId),
                  onConnect: () => _connect(item),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _applyPostFilters() {
    setState(() {
      _filteredPosts = _allPosts.where((p) {
        final matchAddress =
            p.address.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
            p.title.toLowerCase().contains(_searchKeyword.toLowerCase());
        final matchPrice = p.price <= _maxPriceFilter;
        return matchAddress && matchPrice;
      }).toList();
    });
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
            _buildDiscoveryFeed(),

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
                          _searchKeyword = val.trim();
                          _applyPostFilters();
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
