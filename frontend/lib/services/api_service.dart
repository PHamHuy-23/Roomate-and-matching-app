import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/auth_user.dart';
import '../models/match_recommendation.dart';
import '../models/match_request_item.dart';
import '../models/room_post.dart';
import '../models/upload_ticket.dart';
import '../models/chat_message.dart';
import '../models/viewing_appointment.dart';
import '../models/blocked_user.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService._internal() : _client = http.Client();

  @visibleForTesting
  ApiService.withClient(http.Client client) : _client = client;

  factory ApiService() => _instance;

  static final ApiService _instance = ApiService._internal();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://roomate-and-matching-app.onrender.com/api/v1',
  );
  static const Duration requestTimeout = Duration(seconds: 45);

  static void Function()? _onUnauthorized;

  final http.Client _client;
  String? _token;
  String? _refreshToken;
  bool _isHandlingUnauthorized = false;
  Future<bool>? _refreshFuture;

  final Set<int> savedPostIds = <int>{};
  bool isSearchActive = true;

  bool isPostSaved(int postId) => savedPostIds.contains(postId);

  Future<bool> toggleSavePost(int postId) async {
    final saved = !savedPostIds.contains(postId);
    await setPostSaved(postId, saved);
    return saved;
  }

  Future<void> setPostSaved(int postId, bool saved) async {
    final response = await _request(
      'PUT',
      '/profile/saved-posts/$postId',
      body: {'saved': saved},
    );
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Không lưu được phòng');
    }
    if (saved) {
      savedPostIds.add(postId);
    } else {
      savedPostIds.remove(postId);
    }
  }

  Future<void> loadSavedPosts() async {
    final response = await _request('GET', '/profile/saved-posts');
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Không tải được phòng đã lưu');
    }
    savedPostIds
      ..clear()
      ..addAll(_decodeList(response).map((id) => (id as num).toInt()));
  }

  String? get authToken => _token;
  bool get hasAuthToken => _token != null && _token!.isNotEmpty;
  String? get refreshToken => _refreshToken;
  bool get hasRefreshToken =>
      _refreshToken != null && _refreshToken!.isNotEmpty;

  static void configureUnauthorizedHandler(void Function() handler) {
    _onUnauthorized = handler;
  }

  @visibleForTesting
  static Map<String, Object> createRegistrationPayload({
    required String email,
    required String password,
    required String fullName,
    required String gender,
    required String phone,
    required DateTime birthDate,
    required String university,
  }) {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'gender': gender,
      'phone': phone,
      'birthDate': birthDate.toIso8601String().split('T').first,
      'university': university,
    };
  }

  void setAuthToken(String token) {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw const ApiException('Token xác thực không được để trống');
    }
    _token = normalizedToken;
    _isHandlingUnauthorized = false;
  }

  void setRefreshToken(String? refreshToken) {
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      _refreshToken = refreshToken.trim();
    } else {
      _refreshToken = null;
    }
  }

  void setTokens({required String accessToken, String? refreshToken}) {
    setAuthToken(accessToken);
    setRefreshToken(refreshToken);
  }

  void clearAuthToken() {
    savedPostIds.clear();
    isSearchActive = true;
    _token = null;
    _refreshToken = null;
    _refreshFuture = null;
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
      queryParameters: queryParameters?.isEmpty == true
          ? null
          : queryParameters,
    );
    final request = http.Request(method, uri)
      ..headers.addAll(_headers(authenticated: authenticated));
    if (body != null) {
      request.body = body is String ? body : jsonEncode(body);
    }

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(requestTimeout);
      final response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(requestTimeout);
      if (authenticated && response.statusCode == 401) {
        if (hasRefreshToken) {
          final refreshed = await (_refreshFuture ??= _tryRefreshToken());
          if (refreshed) {
            final retryRequest = http.Request(method, uri)
              ..headers.addAll(_headers(authenticated: authenticated));
            if (body != null) {
              retryRequest.body = body is String ? body : jsonEncode(body);
            }
            final retryStreamed = await _client
                .send(retryRequest)
                .timeout(requestTimeout);
            final retryResponse = await http.Response.fromStream(
              retryStreamed,
            ).timeout(requestTimeout);
            if (retryResponse.statusCode != 401) {
              return retryResponse;
            }
          }
        }
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

  Future<bool> refreshAuthToken() async {
    return (_refreshFuture ??= _tryRefreshToken());
  }

  Future<bool> _tryRefreshToken() async {
    final currentRefreshToken = _refreshToken;
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      return false;
    }
    try {
      final uri = Uri.parse('$baseUrl/auth/refresh-token');
      final response = await _client
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode({'refreshToken': currentRefreshToken}),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = _decodeData(response);
        if (data is Map<String, dynamic>) {
          final newAccessToken = data['token'] ?? data['accessToken'];
          final newRefreshToken = data['refreshToken'];
          if (newAccessToken is String && newAccessToken.isNotEmpty) {
            _token = newAccessToken;
            if (newRefreshToken is String && newRefreshToken.isNotEmpty) {
              _refreshToken = newRefreshToken;
            }
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<void> logout() async {
    final tokenToRevoke = _refreshToken;
    try {
      if (hasAuthToken || tokenToRevoke != null) {
        await _request(
          'POST',
          '/auth/logout',
          authenticated: hasAuthToken,
          body: tokenToRevoke != null ? {'refreshToken': tokenToRevoke} : null,
        );
      }
    } catch (_) {
      // Bỏ qua lỗi mạng khi logout để trạng thái local luôn được xóa sạch
    } finally {
      clearAuthToken();
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

  Future<List<MatchRecommendation>> getRecommendations(
    int currentUserId,
  ) async {
    final response = await _request(
      'GET',
      '/matches/recommendations/$currentUserId',
    );
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map(
            (json) =>
                MatchRecommendation.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }
    throw _errorFrom(response, 'Không tải được danh sách gợi ý');
  }

  Future<MatchRequestItem> sendMatchRequest(int receiverId) async {
    final response = await _request(
      'POST',
      '/matches/requests',
      queryParameters: {'receiverId': '$receiverId'},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = _decodeData(response);
        if (data is! Map<String, dynamic>) throw const FormatException();
        final request = MatchRequestItem.fromJson(data);
        if (request.partnerId != receiverId ||
            !['PENDING', 'ACCEPTED'].contains(request.status) ||
            !request.matchScore.isFinite) {
          throw const FormatException();
        }
        return request;
      } catch (_) {
        throw const ApiException('Dữ liệu lời mời từ máy chủ không hợp lệ');
      }
    }
    throw _errorFrom(response, 'Không thể gửi yêu cầu kết nối');
  }

  Future<List<RoomPost>> getRoomPosts() async {
    final response = await _request('GET', '/posts');
    if (response.statusCode == 200) {
      return _decodeList(
        response,
      ).map((json) => RoomPost.fromJson(json as Map<String, dynamic>)).toList();
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
      setTokens(accessToken: user.token, refreshToken: user.refreshToken);
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
    DateTime birthDate,
    String university,
  ) async {
    final response = await _request(
      'POST',
      '/auth/register',
      authenticated: false,
      body: createRegistrationPayload(
        email: email,
        password: password,
        fullName: fullName,
        gender: gender,
        phone: phone,
        birthDate: birthDate,
        university: university,
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _decodeData(response);
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Dữ liệu đăng ký từ máy chủ không hợp lệ');
      }
      final user = AuthUser.fromJson(data);
      setTokens(accessToken: user.token, refreshToken: user.refreshToken);
      return user;
    }
    throw _errorFrom(response, 'Đăng ký thất bại');
  }

  Future<Map<String, dynamic>?> getPreferences(int userId) async {
    final response = await _request('GET', '/profile/preferences/$userId');
    if (response.statusCode == 200) {
      if (response.bodyBytes.isEmpty ||
          response.body.trim().isEmpty ||
          response.body.trim() == 'null') {
        return null;
      }
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
    final response = await _request(
      'GET',
      '/matches/requests/received/$userId',
    );
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map(
            (json) => MatchRequestItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }
    throw _errorFrom(response, 'Không tải được yêu cầu đã nhận');
  }

  Future<List<MatchRequestItem>> getSentRequests(int userId) async {
    final response = await _request('GET', '/matches/requests/sent/$userId');
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map(
            (json) => MatchRequestItem.fromJson(json as Map<String, dynamic>),
          )
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
    DateTime birthDate,
    String university,
  ) async {
    final response = await _request(
      'PUT',
      '/profile/user/$userId',
      queryParameters: {
        'fullName': fullName,
        'phone': phone,
        'gender': gender,
        'birthDate': birthDate.toIso8601String().split('T').first,
        'university': university,
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

  Future<UploadTicket> createUploadTicket({
    required String fileName,
    required String contentType,
    required int fileSize,
    required String purpose,
  }) async {
    final response = await _request(
      'POST',
      '/uploads/presign',
      body: {
        'fileName': fileName,
        'contentType': contentType,
        'fileSize': fileSize,
        'purpose': purpose,
      },
    );
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Không thể chuẩn bị tải ảnh lên');
    }
    final data = _decodeData(response);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Thông tin upload từ máy chủ không hợp lệ');
    }
    return UploadTicket.fromJson(data);
  }

  Future<UploadTicket> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String purpose,
  }) async {
    final ticket = await createUploadTicket(
      fileName: fileName,
      contentType: contentType,
      fileSize: bytes.length,
      purpose: purpose,
    );
    final response = await _client
        .put(
          Uri.parse(ticket.uploadUrl),
          headers: {
            'Content-Type': ticket.contentType,
            'Content-Length': '${bytes.length}',
          },
          body: bytes,
        )
        .timeout(requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'R2 từ chối tải ảnh lên',
        statusCode: response.statusCode,
      );
    }
    return ticket;
  }

  Future<String> confirmAvatar(String objectKey) async {
    final response = await _request(
      'PUT',
      '/uploads/avatar',
      body: {'objectKey': objectKey},
    );
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Không thể cập nhật ảnh đại diện');
    }
    final data = _decodeData(response);
    if (data is Map<String, dynamic> && data['avatarUrl'] is String) {
      return data['avatarUrl'] as String;
    }
    throw const ApiException('Máy chủ không trả về URL ảnh đại diện');
  }

  Future<List<dynamic>> getAdminPosts() async {
    final response = await _request('GET', '/admin/posts');
    if (response.statusCode == 200) return _decodeList(response);
    throw _errorFrom(response, 'Không tải được danh sách bài đăng quản trị');
  }

  Future<bool> moderatePost(int postId, String status, {String? reason}) async {
    final query = <String, String>{'status': status};
    if (reason != null && reason.trim().isNotEmpty) {
      query['reason'] = reason.trim();
    }
    final response = await _request(
      'PUT',
      '/admin/posts/$postId/moderate',
      queryParameters: query,
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
    final response = await _request(
      'PUT',
      '/admin/users/$userId/toggle-status',
    );
    if (response.statusCode == 200) return true;
    throw _errorFrom(response, 'Không thể thay đổi trạng thái người dùng');
  }

  static String _formatIsoWithOffset(DateTime dateTime) {
    if (dateTime.isUtc) {
      return dateTime.toIso8601String();
    }
    final offset = dateTime.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '${dateTime.toIso8601String()}$sign$hours:$minutes';
  }

  // --- LỊCH HẸN XEM PHÒNG (APPOINTMENTS) ---
  Future<ViewingAppointment> createAppointment({
    required int roomPostId,
    required DateTime appointmentTime,
    String? note,
  }) async {
    final response = await _request(
      'POST',
      '/appointments',
      body: {
        'roomPostId': roomPostId,
        'appointmentTime': _formatIsoWithOffset(appointmentTime),
        'note': note,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _decodeData(response);
      if (data is Map<String, dynamic>) {
        return ViewingAppointment.fromJson(data);
      }
      throw const ApiException('Dữ liệu lịch hẹn từ máy chủ không hợp lệ');
    }
    throw _errorFrom(response, 'Không thể đặt lịch xem phòng');
  }

  Future<List<ViewingAppointment>> getMyAppointments() async {
    final response = await _request('GET', '/appointments/my');
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map(
            (json) => ViewingAppointment.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }
    throw _errorFrom(response, 'Không tải được danh sách lịch hẹn');
  }

  Future<ViewingAppointment> updateAppointmentStatus(
    int appointmentId,
    String status,
  ) async {
    final response = await _request(
      'PUT',
      '/appointments/$appointmentId/status',
      queryParameters: {'status': status},
    );
    if (response.statusCode == 200) {
      final data = _decodeData(response);
      return ViewingAppointment.fromJson(data as Map<String, dynamic>);
    }
    throw _errorFrom(response, 'Không thể cập nhật trạng thái lịch hẹn');
  }

  // --- TIN NHẮN TRÒ CHUYỆN (REALTIME CHAT) ---
  Future<ChatMessage> sendChatMessage({
    required int receiverId,
    required String content,
    String? imageUrl,
  }) async {
    final response = await _request(
      'POST',
      '/chat/messages',
      body: {
        'receiverId': receiverId,
        'content': content,
        'imageUrl': imageUrl,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _decodeData(response);
      if (data is Map<String, dynamic>) {
        return ChatMessage.fromJson(data);
      }
      throw const ApiException('Dữ liệu tin nhắn không hợp lệ');
    }
    throw _errorFrom(response, 'Không thể gửi tin nhắn');
  }

  Future<List<ChatMessage>> getChatMessages(int partnerId) async {
    final response = await _request('GET', '/chat/messages/$partnerId');
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw _errorFrom(response, 'Không tải được tin nhắn');
  }

  // --- BÁO CÁO VI PHẠM (REPORTS) ---
  Future<bool> submitReport({
    required int targetId,
    String targetType = 'USER',
    required String reason,
    String? evidenceObjectKey,
  }) async {
    final response = await _request(
      'POST',
      '/reports',
      body: {
        'targetId': targetId,
        'targetType': targetType,
        'reason': reason,
        'evidenceObjectKey': ?evidenceObjectKey,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    throw _errorFrom(response, 'Không thể gửi báo cáo vi phạm');
  }

  // --- HỦY KẾT NỐI (CANCEL CONNECTION) ---
  Future<bool> cancelConnection(int partnerId) async {
    final response = await _request(
      'DELETE',
      '/matches/connections/$partnerId',
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw _errorFrom(response, 'Không thể hủy kết nối');
  }

  // --- HỦY LỜI MỜI ĐÃ GỬI (CANCEL SENT REQUEST) ---
  Future<bool> cancelSentRequest(int targetUserId) async {
    final response = await _request(
      'DELETE',
      '/matches/requests/outgoing/$targetUserId',
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw _errorFrom(response, 'Không thể hủy lời mời');
  }

  // --- QUẢN LÝ BÁO CÁO ADMIN (ADMIN REPORTS) ---
  Future<List<dynamic>> getAdminReports() async {
    final response = await _request('GET', '/admin/reports');
    if (response.statusCode == 200) return _decodeList(response);
    throw _errorFrom(response, 'Không tải được danh sách báo cáo');
  }

  Future<bool> moderateAdminReport(
    int reportId, {
    required String status,
    String? note,
  }) async {
    final query = <String, String>{'status': status};
    if (note != null && note.isNotEmpty) query['note'] = note;
    final response = await _request(
      'PUT',
      '/admin/reports/$reportId/moderate',
      queryParameters: query,
    );
    if (response.statusCode == 200) return true;
    throw _errorFrom(response, 'Không thể xử lý báo cáo');
  }

  // --- ĐÓNG TIN ĐĂNG (CLOSE ROOM POST) ---
  Future<bool> closeRoomPost(int postId) async {
    final response = await _request('DELETE', '/posts/$postId');
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw _errorFrom(response, 'Không thể đóng tin đăng');
  }

  // --- QUẢN LÝ CHẶN (BLOCK / UNBLOCK) ---
  Future<List<BlockedUser>> getBlockedUsers() async {
    final response = await _request('GET', '/blocks');
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map((json) => BlockedUser.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw _errorFrom(response, 'Không tải được danh sách người bị chặn');
  }

  Future<BlockedUser> blockUser(int targetUserId) async {
    final response = await _request(
      'POST',
      '/blocks',
      queryParameters: {'targetUserId': targetUserId.toString()},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _decodeData(response);
      return BlockedUser.fromJson(data as Map<String, dynamic>);
    }
    throw _errorFrom(response, 'Không thể chặn người dùng');
  }

  Future<bool> unblockUser(int targetUserId) async {
    final response = await _request('DELETE', '/blocks/$targetUserId');
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw _errorFrom(response, 'Không thể bỏ chặn người dùng');
  }

  // --- ĐỔI MẬT KHẨU (CHANGE PASSWORD) ---
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await _request(
      'PUT',
      '/auth/change-password',
      body: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw _errorFrom(response, 'Không thể thay đổi mật khẩu');
  }

  // --- QUÊN MẬT KHẨU & XÁC MINH EMAIL (PASSWORD RECOVERY & EMAIL VERIFICATION) ---
  Future<bool> forgotPassword(String email) async {
    final response = await _request(
      'POST',
      '/auth/forgot-password',
      body: {'email': email},
      authenticated: false,
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw _errorFrom(response, 'Không thể gửi yêu cầu quên mật khẩu');
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _request(
      'POST',
      '/auth/reset-password',
      body: {'email': email, 'code': code, 'newPassword': newPassword},
      authenticated: false,
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw _errorFrom(response, 'Không thể đặt lại mật khẩu');
  }

  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _request(
      'POST',
      '/auth/verify-email',
      body: {'email': email, 'code': code},
      authenticated: false,
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw _errorFrom(response, 'Không thể xác minh email');
  }

  Future<bool> sendVerificationEmail(String email) async {
    final response = await _request(
      'POST',
      '/auth/send-verification-email',
      body: {'email': email},
      authenticated: false,
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw _errorFrom(response, 'Không thể gửi mã xác minh');
  }

  // --- QUẢN LÝ BÀI ĐĂNG CỦA TÔI (MY ROOM POSTS) ---
  Future<List<RoomPost>> getMyPosts() async {
    final response = await _request('GET', '/posts/my');
    if (response.statusCode == 200) {
      final list = _decodeList(response);
      return list
          .map((item) => RoomPost.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw _errorFrom(response, 'Không tải được danh sách bài đăng của bạn');
  }

  Future<RoomPost> updateRoomPost({
    required int postId,
    required String title,
    required String description,
    required double price,
    required String address,
    required String district,
    required double deposit,
    required String electricityWaterCost,
    required double area,
    required int maxOccupants,
    int? currentOccupants,
    required List<String> amenities,
    String? imageObjectKey,
  }) async {
    final cleanCostStr = electricityWaterCost
        .replaceAll('.', '')
        .replaceAll('đ', '')
        .replaceAll('/tháng', '')
        .trim();
    final costDouble = double.tryParse(cleanCostStr);
    if (costDouble == null || costDouble < 0) {
      throw const ApiException('Chi phí điện / nước phải là số tiền không âm');
    }
    final amenitiesString = amenities.join(',');
    final response = await _request(
      'PUT',
      '/posts/$postId',
      body: {
        'title': title,
        'description': description,
        'price': price,
        'address': address,
        'district': district,
        'deposit': deposit,
        'electricityWaterCost': costDouble,
        'area': area,
        'maxOccupants': maxOccupants,
        'currentOccupants': currentOccupants,
        'amenities': amenitiesString,
        'imageObjectKey': imageObjectKey,
      },
    );
    if (response.statusCode == 200) {
      final data = _decodeData(response);
      return RoomPost.fromJson(data as Map<String, dynamic>);
    }
    throw _errorFrom(response, 'Không thể cập nhật bài đăng');
  }

  Future<Map<String, dynamic>> getPublicProfile(int userId) async {
    final response = await _request('GET', '/profile/public/$userId');
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Không tải được hồ sơ công khai');
    }
    return _decodeData(response) as Map<String, dynamic>;
  }

  Future<RoomPost> getRoomPost(int postId) async {
    final response = await _request('GET', '/posts/$postId');
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Không tải được tin phòng');
    }
    return RoomPost.fromJson(_decodeData(response) as Map<String, dynamic>);
  }

  Future<bool> getSearchStatus() async {
    final response = await _request('GET', '/profile/search-status');
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Không tải được trạng thái tìm bạn');
    }
    final data = _decodeData(response) as Map<String, dynamic>;
    isSearchActive = data['searchActive'] == true;
    return isSearchActive;
  }

  Future<void> updateSearchStatus(bool value) async {
    final response = await _request(
      'PUT',
      '/profile/search-status',
      body: {'searchActive': value},
    );
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Không cập nhật được trạng thái tìm bạn');
    }
    isSearchActive = value;
  }
}
