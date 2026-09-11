import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth_user.dart';
import '../models/match_recommendation.dart';
import '../models/match_request_item.dart';
import '../models/room_post.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';

  // 1. Lấy danh sách gợi ý bạn trọ kèm điểm tương thích (QĐ 1)
  Future<List<MatchRecommendation>> getRecommendations(int currentUserId) async {
    final res = await http.get(Uri.parse('$baseUrl/matches/recommendations/$currentUserId'));
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((json) => MatchRecommendation.fromJson(json)).toList();
    }
    throw Exception('Không tải được danh sách gợi ý (${res.statusCode})');
  }

  // 2. Gửi lời mời kết nối ghép đôi
  Future<bool> sendMatchRequest(int senderId, int receiverId, double score) async {
    final url = Uri.parse('$baseUrl/matches/requests?senderId=$senderId&receiverId=$receiverId&score=$score');
    final res = await http.post(url);
    if (res.statusCode == 200) {
      return true;
    } else {
      debugPrint('Lỗi gửi kết nối: ${res.statusCode} - ${res.body}');
      return false;
    }
  }

  // 3. Lấy danh sách bài đăng phòng trọ
  Future<List<RoomPost>> getRoomPosts() async {
    final res = await http.get(Uri.parse('$baseUrl/posts'));
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((json) => RoomPost.fromJson(json)).toList();
    }
    throw Exception('Không tải được danh sách phòng (${res.statusCode})');
  }

  // 4. Đăng nhập
  Future<AuthUser> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return AuthUser.fromJson(data);
    } else {
      final msg = res.body.isNotEmpty ? res.body : 'Đăng nhập thất bại';
      throw Exception(msg);
    }
  }

  // 5. Đăng ký
  Future<AuthUser> register(String email, String password, String fullName, String gender, String phone) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'fullName': fullName,
        'gender': gender,
        'phone': phone,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return AuthUser.fromJson(data);
    } else {
      final msg = res.body.isNotEmpty ? res.body : 'Đăng ký thất bại';
      throw Exception(msg);
    }
  }

  // 6. Lấy tiêu chí hiện tại của User
  Future<Map<String, dynamic>?> getPreferences(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/profile/preferences/$userId'));
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    return null;
  }

  // 7. Cập nhật khảo sát thói quen
  Future<bool> savePreferences(int userId, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/profile/preferences/$userId'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(data),
    );
    return res.statusCode == 200;
  }

  // 8. Lấy danh sách yêu cầu nhận được
  Future<List<MatchRequestItem>> getReceivedRequests(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/matches/requests/received/$userId'));
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((json) => MatchRequestItem.fromJson(json)).toList();
    }
    debugPrint('Lỗi getReceivedRequests: ${res.statusCode} - ${res.body}');
    return [];
  }

  // 9. Lấy danh sách yêu cầu đã gửi
  Future<List<MatchRequestItem>> getSentRequests(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/matches/requests/sent/$userId'));
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((json) => MatchRequestItem.fromJson(json)).toList();
    }
    debugPrint('Lỗi getSentRequests: ${res.statusCode} - ${res.body}');
    return [];
  }

  // 10. Phản hồi lời mời kết nối (Chấp nhận / Từ chối)
  Future<bool> respondMatchRequest(int requestId, bool accept) async {
    final res = await http.put(
      Uri.parse('$baseUrl/matches/requests/$requestId/respond?accept=$accept'),
    );
    return res.statusCode == 200;
  }
  // Cập nhật thông tin tài khoản
  Future<bool> updateProfile(int userId, String fullName, String phone, String gender) async {
    final res = await http.put(
      Uri.parse('$baseUrl/profile/user/$userId?fullName=$fullName&phone=$phone&gender=$gender'),
    );
    return res.statusCode == 200;
  }
  // Tạo bài đăng tìm người ở ghép mới
  Future<bool> createRoomPost(Map<String, dynamic> postData) async {
    final res = await http.post(
      Uri.parse('$baseUrl/posts'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(postData),
    );
    return res.statusCode == 200;
  }
  // 11. Admin: Lấy tất cả bài đăng để duyệt
  Future<List<dynamic>> getAdminPosts() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/posts'));
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    return [];
  }

  // 12. Admin: Duyệt bài đăng (APPROVED / REJECTED)
  Future<bool> moderatePost(int postId, String status) async {
    final res = await http.put(
      Uri.parse('$baseUrl/admin/posts/$postId/moderate?status=$status'),
    );
    return res.statusCode == 200;
  }

  // 13. Admin: Lấy tất cả người dùng
  Future<List<dynamic>> getAdminUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/users'));
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    return [];
  }

  // 14. Admin: Khóa / Mở khóa người dùng
  Future<bool> toggleUserStatus(int userId) async {
    final res = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId/toggle-status'),
    );
    return res.statusCode == 200;
  }
}