import 'package:flutter/material.dart';

import '../models/match_recommendation.dart';
import '../theme/discovery_palette.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.item, required this.onViewDetails});

  final MatchRecommendation item;
  final VoidCallback onViewDetails;

  ({Color background, Color foreground}) _scoreColors(double score) {
    if (score >= 80) {
      return (
        background: const Color(0xFFEAF7F0),
        foreground: DiscoveryPalette.primary,
      );
    }
    if (score >= 60) {
      return (
        background: const Color(0xFFFFF6E7),
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
      const shortLabels = {
        'Ngân sách phù hợp': 'Ngân sách hợp',
        'Giờ sinh hoạt phù hợp': 'Giờ ngủ hợp',
        'Mức độ sạch sẽ tương đồng': 'Sạch sẽ',
        'Thói quen hút thuốc phù hợp': 'Hút thuốc hợp',
        'Quan điểm thú cưng phù hợp': 'Thú cưng hợp',
      };
      return item.matchedReasons
          .take(2)
          .map((reason) => shortLabels[reason] ?? reason)
          .toList();
    }
    final scores = <({String label, double score})>[
      (label: 'Ngân sách hợp', score: item.criteriaDetail.budgetMatch),
      (label: 'Giờ ngủ hợp', score: item.criteriaDetail.sleepMatch),
      (label: 'Sạch sẽ', score: item.criteriaDetail.cleanlinessMatch),
      (label: 'Hút thuốc hợp', score: item.criteriaDetail.smokingMatch),
      (label: 'Thú cưng hợp', score: item.criteriaDetail.petMatch),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return scores.take(2).map((entry) => entry.label).toList();
  }

  String get _secondaryText {
    final parts = <String>[item.fullName];
    if (item.age != null) parts.add('${item.age}');
    return parts.join(' · ');
  }

  String get _universityText {
    if (item.university?.trim().isNotEmpty == true) {
      return '${item.university!.trim()} · ${item.targetDistrict}';
    }
    return item.targetDistrict;
  }

  String get _budgetText {
    final millions = item.budgetAmount / 1000000;
    final value = millions == millions.roundToDouble()
        ? millions.toStringAsFixed(0)
        : millions.toStringAsFixed(1);
    return '$value triệu/tháng';
  }

  @override
  Widget build(BuildContext context) {
    final colors = _scoreColors(item.totalScore);
    final habits = _habitHighlights;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: DiscoveryPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: DiscoveryPalette.border),
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
                        _secondaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: DiscoveryPalette.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _universityText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: DiscoveryPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${item.totalScore.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: colors.foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '$_budgetText · ${item.targetDistrict}',
              style: const TextStyle(
                fontSize: 12,
                color: DiscoveryPalette.text,
                height: 1.35,
              ),
            ),
            if (habits.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var index = 0; index < habits.length; index++)
                    _HabitChip(label: habits[index], accented: index.isOdd),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onViewDetails,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Xem lý do tương thích'),
                style: TextButton.styleFrom(
                  foregroundColor: DiscoveryPalette.primary,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitChip extends StatelessWidget {
  const _HabitChip({required this.label, required this.accented});

  final String label;
  final bool accented;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accented
              ? DiscoveryPalette.accentSoft
              : DiscoveryPalette.primarySoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accented
                ? DiscoveryPalette.accent
                : DiscoveryPalette.primary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
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
        color: DiscoveryPalette.primarySoftStrong,
        shape: BoxShape.circle,
      ),
      child: Text(
        item.fullName.trim().isEmpty
            ? '?'
            : item.fullName.trim()[0].toUpperCase(),
        style: const TextStyle(
          color: DiscoveryPalette.primary,
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
