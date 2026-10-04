import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/screens/room_filters_screen.dart';

Future<void> _openFilter(
  WidgetTester tester,
  RoomFiltersScreen screen,
  void Function(RoomFilterSelection?) onResult,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              onResult(
                await Navigator.push<RoomFilterSelection>(
                  context,
                  MaterialPageRoute(builder: (_) => screen),
                ),
              );
            },
            child: const Text('Open filter'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open filter'));
  await tester.pumpAndSettle();
}

Future<void> _apply(WidgetTester tester) async {
  await tester.tap(find.text('Xem phòng phù hợp'));
  await tester.pumpAndSettle();
}

void _expectNoFilters(RoomFilterSelection? selection) {
  expect(selection, isNotNull);
  expect(selection!.minPrice, 0);
  expect(selection.maxPrice, double.infinity);
  expect(selection.district, 'Tất cả khu vực');
  expect(selection.minArea, 0);
  expect(selection.amenities, isEmpty);
}

void main() {
  testWidgets('Default filter is unrestricted, not a demo preference', (
    tester,
  ) async {
    RoomFilterSelection? result;
    await _openFilter(
      tester,
      const RoomFiltersScreen(),
      (value) => result = value,
    );
    expect(find.text('Tất cả khu vực'), findsOneWidget);
    expect(find.text('Không giới hạn giá'), findsOneWidget);
    expect(find.text('Tất cả diện tích'), findsOneWidget);
    await tester.tap(find.text('Không giới hạn giá'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    await _apply(tester);
    _expectNoFilters(result);
  });

  testWidgets('Clear removes every advanced filter without mutating input', (
    tester,
  ) async {
    final amenities = <String>{'Nội thất', 'Máy lạnh'};
    RoomFilterSelection? result;
    await _openFilter(
      tester,
      RoomFiltersScreen(
        initialMinPrice: 2000000,
        initialMaxPrice: 4000000,
        initialDistrict: 'Bình Thạnh, TP.HCM',
        initialMinArea: 20,
        initialAmenities: amenities,
      ),
      (value) => result = value,
    );
    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pump();
    expect(
      tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .every((chip) => !chip.selected),
      isTrue,
    );
    await _apply(tester);
    _expectNoFilters(result);
    expect(amenities, {'Nội thất', 'Máy lạnh'});
  });

  testWidgets('Reopen and confirm keeps zero minimum and finite high maximum', (
    tester,
  ) async {
    RoomFilterSelection? result;
    await _openFilter(
      tester,
      const RoomFiltersScreen(
        initialMinPrice: 0,
        initialMaxPrice: 20000000,
        initialDistrict: 'Thủ Đức, TP.HCM',
        initialMinArea: 25,
        initialAmenities: {'Giữ xe'},
      ),
      (value) => result = value,
    );
    await tester.tap(find.text('0đ — 20.000.000đ'));
    await tester.pumpAndSettle();
    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    expect(slider.min, 0);
    expect(slider.max, greaterThanOrEqualTo(20000000));
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    await _apply(tester);
    expect(result!.minPrice, 0);
    expect(result!.maxPrice, 20000000);
    expect(result!.district, 'Thủ Đức, TP.HCM');
    expect(result!.minArea, 25);
    expect(result!.amenities, {'Giữ xe'});
  });

  testWidgets('Sub-million custom budget survives opening and applying', (
    tester,
  ) async {
    RoomFilterSelection? result;
    await _openFilter(
      tester,
      const RoomFiltersScreen(initialMinPrice: 500000, initialMaxPrice: 800000),
      (value) => result = value,
    );
    expect(find.text('500.000đ — 800.000đ'), findsOneWidget);
    await tester.tap(find.text('500.000đ — 800.000đ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    await _apply(tester);
    expect(result!.minPrice, 500000);
    expect(result!.maxPrice, 800000);
  });

  testWidgets(
    'Clear then cancel does not apply draft or change caller values',
    (tester) async {
      RoomFilterSelection? result;
      var returned = false;
      final amenities = {'Máy lạnh'};
      await _openFilter(
        tester,
        RoomFiltersScreen(
          initialMinPrice: 2000000,
          initialMaxPrice: 4000000,
          initialDistrict: 'Bình Thạnh, TP.HCM',
          initialMinArea: 20,
          initialAmenities: amenities,
        ),
        (value) {
          result = value;
          returned = true;
        },
      );
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(returned, isTrue);
      expect(result, isNull);
      expect(amenities, {'Máy lạnh'});
    },
  );

  testWidgets('Budget upper handle can explicitly choose no upper bound', (
    tester,
  ) async {
    RoomFilterSelection? result;
    await _openFilter(
      tester,
      const RoomFiltersScreen(
        initialMinPrice: 500000,
        initialMaxPrice: 4000000,
      ),
      (value) => result = value,
    );
    await tester.tap(find.text('500.000đ — 4.000.000đ'));
    await tester.pumpAndSettle();
    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    slider.onChanged!(RangeValues(0, slider.max));
    await tester.pump();
    expect(find.text('Không giới hạn giá'), findsOneWidget);
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    await _apply(tester);
    _expectNoFilters(result);
  });

  testWidgets('Area picker can remove only the area restriction', (
    tester,
  ) async {
    RoomFilterSelection? result;
    await _openFilter(
      tester,
      const RoomFiltersScreen(
        initialMinPrice: 2000000,
        initialMaxPrice: 4000000,
        initialMinArea: 20,
      ),
      (value) => result = value,
    );
    await tester.tap(find.text('Từ 20 m²'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tất cả diện tích'));
    await tester.pumpAndSettle();
    await _apply(tester);
    expect(result!.minArea, 0);
    expect(result!.minPrice, 2000000);
    expect(result!.maxPrice, 4000000);
  });
}
