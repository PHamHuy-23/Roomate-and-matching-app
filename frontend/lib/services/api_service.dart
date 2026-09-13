import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_user.dart';
import '../models/match_recommendation.dart';
import '../models/match_request_item.dart';
import '../models/room_post.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService._internal();

  factory ApiService() => _instance;

  static final ApiService _instance = ApiService._internal();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );
  static const Duration requestTimeout = Duration(seconds: 15);

  static void Function()? _onUnauthorized;

  final http.Client _client = http.Client();
  String? _token;
  bool _isHandlingUnauthorized = false;

  String? get authToken => _token;
  bool get hasAuthToken => _token != null && _token!.isNotEmpty;

  static void configureUnauthorizedHandler(void Function() handler) {
    _onUnauthorized = handler;
  }

  void setAuthToken(String token) {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw const ApiException('Token xác thực không được để trống');
    }
    _token = normalizedToken;
    _isHandlingUnauthorized = false;
  }

  void clearAuthToken() {
    _token = null;
  }

  Map<String, String> _headers({bool authenticated = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (authenticated && hasAuthToken) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Object? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters?.isEmpty == true ? null : queryParameters,
    );
    final request = http.Request(method, uri)
      ..headers.addAll(_headers(authenticated: authenticated));
    if (body != null) {
      request.body = body is String ? body : jsonEncode(body);
    }

    try {
      final streamedResponse = await _client.send(request).timeout(requestTimeout);
      final response = await http.Response.fromStream(streamedResponse).timeout(requestTimeout);
      if (authenticated && response.statusCode == 401) {
        _handleUnauthorized();
        throw const ApiException('Phiên làm việc đã hết hạn', statusCode: 401);
      }
      return response;
    } on TimeoutException {
      throw const ApiException('Máy chủ phản hồi quá lâu, vui lòng thử lại');
    } on http.ClientException {
      throw const ApiException('Không thể kết nối đến máy chủ');
    }
  }

  void _handleUnauthorized() {
    clearAuthToken();
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;
    _onUnauthorized?.call();
  }

  dynamic _decodeData(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic> &&
        decoded.containsKey('status') &&
        decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  List<dynamic> _decodeList(http.Response response) {
    final data = _decodeData(response);
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic> && data['items'] is List<dynamic>) {
      return data['items'] as List<dynamic>;
    }
    throw ApiException(
      'Dữ liệu danh sách từ máy chủ không hợp lệ',
      statusCode: response.statusCode,
    );
  }

  ApiException _errorFrom(http.Response response, String fallbackMessage) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        return ApiException(
          decoded['message'] as String,
          statusCode: response.statusCode,
        );
      }
      if (decoded is String && decoded.isNotEmpty) {
        return ApiException(decoded, statusCode: response.statusCode);
      }
    } on FormatException {
      // Server cũ có thể trả plain text thay vì JSON.
    }
    return ApiException(fallbackMessage, statusCode: response.statusCode);
  }

  Future<List<MatchRecommendation>> getRecommendations(int currentUserId) async {
    final response = await _request('GET', '/matches/recommendations/$currentUserId');
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map((json) => MatchRecommendation.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw _errorFrom(response, 'Không tải được danh sách gợi ý');
  }

  Future<bool> sendMatchRequest(int senderId, int receiverId, double score) async {
    final response = await _request(
      'POST',
      '/matches/requests',
      queryParameters: {
        'senderId': '$senderId',
        'receiverId': '$receiverId',
        'score': '$score',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) return true;
    throw _errorFrom(response, 'Không thể gửi yêu cầu kết nối');
  }

  Future<List<RoomPost>> getRoomPosts() async {
    final response = await _request('GET', '/posts');
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map((json) => RoomPost.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw _errorFrom(response, 'Không tải được danh sách phòng');
  }

  Future<AuthUser> login(String email, String password) async {
    final response = await _request(
      'POST',
      '/auth/login',
      authenticated: false,
      body: {'email': email, 'password': password},
    );
    if (response.statusCode == 200) {
      final data = _decodeData(response);
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Dữ liệu đăng nhập từ máy chủ không hợp lệ');
      }
      final user = AuthUser.fromJson(data);
      setAuthToken(user.token);
      return user;
    }
    throw _errorFrom(response, 'Đăng nhập thất bại');
  }

  Future<AuthUser> register(
    String email,
    String password,
    String fullName,
    String gender,
    String phone,
  ) async {
    final response = await _request(
      'POST',
      '/auth/register',
      authenticated: false,
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'gender': gender,
        'phone': phone,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _decodeData(response);
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Dữ liệu đăng ký từ máy chủ không hợp lệ');
      }
      final user = AuthUser.fromJson(data);
      setAuthToken(user.token);
      return user;
    }
    throw _errorFrom(response, 'Đăng ký thất bại');
  }

  Future<Map<String, dynamic>?> getPreferences(int userId) async {
    final response = await _request('GET', '/profile/preferences/$userId');
    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      final data = _decodeData(response);
      return data is Map<String, dynamic> ? data : null;
    }
    if (response.statusCode == 404) return null;
    throw _errorFrom(response, 'Không tải được tiêu chí người dùng');
  }

  Future<bool> savePreferences(int userId, Map<String, dynamic> data) async {
    final response = await _request(
      'PUT',
      '/profile/preferences/$userId',
      body: data,
    );
    if (response.statusCode == 200) return true;
    throw _errorFrom(response, 'Không thể lưu tiêu chí người dùng');
  }

  Future<List<MatchRequestItem>> getReceivedRequests(int userId) async {
    final response = await _request('GET', '/matches/requests/received/$userId');
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map((json) => MatchRequestItem.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw _errorFrom(response, 'Không tải được yêu cầu đã nhận');
  }

  Future<List<MatchRequestItem>> getSentRequests(int userId) async {
    final response = await _request('GET', '/matches/requests/sent/$userId');
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map((json) => MatchRequestItem.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw _errorFrom(response, 'Không tải được yêu cầu đã gửi');
  }

  Future<bool> respondMatchRequest(int requestId, bool accept) async {
    final response = await _request(
      'PUT',
      '/matches/requests/$requestId/respond',
      queryParameters: {'accept': '$accept'},
    );
    if (response.statusCode == 200) return true;
    throw _errorFrom(response, 'Không thể phản hồi yêu cầu kết nối');
  }

  Future<bool> updateProfile(
    int userId,
    String fullName,
    String phone,
    String gender,
  ) async {
    final response = await _request(
      'PUT',
      '/profile/user/$userId',
      queryParameters: {
        'fullName': fullName,
        'phone': phone,
        'gender': gender,
      },
    );
    if (response.statusCode == 200) return true;
    throw _errorFrom(response, 'Không thể cập nhật hồ sơ');
  }

  Future<bool> createRoomPost(Map<String, dynamic> postData) async {
    final response = await _request('POST', '/posts', body: postData);
    if (response.statusCode == 200 || response.statusCode == 201) return true;
    throw _errorFrom(response, 'Không thể tạo bài đăng');
  }

  Future<List<dynamic>> getAdminPosts() async {
    final response = await _request('GET', '/admin/posts');
    if (response.statusCode == 200) return _decodeList(response);
    throw _errorFrom(response, 'Không tải được danh sách bài đăng quản trị');
  }

  Future<bool> moderatePost(int postId, String status) async {
    final response = await _request(
      'PUT',
      '/admin/posts/$postId/moderate',
      queryParameters: {'status': status},
    );
    if (response.statusCode == 200) return true;
    throw _errorFrom(response, 'Không thể duyệt bài đăng');
  }

  Future<List<dynamic>> getAdminUsers() async {
    final response = await _request('GET', '/admin/users');
    if (response.statusCode == 200) return _decodeList(response);
    throw _errorFrom(response, 'Không tải được danh sách người dùng');
  }

  Future<bool> toggleUserStatus(int userId) async {
    final response = await _request('PUT', '/admin/users/$userId/toggle-status');
    if (response.statusCode == 200) return true;
    throw _errorFrom(response, 'Không thể thay đổi trạng thái người dùng');
  }
}
