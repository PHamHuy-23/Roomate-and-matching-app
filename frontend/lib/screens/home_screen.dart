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
  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  late Future<List<MatchRecommendation>> _matchesFuture;
  late int _currentUserId;

  // Trạng thái cho bộ lọc phòng trọ
  List<RoomPost> _allPosts = [];
  List<RoomPost> _filteredPosts = [];
  bool _isLoadingPosts = true;
  String? _postsError;
  String _searchKeyword = '';
  double _minPriceFilter = 0;
  double _maxPriceFilter = 10000000;
  String? _selectedDistrictFilter;
  Set<String> _selectedAmenityFilters = {};

  // Danh sách tiện ích cho bộ lọc
  static const List<String> _filterAmenities = [
    'Wifi', 'Máy lạnh', 'Nước nóng', 'Máy giặt', 'Giữ xe', 'Giờ tự do',
  ];
  static const Map<String, String> _amenityEmojis = {
    'Wifi': '📶', 'Máy lạnh': '❄️', 'Nước nóng': '🚿',
    'Máy giặt': '🧺', 'Giữ xe': '🛵', 'Giờ tự do': '🔑',
  };

  // Danh sách quận cho bộ lọc
  static const List<String> _filterDistricts = [
    'Tất cả',
    'Quận 1',
    'Quận 3',
    'Quận 7',
    'Quận 9',
    'Quận 10',
    'Quận 12',
    'Bình Thạnh',
    'TP. Thủ Đức',
    'Gò Vấp',
    'Tân Bình',
    'Tân Phú',
    'Phú Nhuận',
    'Bình Tân',
  ];

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
      _postsError = null;
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
            setState(() {
              _isLoadingPosts = false;
              _postsError = err is Exception ? err.toString() : 'Lỗi không xác định';
            });
          }
        });
  }

  void _applyPostFilters() {
    setState(() {
      _filteredPosts = _allPosts.where((p) {
        // Lọc theo từ khóa tìm kiếm (tên đường, tiêu đề, quận)
        final keyword = _searchKeyword.toLowerCase();
        final matchKeyword = keyword.isEmpty ||
            p.address.toLowerCase().contains(keyword) ||
            p.title.toLowerCase().contains(keyword) ||
            p.district.toLowerCase().contains(keyword) ||
            p.authorName.toLowerCase().contains(keyword);

        // Lọc theo khoảng giá
        final matchPrice =
            p.price >= _minPriceFilter && p.price <= _maxPriceFilter;

        // Lọc theo quận
        final matchDistrict = _selectedDistrictFilter == null ||
            _selectedDistrictFilter == 'Tất cả' ||
            p.district == _selectedDistrictFilter ||
            p.address.contains(_selectedDistrictFilter!);

        // Lọc theo tiện ích (post phải chứa tất cả tiện ích đã chọn)
        final matchAmenities = _selectedAmenityFilters.isEmpty ||
            _selectedAmenityFilters.every((a) => p.amenities.contains(a));

        return matchKeyword && matchPrice && matchDistrict && matchAmenities;
      }).toList();
    });
  }

  /// Mở BottomSheet bộ lọc nâng cao
  void _showFilterBottomSheet() {
    // Tạo bản sao tạm để thao tác trong BottomSheet
    double tempMin = _minPriceFilter;
    double tempMax = _maxPriceFilter;
    String? tempDistrict = _selectedDistrictFilter;
    Set<String> tempAmenities = Set.from(_selectedAmenityFilters);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thanh handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    '🔍 Bộ lọc tìm phòng',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lọc theo Quận
                  const Text(
                    'Quận / Huyện',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filterDistricts.map((d) {
                      final isSelected = tempDistrict == d ||
                          (d == 'Tất cả' && tempDistrict == null);
                      return ChoiceChip(
                        label: Text(d),
                        selected: isSelected,
                        selectedColor: Colors.indigo.shade100,
                        onSelected: (selected) {
                          setModalState(() {
                            tempDistrict = selected
                                ? (d == 'Tất cả' ? null : d)
                                : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Lọc theo khoảng giá
                  Text(
                    'Khoảng giá: ${fmt.format(tempMin)} - ${tempMax >= 10000000 ? "Không giới hạn" : fmt.format(tempMax)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: RangeValues(tempMin, tempMax),
                    min: 0,
                    max: 10000000,
                    divisions: 20,
                    labels: RangeLabels(
                      fmt.format(tempMin),
                      tempMax >= 10000000
                          ? 'Max'
                          : fmt.format(tempMax),
                    ),
                    onChanged: (values) {
                      setModalState(() {
                        tempMin = values.start;
                        tempMax = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Lọc theo Tiện ích
                  const Text(
                    'Tiện ích mong muốn',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filterAmenities.map((a) {
                      final isSelected = tempAmenities.contains(a);
                      final emoji = _amenityEmojis[a] ?? '🔹';
                      return FilterChip(
                        label: Text('$emoji $a'),
                        selected: isSelected,
                        selectedColor: Colors.indigo.shade100,
                        checkmarkColor: Colors.indigo,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              tempAmenities.add(a);
                            } else {
                              tempAmenities.remove(a);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Nút Áp dụng
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempMin = 0;
                              tempMax = 10000000;
                              tempDistrict = null;
                              tempAmenities.clear();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Đặt lại'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _minPriceFilter = tempMin;
                              _maxPriceFilter = tempMax;
                              _selectedDistrictFilter = tempDistrict;
                              _selectedAmenityFilters = Set.from(tempAmenities);
                              _applyPostFilters();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Áp dụng bộ lọc',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
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
            // TAB 1: GỢI Ý BẠN TRỌ (giữ nguyên)
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
                  return const Center(
                    child: Text('Không tìm thấy người phù hợp'),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final item = list[i];
                    return MatchCard(
                      item: item,
                      onConnect: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await _api.sendMatchRequest(
                          _currentUserId,
                          item.userId,
                          item.totalScore,
                        );
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Đã gửi kết nối tới ${item.fullName}! Trạng thái: Đang chờ.'
                                  : 'Gửi kết nối thất bại!',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),

            // TAB 2: BÀI ĐĂNG PHÒNG TRỌ — GIAO DIỆN MỚI HIỆN ĐẠI
            _buildRoomPostsTab(),
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

  /// TAB 2: Bảng tin Phòng trọ hiện đại
  Widget _buildRoomPostsTab() {
    return Column(
      children: [
        // ===== THANH TÌM KIẾM + NÚT LỌC =====
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thanh tìm kiếm
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo khu vực, đường, tên bài...',
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo),
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
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (val) {
                    _searchKeyword = val.trim();
                    _applyPostFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Nút mở BottomSheet lọc
              Material(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _showFilterBottomSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Badge(
                      isLabelVisible: _selectedDistrictFilter != null ||
                          _minPriceFilter > 0 ||
                          _maxPriceFilter < 10000000 ||
                          _selectedAmenityFilters.isNotEmpty,
                      backgroundColor: Colors.deepOrange,
                      child: const Icon(
                        Icons.tune,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Hiển thị bộ lọc đang áp dụng (nếu có)
        if (_selectedDistrictFilter != null ||
            _minPriceFilter > 0 ||
            _maxPriceFilter < 10000000 ||
            _selectedAmenityFilters.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.indigo.shade50,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (_selectedDistrictFilter != null)
                  Chip(
                    label: Text('📍 $_selectedDistrictFilter',
                        style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _selectedDistrictFilter = null;
                        _applyPostFilters();
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                if (_minPriceFilter > 0 || _maxPriceFilter < 10000000)
                  Chip(
                    label: Text(
                      '💰 ${fmt.format(_minPriceFilter)} - ${_maxPriceFilter >= 10000000 ? "Max" : fmt.format(_maxPriceFilter)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _minPriceFilter = 0;
                        _maxPriceFilter = 10000000;
                        _applyPostFilters();
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ..._selectedAmenityFilters.map((a) {
                  final emoji = _amenityEmojis[a] ?? '🔹';
                  return Chip(
                    label: Text('$emoji $a',
                        style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _selectedAmenityFilters.remove(a);
                        _applyPostFilters();
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }),
              ],
            ),
          ),

        // ===== DANH SÁCH BÀI ĐĂNG =====
        Expanded(
          child: _isLoadingPosts
              ? const Center(child: CircularProgressIndicator())
              : _postsError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off,
                              size: 64, color: Colors.red.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Không thể tải danh sách phòng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              _postsError!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredPosts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'Không tìm thấy phòng phù hợp',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _searchKeyword = '';
                                    _minPriceFilter = 0;
                                    _maxPriceFilter = 10000000;
                                    _selectedDistrictFilter = null;
                                    _selectedAmenityFilters = {};
                                    _applyPostFilters();
                                  });
                                },
                                child: const Text('Xóa bộ lọc'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _loadData(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filteredPosts.length,
                            itemBuilder: (context, i) {
                              final p = _filteredPosts[i];
                              return _buildRoomPostCard(p);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  /// Thẻ bài đăng phòng trọ hiện đại với ảnh, huy hiệu quận, tiện ích
  Widget _buildRoomPostCard(RoomPost p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.roomDetail,
            arguments: p,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== ẢNH PHÒNG 16:9 + HUY HIỆU QUẬN =====
            Stack(
              children: [
                // Ảnh phòng (hoặc placeholder gradient)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                      ? Image.network(
                          p.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildCardImagePlaceholder(p),
                        )
                      : _buildCardImagePlaceholder(p),
                ),
                // Huy hiệu Quận nổi bật trên ảnh
                if (p.district.isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '📍 ${p.district}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  ),
                // Giá nổi bật góc dưới phải
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade600,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '${fmt.format(p.price)}/tháng',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ===== THÔNG TIN BÀI ĐĂNG =====
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text(
                p.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Địa chỉ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                p.address,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),

            // Hàng icon tiện ích thu nhỏ
            if (p.amenities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: p.amenities.take(4).map((a) {
                    final emoji = RoomPost.amenityIcons[a] ?? '🔹';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$emoji $a',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Người đăng + thời gian
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      p.authorName.isNotEmpty
                          ? p.authorName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.authorName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (p.timeAgo.isNotEmpty)
                    Text(
                      p.timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  if (p.maxOccupants > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '👥 ${p.currentOccupants}/${p.maxOccupants}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder ảnh gradient cho Card bài đăng
  Widget _buildCardImagePlaceholder(RoomPost p) {
    // Dùng màu khác nhau theo quận để tạo sự đa dạng
    final colors = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
      [const Color(0xFFa18cd1), const Color(0xFFfbc2eb)],
    ];
    final colorPair = colors[p.id % colors.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorPair,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_work, size: 40, color: Colors.white54),
            const SizedBox(height: 4),
            Text(
              p.district.isNotEmpty ? p.district : 'Phòng trọ',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
