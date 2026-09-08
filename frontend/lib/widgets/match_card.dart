import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match_recommendation.dart';

class MatchCard extends StatelessWidget {
  final MatchRecommendation item;
  final VoidCallback onConnect;

  const MatchCard({super.key, required this.item, required this.onConnect});

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green.shade700;
    if (score >= 60) return Colors.orange.shade800;
    return Colors.red.shade700;
  }

  Widget _buildCriterionBar(String label, double score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(width: 95, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${score.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.indigo.shade50,
                  child: Text(
                    item.fullName.isNotEmpty ? item.fullName[0] : '?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Khu vực: ${item.targetDistrict}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(item.totalScore).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _getScoreColor(item.totalScore)),
                  ),
                  child: Text(
                    '${item.totalScore}% Phù hợp',
                    style: TextStyle(color: _getScoreColor(item.totalScore), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text('Ngân sách: ${fmt.format(item.budgetAmount)}/tháng', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              item.bioDescription ?? 'Chưa cập nhật phần giới thiệu bản thân.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            const Text('Chi tiết độ hòa hợp:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 4),
            _buildCriterionBar('Ngân sách (30%)', item.criteriaDetail.budgetMatch),
            _buildCriterionBar('Giờ giấc (25%)', item.criteriaDetail.sleepMatch),
            _buildCriterionBar('Vệ sinh (20%)', item.criteriaDetail.cleanlinessMatch),
            _buildCriterionBar('Hút thuốc (15%)', item.criteriaDetail.smokingMatch),
            _buildCriterionBar('Thú cưng (10%)', item.criteriaDetail.petMatch),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Gửi Yêu Cầu Kết Nối'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}