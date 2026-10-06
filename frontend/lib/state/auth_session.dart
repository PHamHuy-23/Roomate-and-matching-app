import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../services/api_service.dart';

/// Trạng thái đăng nhập dùng chung cho toàn bộ cây widget.
class AuthSession extends ChangeNotifier {
  AuthSession({ApiService? apiService}) : _api = apiService ?? ApiService();

  final ApiService _api;
  AuthUser? _user;
  int _generation = 0;

  int get generation => _generation;

  bool isCurrentSession(int generation, int userId) =>
      generation == _generation && _user?.userId == userId && isAuthenticated;

  void _ensureCurrentOperation(int generation) {
    if (generation != _generation) {
      throw const ApiException('Phiên đăng nhập đã thay đổi, vui lòng thử lại');
    }
  }

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null && _api.hasAuthToken;

  Future<AuthUser> login(String email, String password) async {
    final generation = ++_generation;
    final login = _api.login(email, password);
    _user = null;
    notifyListeners();
    final user = await login;
    _ensureCurrentOperation(generation);
    _user = user;
    notifyListeners();
    return user;
  }

  /// Returns whether the signed-in user has completed the matching survey.
  ///
  /// A missing preferences resource (the API's 404 response) means the user
  /// should be sent through the five-step onboarding flow. If the preferences
  /// endpoint is temporarily unavailable, return null so callers can keep the
  /// user in the normal authenticated flow instead of treating an outage as
  /// an incomplete profile.
  Future<bool?> hasPreferences() async {
    final currentUser = _user;
    if (currentUser == null) return null;
    try {
      final preferences = await _api.getPreferences(currentUser.userId);
      return preferences != null;
    } catch (_) {
      return null;
    }
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
    final generation = ++_generation;
    final registration = _api.register(
      email,
      password,
      fullName,
      gender,
      phone,
      birthDate,
      university,
    );
    _user = null;
    notifyListeners();
    final user = await registration;
    _ensureCurrentOperation(generation);
    _user = user;
    notifyListeners();
    return user;
  }

  void updateUser(AuthUser updatedUser, {int? expectedGeneration}) {
    if (expectedGeneration != null &&
        !isCurrentSession(expectedGeneration, updatedUser.userId)) {
      return;
    }
    if (_user?.userId != updatedUser.userId) _generation++;
    _user = updatedUser;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String gender,
    required DateTime? birthDate,
    required String? university,
    String? bioNote,
  }) async {
    final currentUser = _user;
    if (currentUser == null || !isAuthenticated) return false;
    final generation = _generation;

    final updated = await _api.updateProfile(
      currentUser.userId,
      fullName,
      phone,
      gender,
      birthDate,
      university,
      bioNote: bioNote,
    );
    if (!isCurrentSession(generation, currentUser.userId)) return false;
    final latest = _user!;
    if (updated.userId != currentUser.userId) {
      throw const ApiException('Dữ liệu hồ sơ từ máy chủ không hợp lệ');
    }
    updateUser(
      updated.copyWith(
        token: _api.authToken ?? latest.token,
        refreshToken: _api.refreshToken ?? latest.refreshToken,
        // An avatar confirmed while this request was pending is newer than its response snapshot.
        avatarUrl: latest.avatarUrl != currentUser.avatarUrl
            ? latest.avatarUrl
            : updated.avatarUrl,
      ),
      expectedGeneration: generation,
    );
    return true;
  }

  Future<void> signOut() async {
    _generation++;
    // Start revocation first: logout invalidates the transport synchronously.
    final logout = Future<void>.sync(_api.logout);
    _user = null;
    notifyListeners();
    try {
      await logout;
    } catch (_) {}
  }
}
