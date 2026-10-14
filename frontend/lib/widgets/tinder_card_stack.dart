import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/match_recommendation.dart';
import '../theme/discovery_palette.dart';
import '../services/api_service.dart';
import '../screens/room_details_screen.dart';

/// Tinder-style swipeable card stack for finding roommates.
class TinderCardStack extends StatefulWidget {
  final List<MatchRecommendation> candidates;
  final ValueChanged<MatchRecommendation> onConnect;
  final ValueChanged<MatchRecommendation> onPass;
  final ValueChanged<MatchRecommendation> onViewDetails;
  final VoidCallback? onRefresh;

  const TinderCardStack({
    super.key,
    required this.candidates,
    required this.onConnect,
    required this.onPass,
    required this.onViewDetails,
    this.onRefresh,
  });

  @override
  State<TinderCardStack> createState() => _TinderCardStackState();
}

class _TinderCardStackState extends State<TinderCardStack> {
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  final List<int> _history = [];

  void _swipe(bool isRight) {
    if (_currentIndex >= widget.candidates.length) return;
    final candidate = widget.candidates[_currentIndex];
    _history.add(_currentIndex);
    setState(() {
      _currentIndex++;
      _dragOffset = Offset.zero;
    });
    if (isRight) {
      widget.onConnect(candidate);
    } else {
      widget.onPass(candidate);
    }
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _currentIndex = _history.removeLast();
      _dragOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty || _currentIndex >= widget.candidates.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF8F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.done_all_rounded,
                  size: 40,
                  color: DiscoveryPalette.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bạn đã xem hết hồ sơ phù hợp!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF142523),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hãy thử đổi khu vực hoặc hạ mức điểm tối thiểu để tìm thấy thêm bạn cùng phòng.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF52625F),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_history.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: _undo,
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text('Xem lại vừa rồi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DiscoveryPalette.primary,
                        side: const BorderSide(color: DiscoveryPalette.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  if (_history.isNotEmpty) const SizedBox(width: 12),
                  if (widget.onRefresh != null)
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 0;
                          _history.clear();
                        });
                        widget.onRefresh!();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Tải lại'),
                      style: FilledButton.styleFrom(
                        backgroundColor: DiscoveryPalette.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final topCandidate = widget.candidates[_currentIndex];
    final nextCandidate = _currentIndex + 1 < widget.candidates.length
        ? widget.candidates[_currentIndex + 1]
        : null;

    final size = MediaQuery.of(context).size;
    final cardHeight = (size.height * 0.65).clamp(440.0, 560.0);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (nextCandidate != null)
                  Transform.scale(
                    scale: 0.94,
                    child: Transform.translate(
                      offset: const Offset(0, 18),
                      child: _SwipeCardContent(
                        candidate: nextCandidate,
                        height: cardHeight,
                        onViewDetails: () => widget.onViewDetails(nextCandidate),
                      ),
                    ),
                  ),
                GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _dragOffset += details.delta;
                    });
                  },
                  onPanEnd: (details) {
                    if (_dragOffset.dx > 100) {
                      _swipe(true);
                    } else if (_dragOffset.dx < -100) {
                      _swipe(false);
                    } else {
                      setState(() {
                        _dragOffset = Offset.zero;
                      });
                    }
                  },
                  child: Transform.translate(
                    offset: _dragOffset,
                    child: Transform.rotate(
                      angle: (_dragOffset.dx / size.width) * (math.pi / 12),
                      child: Stack(
                        children: [
                          _SwipeCardContent(
                            candidate: topCandidate,
                            height: cardHeight,
                            onViewDetails: () => widget.onViewDetails(topCandidate),
                          ),
                          // Stamp KẾT NỐI (Xanh)
                          if (_dragOffset.dx > 25)
                            Positioned(
                              top: 36,
                              left: 24,
                              child: Transform.rotate(
                                angle: -math.pi / 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF087E6B),
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'KẾT NỐI',
                                    style: TextStyle(
                                      color: const Color(0xFF087E6B).withOpacity(
                                        (_dragOffset.dx / 100).clamp(0.2, 1.0),
                                      ),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Stamp BỎ QUA (Đỏ)
                          if (_dragOffset.dx < -25)
                            Positioned(
                              top: 36,
                              right: 24,
                              child: Transform.rotate(
                                angle: math.pi / 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE53935),
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'BỎ QUA',
                                    style: TextStyle(
                                      color: const Color(0xFFE53935).withOpacity(
                                        (-_dragOffset.dx / 100).clamp(0.2, 1.0),
                                      ),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Action Controls Bar dưới đáy
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Nút Undo
              _FloatingActionButton(
                icon: Icons.replay_rounded,
                color: const Color(0xFFF09A37),
                size: 48,
                iconSize: 22,
                tooltip: 'Hoàn tác',
                onPressed: _history.isNotEmpty ? _undo : null,
              ),
              // Nút Bỏ qua (Pass)
              _FloatingActionButton(
                icon: Icons.close_rounded,
                color: const Color(0xFFE53935),
                size: 60,
                iconSize: 30,
                tooltip: 'Bỏ qua (Vuốt trái)',
                onPressed: () => _swipe(false),
              ),
              // Nút Xem chi tiết hồ sơ
              _FloatingActionButton(
                icon: Icons.info_outline_rounded,
                color: const Color(0xFF1976D2),
                size: 48,
                iconSize: 24,
                tooltip: 'Xem hồ sơ',
                onPressed: () => widget.onViewDetails(topCandidate),
              ),
              // Nút Kết nối (Connect)
              _FloatingActionButton(
                icon: Icons.favorite_rounded,
                color: const Color(0xFF087E6B),
                size: 60,
                iconSize: 32,
                tooltip: 'Kết nối (Vuốt phải)',
                onPressed: () => _swipe(true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FloatingActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final String tooltip;
  final VoidCallback? onPressed;

  const _FloatingActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: enabled ? 4 : 1,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: iconSize,
              color: enabled ? color : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeCardContent extends StatelessWidget {
  final MatchRecommendation candidate;
  final double height;
  final VoidCallback onViewDetails;

  const _SwipeCardContent({
    required this.candidate,
    required this.height,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ảnh chân dung full bleed
          Positioned.fill(
            child: _buildAvatar(candidate),
          ),
          // Gradient phủ đen dưới đáy để chữ dễ đọc
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.45, 0.72, 1.0],
                ),
              ),
            ),
          ),
          // Badge Điểm tương thích góc trên trái
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF087E6B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${candidate.totalScore.toStringAsFixed(0)}% phù hợp',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Badge Housing Status góc trên phải
          Positioned(
            top: 16,
            right: 16,
            child: candidate.hasRoom
                ? GestureDetector(
                    onTap: candidate.roomId != null
                        ? () async {
                            try {
                              final post = await ApiService().getRoomPost(
                                candidate.roomId!,
                              );
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RoomDetailsScreen(post: post),
                                  ),
                                );
                              }
                            } catch (_) {}
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7EE),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                        border: Border.all(color: const Color(0xFF1B7A43)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home, size: 15, color: Color(0xFF1B7A43)),
                          SizedBox(width: 5),
                          Text(
                            'Đã có phòng sẵn',
                            style: TextStyle(
                              color: Color(0xFF1B7A43),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF5FB),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                      border: Border.all(color: const Color(0xFF20639B)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 15,
                          color: Color(0xFF20639B),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Tìm bạn cùng thuê',
                          style: TextStyle(
                            color: Color(0xFF20639B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          // Thông tin ứng viên góc dưới
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        candidate.age == null
                            ? candidate.fullName
                            : '${candidate.fullName}, ${candidate.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFEAF8F5),
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      candidate.districtDisplay,
                      style: const TextStyle(
                        color: Color(0xFFEAF8F5),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (candidate.university?.trim().isNotEmpty == true) ...[
                      const Text('  •  ', style: TextStyle(color: Colors.white70)),
                      Expanded(
                        child: Text(
                          candidate.university!.trim(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (candidate.bioDescription?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    '“${candidate.bioDescription!.trim()}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(MatchRecommendation item) {
    final fallback = Container(
      color: const Color(0xFF1B3B36),
      alignment: Alignment.center,
      child: Text(
        item.fullName.trim().isEmpty ? '?' : item.fullName.trim()[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 72,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    if (item.avatarUrl?.trim().isEmpty != false) {
      return fallback;
    }
    return Image.network(
      item.avatarUrl!.trim(),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
