import 'package:flutter/material.dart';

import '../models/match_recommendation.dart';

class CompatibilityBottomSheet extends StatelessWidget {
  const CompatibilityBottomSheet({
    super.key,
    required this.item,
    required this.onConnect,
    this.isConnecting = false,
    this.requestSent = false,
  });

  static const _primary = Color(0xFF008F7A);
  static const _warning = Color(0xFFE7A400);
  static const _surface = Color(0xFFF5F8F7);

  final MatchRecommendation item;
  final Future<void> Function() onConnect;
  final bool isConnecting;
  final bool requestSent;

  List<({String label, double score})> get _criteria => [
    (label: 'Ngân sách', score: item.criteriaDetail.budgetMatch),
    (label: 'Giờ sinh hoạt', score: item.criteriaDetail.sleepMatch),
    (label: 'Sạch sẽ', score: item.criteriaDetail.cleanlinessMatch),
    (label: 'Hút thuốc', score: item.criteriaDetail.smokingMatch),
    (label: 'Thú cưng', score: item.criteriaDetail.petMatch),
  ];

  List<String> get _attentionPoints => _criteria
      .where((criterion) => criterion.score < 90)
      .map(
        (criterion) => 'Nên trao đổi thêm về ${criterion.label.toLowerCase()}',
      )
      .toList();

  Color _scoreColor(double score) => score >= 90 ? _primary : _warning;

  @override
  Widget build(BuildContext context) {
    final attentionPoints = _attentionPoints;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vì sao ${item.totalScore.toStringAsFixed(0)}%?',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF17342F),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Giải thích minh bạch cho từng tiêu chí với ${item.fullName}.',
                          style: const TextStyle(color: Color(0xFF62736F)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              for (final criterion in _criteria)
                _CriterionProgress(
                  label: criterion.label,
                  score: criterion.score,
                  color: _scoreColor(criterion.score),
                ),
              const SizedBox(height: 4),
              _InsightPanel(
                title: 'Điểm cần trao đổi',
                icon: Icons.chat_bubble_outline,
                color: const Color(0xFF9A5B00),
                backgroundColor: const Color(0xFFFFF0E8),
                items: attentionPoints.isEmpty
                    ? const ['Hai bạn chưa có khác biệt lớn cần lưu ý.']
                    : attentionPoints,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: requestSent || isConnecting ? null : onConnect,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isConnecting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          requestSent ? Icons.check : Icons.person_add_alt_1,
                        ),
                  label: Text(
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
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
              backgroundColor: const Color(0xFFDDE7E4),
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
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
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
