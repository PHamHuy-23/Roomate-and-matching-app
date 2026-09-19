import 'package:flutter/material.dart';

import '../models/match_recommendation.dart';
import '../theme/discovery_palette.dart';

class CompatibilityBottomSheet extends StatelessWidget {
  const CompatibilityBottomSheet({
    super.key,
    required this.item,
    required this.onConnect,
    this.isConnecting = false,
    this.requestSent = false,
  });

  final MatchRecommendation item;
  final Future<void> Function() onConnect;
  final bool isConnecting;
  final bool requestSent;

  List<({String label, double score})> get _criteria => [
    (label: 'Ngân sách', score: item.criteriaDetail.budgetMatch),
    (label: 'Giờ ngủ', score: item.criteriaDetail.sleepMatch),
    (label: 'Sạch sẽ', score: item.criteriaDetail.cleanlinessMatch),
    (label: 'Hút thuốc', score: item.criteriaDetail.smokingMatch),
    (label: 'Thú cưng', score: item.criteriaDetail.petMatch),
  ];

  List<String> get _highlights {
    if (item.matchedReasons.isNotEmpty) {
      return item.matchedReasons.take(2).toList();
    }
    return _criteria
        .where((criterion) => criterion.score >= 80)
        .take(2)
        .map(
          (criterion) =>
              '${criterion.label}: ${criterion.score.toStringAsFixed(0)}%',
        )
        .toList();
  }

  List<String> get _attentionPoints => _criteria
      .where((criterion) => criterion.score < 70)
      .map(
        (criterion) =>
            '${criterion.label}: ${criterion.score.toStringAsFixed(0)}% — nên trao đổi thêm',
      )
      .toList();

  String get _scoreDescription {
    if (item.totalScore >= 80) return 'Rất phù hợp';
    if (item.totalScore >= 60) return 'Khá phù hợp';
    return 'Cần trao đổi thêm';
  }

  Color _scoreColor(double score) =>
      score >= 70 ? DiscoveryPalette.primary : DiscoveryPalette.warning;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            decoration: const BoxDecoration(
              color: DiscoveryPalette.canvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Độ tương thích',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: DiscoveryPalette.text,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    'Với ${item.fullName}',
                    style: const TextStyle(color: DiscoveryPalette.muted),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 156,
                      height: 156,
                      decoration: const BoxDecoration(
                        color: DiscoveryPalette.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${item.totalScore.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: DiscoveryPalette.primary,
                            ),
                          ),
                          Text(
                            _scoreDescription,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: DiscoveryPalette.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final criterion in _criteria)
                    _CriterionProgress(
                      label: criterion.label,
                      score: criterion.score,
                      color: _scoreColor(criterion.score),
                    ),
                  if (_highlights.isNotEmpty) ...[
                    _InsightPanel(
                      title: 'Điểm nổi bật',
                      icon: Icons.check_circle_outline,
                      color: DiscoveryPalette.primary,
                      backgroundColor: DiscoveryPalette.primarySoft,
                      items: _highlights,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _InsightPanel(
                    title: 'Điểm cần trao đổi',
                    icon: Icons.chat_bubble_outline,
                    color: const Color(0xFF9A5B00),
                    backgroundColor: const Color(0xFFFFF6E7),
                    items: _attentionPoints.isEmpty
                        ? const ['Chưa có tiêu chí nào dưới 70%.']
                        : _attentionPoints,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: requestSent || isConnecting ? null : onConnect,
                      style: FilledButton.styleFrom(
                        backgroundColor: DiscoveryPalette.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                          : Text(
                              requestSent
                                  ? 'Đã gửi yêu cầu kết nối'
                                  : 'Gửi yêu cầu kết nối',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CriterionProgress extends StatelessWidget {
  const _CriterionProgress({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final double score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: DiscoveryPalette.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0, 1),
              minHeight: 7,
              color: color,
              backgroundColor: DiscoveryPalette.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.title,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text('• $item', style: const TextStyle(height: 1.35)),
            ),
        ],
      ),
    );
  }
}
