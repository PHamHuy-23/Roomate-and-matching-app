import 'package:flutter/material.dart';
import '../models/match_recommendation.dart';
import '../widgets/penpot_back_button.dart';

class CandidateComparisonScreen extends StatelessWidget {
  final List<MatchRecommendation> candidates;

  const CandidateComparisonScreen({
    super.key,
    required this.candidates,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const PenpotBackButton(),
        title: const Text(
          'So sánh đối đầu bạn trọ',
          style: TextStyle(
            color: Color(0xFF142523),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: candidates.isEmpty
          ? const Center(
              child: Text('Vui lòng chọn từ 2 đến 3 hồ sơ để so sánh.'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đang so sánh ( ứng viên)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF65746F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bảng so sánh thẻ ứng viên
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: candidates.map((c) => _buildCandidateColumn(c)).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Chi tiết bảng chỉ số đối đầu
                  _buildComparisonTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildCandidateColumn(MatchRecommendation c) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EBE8)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFEAF8F5),
            backgroundImage: c.avatarUrl != null && c.avatarUrl!.isNotEmpty
                ? NetworkImage(c.avatarUrl!)
                : null,
            child: c.avatarUrl == null || c.avatarUrl!.isEmpty
                ? const Icon(Icons.person, color: Color(0xFF087E6B), size: 28)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            c.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF142523),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF087E6B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '% Match',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF087E6B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EBE8)),
      ),
      child: Column(
        children: [
          _buildRow('Ngân sách tối đa', candidates.map((c) => c.budgetAmount > 0 ? ' tr' : 'Chưa rõ').toList()),
          const Divider(height: 1),
          _buildRow('Khu vực quận', candidates.map((c) => c.targetDistrict).toList()),
          const Divider(height: 1),
          _buildRow('Độ sạch sẽ', candidates.map((c) => '%').toList()),
          const Divider(height: 1),
          _buildRow('Giờ giấc / Ngủ', candidates.map((c) => '%').toList()),
          const Divider(height: 1),
          _buildRow('Hút thuốc', candidates.map((c) => '%').toList()),
          const Divider(height: 1),
          _buildRow('Thú cưng', candidates.map((c) => '%').toList()),
        ],
      ),
    );
  }

  Widget _buildRow(String title, List<String> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF65746F),
              ),
            ),
          ),
          ...values.map(
            (v) => Expanded(
              flex: 2,
              child: Text(
                v,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF142523),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}