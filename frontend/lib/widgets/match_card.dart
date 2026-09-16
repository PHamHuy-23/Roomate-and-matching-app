import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/match_recommendation.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.item,
    required this.onViewDetails,
    required this.onConnect,
    this.isConnecting = false,
    this.requestSent = false,
  });

  static const _primary = Color(0xFF008F7A);

  final MatchRecommendation item;
  final VoidCallback onViewDetails;
  final VoidCallback onConnect;
  final bool isConnecting;
  final bool requestSent;

  ({Color background, Color foreground}) _scoreColors(double score) {
    if (score >= 80) {
      return (
        background: const Color(0xFFDDF4E8),
        foreground: const Color(0xFF087443),
      );
    }
    if (score >= 60) {
      return (
        background: const Color(0xFFFFE8C7),
        foreground: const Color(0xFF9A5B00),
      );
    }
    return (
      background: const Color(0xFFE8ECEB),
      foreground: const Color(0xFF596662),
    );
  }

  List<String> get _habitHighlights {
    if (item.matchedReasons.isNotEmpty) {
      return item.matchedReasons.take(2).toList();
    }
    final scores = <({String label, double score})>[
      (label: 'Ngân sách tương đồng', score: item.criteriaDetail.budgetMatch),
      (label: 'Giờ sinh hoạt phù hợp', score: item.criteriaDetail.sleepMatch),
      (
        label: 'Mức độ sạch sẽ tương đồng',
        score: item.criteriaDetail.cleanlinessMatch,
      ),
      (
        label: 'Thói quen hút thuốc phù hợp',
        score: item.criteriaDetail.smokingMatch,
      ),
      (
        label: 'Quan điểm thú cưng phù hợp',
        score: item.criteriaDetail.petMatch,
      ),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return scores.take(2).map((entry) => entry.label).toList();
  }

  String get _secondaryText {
    final parts = <String>[];
    if (item.age != null) parts.add('${item.age} tuổi');
    if (item.university?.trim().isNotEmpty == true) {
      parts.add(item.university!.trim());
    }
    return parts.isEmpty
        ? 'Ứng viên tại ${item.targetDistrict}'
        : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.compactCurrency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final colors = _scoreColors(item.totalScore);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2EAE7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(item: item),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17342F),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _secondaryText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF687873),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 15, color: colors.foreground),
                      const SizedBox(width: 2),
                      Text(
                        'Match ${item.totalScore.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: colors.foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.location_on_outlined,
                  label: item.targetDistrict,
                ),
                _InfoChip(
                  icon: Icons.payments_outlined,
                  label: '${formatter.format(item.budgetAmount)}/tháng',
                ),
                for (final highlight in _habitHighlights)
                  _InfoChip(icon: Icons.check_circle_outline, label: highlight),
              ],
            ),
            if (item.bioDescription?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                item.bioDescription!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF52645F), height: 1.35),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: Color(0xFFB9DDD5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: const Text(
                      'Xem đối chiếu',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: requestSent || isConnecting ? null : onConnect,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: isConnecting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(requestSent ? 'Đã gửi lời mời' : 'Gửi lời mời'),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.item});

  final MatchRecommendation item;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFCFF3EC),
        shape: BoxShape.circle,
      ),
      child: Text(
        item.fullName.trim().isEmpty
            ? '?'
            : item.fullName.trim()[0].toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF007C6A),
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    if (item.avatarUrl?.trim().isEmpty != false) {
      return fallback;
    }
    return ClipOval(
      child: Image.network(
        item.avatarUrl!.trim(),
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6F4),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF4D6760)),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF425A54)),
            ),
          ),
        ],
      ),
    );
  }
}
