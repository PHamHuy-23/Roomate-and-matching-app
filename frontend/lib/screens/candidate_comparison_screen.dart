import 'package:flutter/material.dart';
import '../models/match_recommendation.dart';

class CandidateComparisonScreen extends StatelessWidget {
  final List<MatchRecommendation> candidates;

  const CandidateComparisonScreen({
    super.key,
    required this.candidates,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF142523)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'So sánh ứng viên',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF142523),
          ),
        ),
        centerTitle: true,
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
                    'Đang so sánh (${candidates.length} ứng viên)',
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
              '${c.totalScore.toStringAsFixed(0)}% Match',
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
          _buildRow(
            'Ngân sách tối đa',
            candidates.map((c) {
              if (c.budgetAmount <= 0) return 'Chưa rõ';
              if (c.budgetAmount >= 1000000) {
                return '${(c.budgetAmount / 1000000).toStringAsFixed(1)} tr';
              }
              return '${c.budgetAmount.toStringAsFixed(0)} đ';
            }).toList(),
          ),
          const Divider(height: 1),
          _buildRow('Khu vực quận', candidates.map((c) => c.districtDisplay).toList()),
          const Divider(height: 1),
          _buildRow('Độ sạch sẽ', candidates.map((c) => '${c.criteriaDetail.cleanlinessMatch.toStringAsFixed(0)}%').toList()),
          const Divider(height: 1),
          _buildRow('Giờ giấc / Ngủ', candidates.map((c) => '${c.criteriaDetail.sleepMatch.toStringAsFixed(0)}%').toList()),
          const Divider(height: 1),
          _buildRow('Hút thuốc', candidates.map((c) => '${c.criteriaDetail.smokingMatch.toStringAsFixed(0)}%').toList()),
          const Divider(height: 1),
          _buildRow('Thú cưng', candidates.map((c) => '${c.criteriaDetail.petMatch.toStringAsFixed(0)}%').toList()),
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
              flex: 3,
              child: Center(
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
          ),
        ],
      ),
    );
  }
}
