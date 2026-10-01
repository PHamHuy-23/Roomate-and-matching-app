import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/blocked_user.dart';

void main() {
  test('Reads the safe block response without requiring contact information', () {
    final user = BlockedUser.fromJson({
      'id': 1,
      'blockedUserId': 7,
      'blockedUserName': 'Người đã chặn',
      'blockedUserAvatar': 'https://example.invalid/avatar.png',
      'createdAt': '2026-10-01T12:00:00',
    });

    expect(user.id, 1);
    expect(user.blockedUserId, 7);
    expect(user.blockedUserName, 'Người đã chặn');
    expect(user.blockedUserAvatar, 'https://example.invalid/avatar.png');
    expect(user.createdAt, DateTime(2026, 10, 1, 12));
  });

  test('Optional avatar and creation time may be absent', () {
    final user = BlockedUser.fromJson({
      'id': 1,
      'blockedUserId': 7,
      'blockedUserName': 'Người đã chặn',
    });

    expect(user.blockedUserId, 7);
    expect(user.blockedUserAvatar, isNull);
    expect(user.createdAt, isNull);
  });
}
