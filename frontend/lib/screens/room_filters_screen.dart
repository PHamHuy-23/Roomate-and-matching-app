import 'package:flutter/material.dart';

/// Values selected on the Penpot filter screen.
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
    this.initialMinPrice = 2000000,
    this.initialMaxPrice = 4000000,
    this.initialDistrict = 'Bình Thạnh, TP.HCM',
    this.initialMinArea = 20,
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

  static const _districts = <String>[
    'Bình Thạnh, TP.HCM',
    'Thủ Đức, TP.HCM',
    'Quận 3, TP.HCM',
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
    _minPrice = widget.initialMinPrice.clamp(1000000, 15000000).toDouble();
    _maxPrice = widget.initialMaxPrice.clamp(_minPrice, 15000000).toDouble();
    _minArea = widget.initialMinArea.clamp(0, 100).toDouble();
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
            value: '${_money(_minPrice)} — ${_money(_maxPrice)}',
            onTap: _pickBudget,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Diện tích'),
          const SizedBox(height: 10),
          _FilterField(
            icon: Icons.square_foot_outlined,
            value: 'Từ ${_minArea.round()} m²',
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

  void _reset() {
    setState(() {
      _minPrice = 2000000;
      _maxPrice = 4000000;
      _district = 'Bình Thạnh, TP.HCM';
      _minArea = 20;
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
                  '${_money(min)} — ${_money(max)}',
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                RangeSlider(
                  values: RangeValues(min, max),
                  min: 1000000,
                  max: 15000000,
                  divisions: 28,
                  activeColor: _primary,
                  onChanged: (values) => setSheetState(() {
                    min = values.start;
                    max = values.end;
                  }),
                ),
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
            for (final area in [15.0, 20.0, 25.0, 30.0, 40.0])
              ListTile(
                title: Text('Từ ${area.round()} m²'),
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
