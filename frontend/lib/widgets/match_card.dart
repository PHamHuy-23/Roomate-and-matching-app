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
    return item.age == null ? item.fullName : '${item.fullName}, ${item.age}';
  }

  String get _universityText {
    if (item.university?.trim().isNotEmpty == true) {
      return '${item.university!.trim()} • ${item.targetDistrict}';
    }
    return item.targetDistrict;
  }

  @override
  Widget build(BuildContext context) {
    final colors = _scoreColors(item.totalScore);
    final habits = _habitHighlights;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 18),
      color: DiscoveryPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CandidatePhoto(item: item, height: 230),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${item.totalScore.toStringAsFixed(0)}% phù hợp',
                    style: TextStyle(
                      color: colors.foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _secondaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: DiscoveryPalette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _universityText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: DiscoveryPalette.muted,
                  ),
                ),
                if (habits.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var index = 0; index < habits.length; index++)
                        _HabitChip(label: habits[index], accented: index.isOdd),
                    ],
                  ),
                ],
                if (item.bioDescription?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  Text(
                    '“${item.bioDescription!.trim()}”',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DiscoveryPalette.text,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: onViewDetails,
                    style: FilledButton.styleFrom(
                      backgroundColor: DiscoveryPalette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Xem hồ sơ & độ phù hợp'),
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

class CandidatePhoto extends StatelessWidget {
  const CandidatePhoto({super.key, required this.item, required this.height});

  final MatchRecommendation item;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DiscoveryPalette.primarySoftStrong,
            DiscoveryPalette.primarySoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        item.fullName.trim().isEmpty
            ? '?'
            : item.fullName.trim()[0].toUpperCase(),
        style: TextStyle(
          color: DiscoveryPalette.primary,
          fontSize: (height * 0.32).clamp(24, 64).toDouble(),
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    if (item.avatarUrl?.trim().isEmpty != false) {
      return fallback;
    }
    return Image.network(
      item.avatarUrl!.trim(),
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
