import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/auth_user.dart';
import '../models/match_recommendation.dart';
import '../models/match_request_item.dart';
import '../models/room_post.dart';
import '../models/district_names.dart';
import '../navigation/app_routes.dart';
import 'candidate_profile_screen.dart';
import 'room_details_screen.dart';
import 'room_filters_screen.dart';
import 'saved_rooms_screen.dart';
import 'listing_management_screen.dart';
import '../services/api_service.dart';
import 'penpot_state_screens.dart';
import '../theme/discovery_palette.dart';
import '../widgets/match_card.dart';

class HomeScreen extends StatefulWidget {
  final AuthUser currentUser;
  final int initialTab;
  final ApiService? apiService;

  const HomeScreen({
    super.key,
    required this.currentUser,
    this.initialTab = 0,
    this.apiService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _discoveryPrimary = DiscoveryPalette.primary;

  late final ApiService _api = widget.apiService ?? ApiService();
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  late Future<List<MatchRecommendation>> _matchesFuture;
  late int _currentUserId;
  int _selectedHomeTab = 0;

  // Trạng thái cho bộ lọc phòng trọ
  List<RoomPost> _allPosts = [];
  List<RoomPost> _filteredPosts = [];
  bool _isLoadingPosts = true;
  bool _postsLoadError = false;
  String _searchKeyword = '';
  final TextEditingController _roomSearchController = TextEditingController();
  // Quick filters are opt-in. Keep the initial room list unfiltered so the
  // chips below accurately reflect the current state.
  double _minPriceFilter = 0;
  double _maxPriceFilter = double.infinity;
  double _minAreaFilter = 0;
  String _roomDistrictFilter = 'Tất cả khu vực';
  final Set<String> _roomAmenitiesFilter = <String>{};
  bool _quickPriceActive = false;
  bool _quickNearbyActive = false;

  // Trạng thái tìm kiếm và lọc ứng viên bạn trọ.
  String _matchSearchKeyword = '';
  double _minimumMatchScore = 0;
  String _districtFilter = 'Tất cả';
  final Set<int> _connectingUserIds = {};
  final Set<int> _savingPostIds = {};
  final Map<int, MatchRequestItem> _connectionRequests = {};
  Set<int> get _savedPostIds => _api.savedPostIds;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.currentUser.userId;
    _selectedHomeTab = widget.initialTab.clamp(0, 1).toInt();
    _loadData();
  }

  @override
  void dispose() {
    _roomSearchController.dispose();
    super.dispose();
  }

  void _loadData() {
    _loadSavedPosts();
    setState(() {
      _matchesFuture = _api.getRecommendations(_currentUserId);
      _isLoadingPosts = true;
      _postsLoadError = false;
    });

    _api
        .getRoomPosts()
        .then((posts) {
          if (mounted) {
            setState(() {
              _allPosts = posts;
              _applyPostFilters();
              _isLoadingPosts = false;
              _postsLoadError = false;
            });
          }
        })
        .catchError((err) {
          if (mounted) {
            setState(() {
              _isLoadingPosts = false;
              _postsLoadError = true;
            });
          }
        });
  }

  void _applyPostFilters() {
    final query = DistrictNames.fold(_searchKeyword);
    _filteredPosts = _allPosts.where((p) {
      final matchAddress =
          DistrictNames.fold(p.address).contains(query) ||
          DistrictNames.fold(p.title).contains(query) ||
          DistrictNames.fold(
            DistrictNames.display(p.district),
          ).contains(query) ||
          DistrictNames.fold(
            DistrictNames.canonical(p.district),
          ).contains(query);
      final matchPrice =
          p.price >= _minPriceFilter && p.price <= _maxPriceFilter;
      final matchDistrict =
          _roomDistrictFilter == 'Tất cả khu vực' ||
          DistrictNames.matchesRoom(
            district: p.district,
            address: p.address,
            selected: _roomDistrictFilter,
          );
      // Area and amenities are optional in older API payloads. An active
      // filter must not silently match a post whose value is unknown.
      final matchArea =
          _minAreaFilter == 0 ||
          (p.areaM2 != null && p.areaM2! >= _minAreaFilter);
      final postAmenities = p.amenities
          .map((amenity) => amenity.trim().toLowerCase())
          .toSet();
      final matchAmenities =
          _roomAmenitiesFilter.isEmpty ||
          (p.amenities.isNotEmpty &&
              _roomAmenitiesFilter.every(
                (amenity) => postAmenities.contains(amenity.toLowerCase()),
              ));
      return matchAddress &&
          matchPrice &&
          matchDistrict &&
          matchArea &&
          matchAmenities;
    }).toList();
  }

  Future<void> _refreshMatches() async {
    final refreshed = _api.getRecommendations(_currentUserId);
    setState(() => _matchesFuture = refreshed);
    await refreshed;
  }

  Future<MatchRequestItem?> _sendMatchRequest(MatchRecommendation item) async {
    if (_connectingUserIds.contains(item.userId)) {
      return null;
    }

    setState(() => _connectingUserIds.add(item.userId));
    final messenger = ScaffoldMessenger.of(context);
    try {
      final request = await _api.sendMatchRequest(item.userId);
      if (!mounted) return null;
      setState(() => _connectionRequests[item.userId] = request);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            request.status == 'ACCEPTED'
                ? 'Bạn và ${request.partnerName} đã kết nối!'
                : 'Đã gửi lời mời tới ${request.partnerName}!',
          ),
        ),
      );
      return request;
    } on ApiException catch (error) {
      if (!mounted) return null;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      return null;
    } catch (_) {
      if (!mounted) return null;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không thể gửi lời mời, vui lòng thử lại.'),
        ),
      );
      return null;
    } finally {
      if (mounted) {
        setState(() => _connectingUserIds.remove(item.userId));
      }
    }
  }

  void _openCandidateProfile(MatchRecommendation item) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CandidateProfileScreen(
          item: item,
          initialRequest: _connectionRequests[item.userId],
          onConnect: () => _sendMatchRequest(item),
        ),
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
    final query = DistrictNames.fold(_matchSearchKeyword);
    final filtered = source.where((item) {
      final matchesSearch =
          query.isEmpty ||
          DistrictNames.fold(item.fullName).contains(query) ||
          DistrictNames.fold(
            DistrictNames.display(item.targetDistrict),
          ).contains(query) ||
          DistrictNames.fold(
            DistrictNames.canonical(item.targetDistrict),
          ).contains(query) ||
          (item.university != null &&
              DistrictNames.fold(item.university!).contains(query));
      final matchesScore = item.totalScore >= _minimumMatchScore;
      final matchesDistrict =
          _districtFilter == 'Tất cả' ||
          DistrictNames.same(item.targetDistrict, _districtFilter);
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
                .map((item) => DistrictNames.canonical(item.targetDistrict))
                .where((district) => district.trim().isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        if (_districtFilter != 'Tất cả' &&
            !districts.contains(_districtFilter)) {
          _districtFilter = 'Tất cả';
        }
        final matches = _filterMatches(allMatches);
        return Material(
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
                    onNotificationsPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                    onAdminPressed:
                        {
                          'ADMIN',
                          'ROLE_ADMIN',
                        }.contains(widget.currentUser.role.trim().toUpperCase())
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
                          onViewDetails: () => _openCandidateProfile(item),
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
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            'Một nơi để gọi là nhà',
                            style: TextStyle(
                              color: Color(0xFF142523),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: _openRoomFilters,
                              style: TextButton.styleFrom(
                                foregroundColor: _discoveryPrimary,
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('Lọc'),
                            ),
                            IconButton(
                              tooltip: 'Phòng đã lưu',
                              onPressed: _openSavedRooms,
                              icon: const Icon(
                                Icons.bookmark_border,
                                color: _discoveryPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: _discoveryPrimary,
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Bình Thạnh, TP. Hồ Chí Minh',
                          style: TextStyle(
                            color: Color(0xFF52625F),
                            fontSize: 13,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF52625F),
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _roomSearchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm khu vực, trường học…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchKeyword.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() {
                                  _roomSearchController.clear();
                                  _searchKeyword = '';
                                  _applyPostFilters();
                                }),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFDCE6E3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFDCE6E3),
                          ),
                        ),
                      ),
                      onChanged: (value) => setState(() {
                        _searchKeyword = value.trim();
                        _applyPostFilters();
                      }),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _quickFilter(
                            label: 'Dưới 4 triệu',
                            selected: _quickPriceActive,
                            onTap: () => setState(() {
                              _quickPriceActive = !_quickPriceActive;
                              if (_quickPriceActive) {
                                _minPriceFilter = 0;
                                _maxPriceFilter = 4000000;
                              } else {
                                _minPriceFilter = 0;
                                _maxPriceFilter = double.infinity;
                              }
                              _applyPostFilters();
                            }),
                          ),
                          const SizedBox(width: 8),
                          _quickFilter(
                            label: 'Có nội thất',
                            selected: _roomAmenitiesFilter.contains('Nội thất'),
                            onTap: _toggleFurnitureFilter,
                          ),
                          const SizedBox(width: 8),
                          _quickFilter(
                            label: 'Gần bạn',
                            selected: _quickNearbyActive,
                            onTap: () => setState(() {
                              _quickNearbyActive = !_quickNearbyActive;
                              _roomDistrictFilter = _quickNearbyActive
                                  ? 'Bình Thạnh, TP.HCM'
                                  : 'Tất cả khu vực';
                              _applyPostFilters();
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'CÒN PHÒNG',
                      style: TextStyle(
                        color: _discoveryPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoadingPosts)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: PenpotStateView(
                  icon: Icons.home_work_outlined,
                  title: 'Đang tìm những lựa chọn dành cho bạn',
                  description: null,
                  loading: true,
                ),
              )
            else if (_postsLoadError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: PenpotStateView(
                  icon: Icons.priority_high_rounded,
                  title: 'Chưa tải được dữ liệu',
                  description:
                      'Kiểm tra kết nối mạng rồi thử lại.\nCác thông tin bạn đã lưu vẫn được giữ.',
                  actionLabel: 'Thử tải lại',
                  onAction: _loadData,
                ),
              )
            else if (_filteredPosts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: PenpotStateView(
                  icon: Icons.check_circle_outline,
                  title: 'Chưa tìm thấy phòng phù hợp',
                  description:
                      'Thử tăng khoảng giá hoặc chọn thêm\nkhu vực lân cận để có nhiều lựa chọn hơn.',
                  actionLabel: 'Điều chỉnh bộ lọc',
                  onAction: _openRoomFilters,
                  secondaryActionLabel: 'Xem tất cả phòng',
                  onSecondaryAction: () => setState(() {
                    _roomSearchController.clear();
                    _searchKeyword = '';
                    _minPriceFilter = 0;
                    _maxPriceFilter = double.infinity;
                    _minAreaFilter = 0;
                    _roomDistrictFilter = 'Tất cả khu vực';
                    _quickPriceActive = false;
                    _quickNearbyActive = false;
                    _roomAmenitiesFilter.clear();
                    _applyPostFilters();
                  }),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverList.builder(
                  itemCount: _filteredPosts.length,
                  itemBuilder: (context, index) =>
                      _roomCard(_filteredPosts[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quickFilter({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _discoveryPrimary.withValues(alpha: .14),
      checkmarkColor: _discoveryPrimary,
      side: BorderSide(
        color: selected ? _discoveryPrimary : const Color(0xFFD3E0DC),
      ),
      labelStyle: TextStyle(
        color: selected ? _discoveryPrimary : const Color(0xFF142523),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  void _toggleFurnitureFilter() {
    if (_allPosts.isNotEmpty &&
        !_allPosts.any((post) => post.amenities.isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bộ lọc nội thất sẽ hoạt động khi API trả về thông tin tiện ích.',
          ),
        ),
      );
      return;
    }

    setState(() {
      if (!_roomAmenitiesFilter.add('Nội thất')) {
        _roomAmenitiesFilter.remove('Nội thất');
      }
      _applyPostFilters();
    });
  }

  Widget _roomCard(RoomPost post) {
    final area = post.areaM2 == null ? '28 m²' : '${post.areaM2!.round()} m²';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () =>
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => RoomDetailsScreen(post: post),
              ),
            ).then((_) {
              if (mounted) setState(() {});
            }),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 170,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _roomImage(post.imageUrl),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.white.withValues(alpha: .92),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: _savedPostIds.contains(post.id)
                            ? 'Bỏ lưu phòng'
                            : 'Lưu phòng',
                        icon: Icon(
                          _savedPostIds.contains(post.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _discoveryPrimary,
                        ),
                        onPressed: _savingPostIds.contains(post.id)
                            ? null
                            : () => _toggleSavedPost(post.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF142523),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${post.address} • $area • ${post.maxOccupants} người',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF52625F),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    fmt.format(post.price),
                    style: const TextStyle(
                      color: _discoveryPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    '/ tháng',
                    style: TextStyle(color: Color(0xFF52625F)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomImage(String? imageUrl) {
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _roomImageFallback(),
      );
    }
    return _roomImageFallback();
  }

  Widget _roomImageFallback() => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFD7EDE7), Color(0xFF9BC8BC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(Icons.home_work_outlined, color: _discoveryPrimary, size: 64),
    ),
  );

  Future<void> _createRoomPost() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ListingManagementScreen(
          mode: ListingFlowMode.myListings,
          authorId: _currentUserId,
        ),
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _loadSavedPosts() async {
    if (!_api.hasAuthToken) return;
    try {
      await _api.loadSavedPosts();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được phòng đã lưu: $e')),
        );
      }
    }
  }

  Future<void> _toggleSavedPost(int postId) async {
    setState(() => _savingPostIds.add(postId));
    try {
      await _api.toggleSavePost(postId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không lưu được phòng: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingPostIds.remove(postId));
    }
  }

  Future<void> _openRoomFilters() async {
    final selection = await Navigator.push<RoomFilterSelection>(
      context,
      MaterialPageRoute<RoomFilterSelection>(
        builder: (_) => RoomFiltersScreen(
          initialMinPrice: _minPriceFilter,
          initialMaxPrice: _maxPriceFilter,
          initialDistrict: _roomDistrictFilter,
          initialMinArea: _minAreaFilter,
          initialAmenities: _roomAmenitiesFilter,
        ),
      ),
    );
    if (selection == null || !mounted) return;
    setState(() {
      _minPriceFilter = selection.minPrice;
      _maxPriceFilter = selection.maxPrice;
      _minAreaFilter = selection.minArea;
      _roomDistrictFilter = selection.district;
      _quickPriceActive =
          selection.minPrice == 0 && selection.maxPrice <= 4000000;
      _quickNearbyActive = selection.district == 'Bình Thạnh, TP.HCM';
      _roomAmenitiesFilter
        ..clear()
        ..addAll(selection.amenities);
      _applyPostFilters();
    });
  }

  void _openSavedRooms() {
    final saved = _allPosts
        .where((post) => _savedPostIds.contains(post.id))
        .toList();
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SavedRoomsScreen(
          posts: saved,
          onUnsave: (postId) async {
            await _api.setPostSaved(postId, false);
            if (mounted) setState(() {});
          },
        ),
      ),
    );
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
            label: 'Phòng trọ',
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
    required this.onNotificationsPressed,
    this.onAdminPressed,
  });

  final String userName;
  final int resultCount;
  final String selectedDistrict;
  final bool filtersActive;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFiltersPressed;
  final VoidCallback onPreferencesPressed;
  final VoidCallback onNotificationsPressed;
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
                  'Tìm bạn cùng nhịp sống',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: DiscoveryPalette.text,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Thông báo',
                onPressed: onNotificationsPressed,
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: DiscoveryPalette.primary,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Tùy chọn',
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: DiscoveryPalette.primarySoftStrong,
                  child: Text(
                    firstName.isEmpty ? '?' : firstName[0].toUpperCase(),
                    style: const TextStyle(
                      color: DiscoveryPalette.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
          const SizedBox(height: 4),
          const Text(
            'Gợi ý dựa trên 5 tiêu chí của bạn',
            style: TextStyle(color: DiscoveryPalette.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DiscoveryPalette.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Một người hợp, một tổ ấm vui.',
                  style: TextStyle(
                    color: DiscoveryPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: onPreferencesPressed,
                  child: const Text(
                    'Tiêu chí đã cập nhật · Điều chỉnh →',
                    style: TextStyle(
                      color: DiscoveryPalette.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            textColor: DiscoveryPalette.primary,
            iconColor: DiscoveryPalette.primary,
            title: Text(
              filtersActive || selectedDistrict != 'Tất cả'
                  ? 'Tìm kiếm và lọc · $resultCount gợi ý'
                  : 'Tìm kiếm và lọc gợi ý',
              style: const TextStyle(
                color: DiscoveryPalette.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              TextField(
                key: const Key('match-search-field'),
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm tên, trường hoặc khu vực...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: DiscoveryPalette.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('match-filter-button'),
                  onPressed: onFiltersPressed,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Bộ lọc'),
                ),
              ),
            ],
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
                  DropdownMenuItem(
                    value: district,
                    child: Text(DistrictNames.display(district)),
                  ),
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
