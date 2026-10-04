import 'package:flutter/material.dart';
import '../models/district_names.dart';

/// Draft values applied only when the user confirms the filter screen.
class RoomFilterSelection {
  const RoomFilterSelection({
    required this.minPrice,
    required this.maxPrice,
    required this.district,
    required this.minArea,
    required this.amenities,
  });

  final double minPrice;
  final double maxPrice;
  final String district;
  final double minArea;
  final Set<String> amenities;
}

class RoomFiltersScreen extends StatefulWidget {
  const RoomFiltersScreen({
    super.key,
    this.initialMinPrice = 0,
    this.initialMaxPrice = double.infinity,
    this.initialDistrict = 'Tất cả khu vực',
    this.initialMinArea = 0,
    this.initialAmenities = const <String>{},
  });

  final double initialMinPrice;
  final double initialMaxPrice;
  final String initialDistrict;
  final double initialMinArea;
  final Set<String> initialAmenities;

  @override
  State<RoomFiltersScreen> createState() => _RoomFiltersScreenState();
}

class _RoomFiltersScreenState extends State<RoomFiltersScreen> {
  static const _canvas = Color(0xFFF5F8F7);
  static const _primary = Color(0xFF087E6B);
  static const _ink = Color(0xFF142523);
  static const _muted = Color(0xFF65746F);
  static const _outline = Color(0xFFD3E0DC);

  late double _minPrice;
  late double _maxPrice;
  late double _minArea;
  late String _district;
  late Set<String> _amenities;

  static final _districts = <String>[
    'Bình Thạnh, TP.HCM',
    'Thủ Đức, TP.HCM',
    'Quận 3, TP.HCM',
    ...DistrictNames.labels.entries
        .where(
          (entry) => !{'Binh Thanh', 'Thu Duc', 'Quan 3'}.contains(entry.key),
        )
        .map((entry) => '${entry.value}, TP.HCM'),
    'Tất cả khu vực',
  ];
  static const _amenityOptions = <String>[
    'Nội thất',
    'Máy lạnh',
    'Bếp riêng',
    'Giữ xe',
  ];

  @override
  void initState() {
    super.initState();
    _minPrice = widget.initialMinPrice.clamp(0, double.infinity).toDouble();
    _maxPrice = widget.initialMaxPrice
        .clamp(_minPrice, double.infinity)
        .toDouble();
    _minArea = widget.initialMinArea.clamp(0, double.infinity).toDouble();
    _district = widget.initialDistrict;
    _amenities = Set<String>.of(widget.initialAmenities);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Bộ lọc phòng trọ'),
        backgroundColor: _canvas,
        foregroundColor: _ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Tìm căn phòng phù hợp với bạn',
            style: TextStyle(color: _muted, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 28),
          const _SectionLabel('Khu vực'),
          const SizedBox(height: 10),
          _FilterField(
            icon: Icons.location_on_outlined,
            value: _district,
            onTap: _pickDistrict,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Khoảng giá / tháng'),
          const SizedBox(height: 10),
          _FilterField(
            icon: Icons.payments_outlined,
            value: _budgetLabel(_minPrice, _maxPrice),
            onTap: _pickBudget,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Diện tích'),
          const SizedBox(height: 10),
          _FilterField(
            icon: Icons.square_foot_outlined,
            value: _areaLabel(_minArea),
            onTap: _pickArea,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Tiện ích'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _amenityOptions.map((amenity) {
              final selected = _amenities.contains(amenity);
              return FilterChip(
                label: Text(amenity),
                selected: selected,
                onSelected: (value) => setState(() {
                  if (value) {
                    _amenities.add(amenity);
                  } else {
                    _amenities.remove(amenity);
                  }
                }),
                selectedColor: _primary.withValues(alpha: 0.14),
                checkmarkColor: _primary,
                side: BorderSide(color: selected ? _primary : _outline),
                labelStyle: TextStyle(
                  color: selected ? _primary : _ink,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 36),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              RoomFilterSelection(
                minPrice: _minPrice,
                maxPrice: _maxPrice,
                district: _district,
                minArea: _minArea,
                amenities: Set<String>.of(_amenities),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Xem phòng phù hợp',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _reset,
            style: TextButton.styleFrom(foregroundColor: _muted),
            child: const Text('Xóa bộ lọc'),
          ),
        ],
      ),
    );
  }

  String _money(double value) {
    final digits = value.round().toString();
    final formatted = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        formatted.write('.');
      }
      formatted.write(digits[index]);
    }
    return '$formattedđ';
  }

  String _budgetLabel(double min, double max) {
    if (max.isInfinite) {
      return min == 0
          ? 'Không giới hạn giá'
          : 'Từ ${_money(min)} — Không giới hạn';
    }
    return '${_money(min)} — ${_money(max)}';
  }

  String _areaLabel(double area) =>
      area == 0 ? 'Tất cả diện tích' : 'Từ ${area.round()} m²';

  void _reset() {
    setState(() {
      _minPrice = 0;
      _maxPrice = double.infinity;
      _district = 'Tất cả khu vực';
      _minArea = 0;
      _amenities = <String>{};
    });
  }

  Future<void> _pickDistrict() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _canvas,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: _districts
              .map(
                (district) => ListTile(
                  title: Text(district),
                  trailing: district == _district
                      ? const Icon(Icons.check, color: _primary)
                      : null,
                  onTap: () => Navigator.pop(context, district),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _district = selected);
  }

  Future<void> _pickBudget() async {
    var min = _minPrice;
    var max = _maxPrice;
    // The rightmost handle means no upper bound; 15m is only a scale hint.
    // Expand the scale for existing higher custom bounds without truncating
    // their values when this sheet is opened and confirmed unchanged.
    final largestBound = max.isFinite ? max : min;
    final sliderMax = largestBound >= 15000000
        ? ((largestBound / 500000).floor() + 1) * 500000.0
        : 15000000.0;
    final selected = await showModalBottomSheet<RangeValues>(
      context: context,
      backgroundColor: _canvas,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khoảng giá / tháng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _budgetLabel(min, max),
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                RangeSlider(
                  values: RangeValues(min, max.isInfinite ? sliderMax : max),
                  min: 0,
                  max: sliderMax,
                  divisions: (sliderMax / 500000).round(),
                  labels: RangeLabels(
                    _money(min),
                    max.isInfinite ? 'Không giới hạn' : _money(max),
                  ),
                  activeColor: _primary,
                  onChanged: (values) => setSheetState(() {
                    min = values.start;
                    max = values.end == sliderMax
                        ? double.infinity
                        : values.end;
                  }),
                ),
                const Text(
                  'Kéo mốc giá tối đa sang phải để bỏ giới hạn.',
                  style: TextStyle(color: _muted),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, RangeValues(min, max)),
                    style: FilledButton.styleFrom(backgroundColor: _primary),
                    child: const Text('Xác nhận'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _minPrice = selected.start;
        _maxPrice = selected.end;
      });
    }
  }

  Future<void> _pickArea() async {
    final selected = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: _canvas,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            for (final area in [0.0, 15.0, 20.0, 25.0, 30.0, 40.0])
              ListTile(
                title: Text(_areaLabel(area)),
                trailing: area == _minArea
                    ? const Icon(Icons.check, color: _primary)
                    : null,
                onTap: () => Navigator.pop(context, area),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _minArea = selected);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF142523),
      fontSize: 16,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD3E0DC)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF087E6B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: Color(0xFF142523), fontSize: 15),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF65746F)),
          ],
        ),
      ),
    );
  }
}
