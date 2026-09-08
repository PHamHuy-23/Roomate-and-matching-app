import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/auth_user.dart';
import '../models/match_recommendation.dart';
import '../models/room_post.dart';
import '../services/api_service.dart';
import '../widgets/match_card.dart';
import 'admin_screen.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'requests_screen.dart';
import 'survey_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthUser currentUser;
  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  late Future<List<MatchRecommendation>> _matchesFuture;
  late Future<List<RoomPost>> _postsFuture;
  late int _currentUserId;

  // Trạng thái cho bộ lọc phòng trọ
  List<RoomPost> _allPosts = [];
  List<RoomPost> _filteredPosts = [];
  bool _isLoadingPosts = true;
  String _searchKeyword = '';
  double _maxPriceFilter = 10000000; // Bộ lọc giá tối đa (mặc định 10 triệu)

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

    _api.getRoomPosts().then((posts) {
      if (mounted) {
        setState(() {
          _allPosts = posts;
          _applyPostFilters();
          _isLoadingPosts = false;
        });
      }
    }).catchError((err) {
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    });
  }

  void _applyPostFilters() {
    setState(() {
      _filteredPosts = _allPosts.where((p) {
        final matchAddress = p.address.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
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
          title: const Text('Roommate Hub', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          actions: [
            if (widget.currentUser.role == 'ROLE_ADMIN' || widget.currentUser.role == 'ADMIN')
              IconButton(
                tooltip: 'Trang Quản Trị Viên',
                icon: const Icon(Icons.admin_panel_settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                },
              ),
            IconButton(
              tooltip: 'Hộp thư kết nối',
              icon: const Icon(Icons.mail_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RequestsScreen(currentUserId: _currentUserId),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Cập nhật tiêu chí bạn trọ',
              icon: const Icon(Icons.tune),
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurveyScreen(userId: _currentUserId),
                  ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(currentUser: widget.currentUser),
                  ),
                );
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
            FutureBuilder<List<MatchRecommendation>>(
              future: _matchesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text('Không tìm thấy người phù hợp'));
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final item = list[i];
                    return MatchCard(
                      item: item,
                      onConnect: () async {
                        final ok = await _api.sendMatchRequest(_currentUserId, item.userId, item.totalScore);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'Đã gửi kết nối tới ${item.fullName}! Trạng thái: Đang chờ.'
                                  : 'Gửi kết nối thất bại!'),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),

            // TAB 2: BÀI ĐĂNG PHÒNG CÓ BỘ LỌC TÌM KIẾM
            Column(
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) {
                          _searchKeyword = val.trim();
                          _applyPostFilters();
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Giá tối đa: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            _maxPriceFilter >= 10000000 ? 'Tất cả' : fmt.format(_maxPriceFilter),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13),
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
                          ? const Center(child: Text('Không tìm thấy phòng phù hợp với tiêu chí lọc.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _filteredPosts.length,
                              itemBuilder: (context, i) {
                                final p = _filteredPosts[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.title,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text('Giá: ${fmt.format(p.price)}/tháng',
                                            style: const TextStyle(
                                                color: Colors.green, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('Địa chỉ: ${p.address}',
                                            style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                        const SizedBox(height: 6),
                                        Text(p.description,
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                        const Divider(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Người đăng: ${p.authorName}',
                                                style: const TextStyle(fontStyle: FontStyle.italic)),
                                            Text('Tối đa: ${p.maxOccupants} người',
                                                style: const TextStyle(fontWeight: FontWeight.w500)),
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
            final created = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatePostScreen(authorId: _currentUserId),
              ),
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