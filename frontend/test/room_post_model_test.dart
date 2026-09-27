import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';

void main() {
  test('RoomPost parses the complete backend payload', () {
    final post = RoomPost.fromJson({
      'id': 7,
      'title': 'Phòng gần trường',
      'description': 'Phòng đầy đủ tiện nghi',
      'price': 3500000,
      'address': '123 Võ Văn Ngân',
      'district': 'Thủ Đức',
      'deposit': 1000000,
      'electricityWaterCost': 300000,
      'area': 25,
      'maxOccupants': 3,
      'currentOccupants': 1,
      'amenities': 'Wifi,Máy lạnh,Chỗ để xe',
      'authorName': 'Demo User',
      'authorId': 2,
      'createdAt': '2026-09-27T10:00:00',
    });

    expect(post.district, 'Thủ Đức');
    expect(post.deposit, 1000000);
    expect(post.electricityWaterCost, 300000);
    expect(post.areaM2, 25);
    expect(post.currentOccupants, 1);
    expect(post.amenities, ['Wifi', 'Máy lạnh', 'Chỗ để xe']);
  });

  test('RoomPost accepts amenities returned as a JSON list', () {
    final post = RoomPost.fromJson({
      'id': 8,
      'title': 'Phòng demo',
      'description': 'Mô tả',
      'price': 2000000,
      'address': 'TP.HCM',
      'maxOccupants': 2,
      'authorName': 'Demo User',
      'authorId': 2,
      'amenities': ['Wifi', 'Máy giặt'],
    });

    expect(post.amenities, ['Wifi', 'Máy giặt']);
    expect(post.currentOccupants, 0);
  });
}
