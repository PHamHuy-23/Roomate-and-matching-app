import 'package:flutter/material.dart';

import '../models/match_recommendation.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.item, required this.onViewDetails});

  static const _primary = Color(0xFF008F7A);

  final MatchRecommendation item;
  final VoidCallback onViewDetails;

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
    final parts = <String>[item.fullName];
    if (item.age != null) parts.add('${item.age}');
    return parts.join(' · ');
  }

  String get _universityText {
    if (item.university?.trim().isNotEmpty == true) {
      return item.university!.trim();
    }
    return 'Sinh viên tại ${item.targetDistrict}';
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
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2EAE7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                          color: Color(0xFF17342F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _universityText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF687873),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.totalScore.toStringAsFixed(0)}% phù hợp',
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
            const SizedBox(height: 11),
            Text(
              '${item.targetDistrict} · $_budgetText',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF52645F),
                height: 1.35,
              ),
            ),
            if (habits.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                habits.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF52645F),
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onViewDetails,
                style: FilledButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFE2F6F1),
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Xem lý do tương thích',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
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
