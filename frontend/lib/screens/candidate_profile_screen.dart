import 'package:flutter/material.dart';

import '../models/match_recommendation.dart';
import '../theme/discovery_palette.dart';
import '../widgets/compatibility_bottom_sheet.dart';
import '../widgets/match_card.dart';

class CandidateProfileScreen extends StatefulWidget {
  const CandidateProfileScreen({
    super.key,
    required this.item,
    required this.onConnect,
    required this.requestSent,
  });

  final MatchRecommendation item;
  final Future<bool> Function() onConnect;
  final bool requestSent;

  @override
  State<CandidateProfileScreen> createState() => _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends State<CandidateProfileScreen> {
  late bool _requestSent = widget.requestSent;
  bool _connecting = false;

  String get _nameAndAge => widget.item.age == null
      ? widget.item.fullName
      : '${widget.item.fullName}, ${widget.item.age}';

  String get _budget {
    final millions = widget.item.budgetAmount / 1000000;
    final value = millions == millions.roundToDouble()
        ? millions.toStringAsFixed(0)
        : millions.toStringAsFixed(1).replaceAll('.', ',');
    return '$value triệu / tháng';
  }

  Future<void> _connect() async {
    if (_requestSent || _connecting) return;
    setState(() => _connecting = true);
    try {
      final sent = await widget.onConnect();
      if (mounted && sent) setState(() => _requestSent = true);
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _showCompatibility() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => CompatibilityBottomSheet(
        item: widget.item,
        requestSent: _requestSent,
        onConnect: () async {
          Navigator.pop(sheetContext);
          await _connect();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final school = item.university?.trim();
    return Scaffold(
      backgroundColor: DiscoveryPalette.canvas,
      appBar: AppBar(
        backgroundColor: DiscoveryPalette.canvas,
        foregroundColor: DiscoveryPalette.text,
        title: const Text('Hồ sơ bạn ở ghép'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              const Text(
                'Thông tin công khai',
                style: TextStyle(color: DiscoveryPalette.muted),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 88,
                      child: CandidatePhoto(item: item, height: 96),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameAndAge,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (school?.isNotEmpty == true) ...[
                          const SizedBox(height: 5),
                          Text(
                            school!,
                            style: const TextStyle(
                              color: DiscoveryPalette.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const _SectionTitle('Một chút về mình'),
              const SizedBox(height: 10),
              Text(
                item.bioDescription?.trim().isNotEmpty == true
                    ? item.bioDescription!.trim()
                    : 'Chưa có lời giới thiệu công khai.',
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 30),
              const _SectionTitle('Mong muốn ở ghép'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _budget,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.targetDistrict,
                      style: const TextStyle(color: DiscoveryPalette.muted),
                    ),
                  ],
                ),
              ),
              if (item.matchedReasons.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final reason in item.matchedReasons.take(2))
                      Chip(
                        label: Text(reason),
                        backgroundColor: DiscoveryPalette.primarySoft,
                        side: BorderSide.none,
                        labelStyle: const TextStyle(
                          color: DiscoveryPalette.primary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _showCompatibility,
                  style: TextButton.styleFrom(
                    backgroundColor: DiscoveryPalette.primarySoft,
                    foregroundColor: DiscoveryPalette.primary,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                  child: Text(
                    '${item.totalScore.toStringAsFixed(0)}% phù hợp · Xem lý do',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Liên hệ chỉ mở khi cả hai chấp nhận kết nối.',
                style: TextStyle(color: DiscoveryPalette.muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _requestSent || _connecting ? null : _connect,
                  style: FilledButton.styleFrom(
                    backgroundColor: DiscoveryPalette.primary,
                  ),
                  child: _connecting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _requestSent
                              ? 'Đã gửi lời mời kết nối'
                              : 'Gửi lời mời kết nối',
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: DiscoveryPalette.text,
      fontSize: 17,
      fontWeight: FontWeight.w800,
    ),
  );
}
