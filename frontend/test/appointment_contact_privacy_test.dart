import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/viewing_appointment.dart';

Map<String, dynamic> appointmentJson() => {
  'id': 1,
  'requesterId': 10,
  'requesterName': 'Người đặt',
  'hostId': 20,
  'hostName': 'Chủ phòng',
  'roomPostId': 30,
  'roomTitle': 'Phòng test',
  'roomAddress': 'Địa chỉ test',
  'roomPrice': 2500000,
  'appointmentTime': '2026-10-10T10:00:00Z',
  'status': 'CONFIRMED',
  'createdAt': '2026-10-04T10:00:00Z',
};

void main() {
  for (final explicitlyNull in [false, true]) {
    test('Điện thoại bị ẩn vẫn để trống (null=$explicitlyNull)', () {
      final json = appointmentJson();
      if (explicitlyNull) {
        json['requesterPhone'] = null;
        json['hostPhone'] = null;
      }

      final appointment = ViewingAppointment.fromJson(json);

      expect(appointment.requesterPhone, isNull);
      expect(appointment.hostPhone, isNull);
      expect(appointment.status, 'CONFIRMED');
      expect(appointment.requesterId, 10);
      expect(appointment.hostId, 20);
      expect(appointment.roomPostId, 30);
    });
  }

  test('Giữ nguyên số điện thoại khi backend đã cho phép xem', () {
    final json = appointmentJson()
      ..['requesterPhone'] = '0000000001'
      ..['hostPhone'] = '0000000002';

    final appointment = ViewingAppointment.fromJson(json);

    expect(appointment.requesterPhone, '0000000001');
    expect(appointment.hostPhone, '0000000002');
  });
}
