import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match_recommendation.dart';

class MatchCard extends StatelessWidget {
  final MatchRecommendation item;
  final VoidCallback onConnect;
  final bool isConnecting;
  final bool isRequestSent;

  const MatchCard({
    super.key,
    required this.item,
    required this.onConnect,
    this.isConnecting = false,
    this.isRequestSent = false,
  });

  static Color scoreColor(double score) {
    if (score >= 85) return const Color(0xFF1565C0);
    if (score >= 60) return const Color(0xFF9A5B00);
    return const Color(0xFF616161);
  }

  double _percentage(double score) =>
      score.isFinite ? score.clamp(0.0, 100.0).toDouble() : 0;

  Widget _avatar() {
    final name = item.fullName.trim();
    final fallback = ColoredBox(
      color: Colors.indigo.shade50,
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade700,
          ),
        ),
      ),
    );
    final url = item.avatarUrl?.trim();
    return ClipOval(
      child: SizedBox(
        width: 60,
        height: 60,
        child: url == null || url.isEmpty
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : fallback,
              ),
      ),
    );
  }

  Widget _info(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Colors.indigo.shade600),
      const SizedBox(width: 5),
      Flexible(child: Text(text, style: const TextStyle(fontSize: 13))),
    ],
  );

  Widget _criterion(String label, double rawScore) {
    final score = _percentage(rawScore);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 13)),
              ),
              Text('${score.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: scoreColor(score),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = _percentage(item.totalScore);
    final color = scoreColor(score);
    final label = score >= 85
        ? 'Rất phù hợp'
        : score >= 60
        ? 'Có tiềm năng'
        : 'Cần cân nhắc';
    final fmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    final bio = item.bioDescription?.trim();
    final university = item.university?.trim();
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _avatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fullName.trim().isEmpty
                            ? 'Ứng viên'
                            : item.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.age != null && item.age! > 0)
                        Text(
                          '${item.age} tuổi',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      if (university != null && university.isNotEmpty)
                        Text(
                          university,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              label:
                  'Tương thích ${score.toStringAsFixed(0)} phần trăm, $label',
              excludeSemantics: true,
              child: Container(
                key: const ValueKey('match-score-badge'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded, size: 22, color: color),
                    const SizedBox(width: 10),
                    Text(
                      '${score.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$label\nTương thích với bạn',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _info(Icons.location_on_outlined, item.targetDistrict),
                _info(
                  Icons.payments_outlined,
                  '${fmt.format(item.budgetAmount)}/tháng',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              bio == null || bio.isEmpty
                  ? 'Chưa cập nhật giới thiệu bản thân.'
                  : bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: const Text(
                'Xem 5 tiêu chí tương thích',
                style: TextStyle(fontSize: 13),
              ),
              children: [
                _criterion('Ngân sách', item.criteriaDetail.budgetMatch),
                _criterion('Giờ giấc', item.criteriaDetail.sleepMatch),
                _criterion('Vệ sinh', item.criteriaDetail.cleanlinessMatch),
                _criterion('Hút thuốc', item.criteriaDetail.smokingMatch),
                _criterion('Thú cưng', item.criteriaDetail.petMatch),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isConnecting || isRequestSent ? null : onConnect,
                icon: isConnecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isRequestSent
                            ? Icons.check_circle_outline
                            : Icons.person_add_alt_1,
                        size: 18,
                      ),
                label: Text(
                  isConnecting
                      ? 'Đang gửi...'
                      : isRequestSent
                      ? 'Đã gửi yêu cầu'
                      : 'Gửi yêu cầu kết nối',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
