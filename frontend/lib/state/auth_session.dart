import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../services/api_service.dart';

/// Trạng thái đăng nhập dùng chung cho toàn bộ cây widget.
class AuthSession extends ChangeNotifier {
  AuthSession({ApiService? apiService}) : _api = apiService ?? ApiService();

  final ApiService _api;
  AuthUser? _user;

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null && _api.hasAuthToken;

  Future<AuthUser> login(String email, String password) async {
    final user = await _api.login(email, password);
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
    final user = await _api.register(
      email,
      password,
      fullName,
      gender,
      phone,
      birthDate,
      university,
    );
    _user = user;
    notifyListeners();
    return user;
  }

  void updateUser(AuthUser updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String gender,
    required DateTime birthDate,
    required String university,
  }) async {
    final currentUser = _user;
    if (currentUser == null) return false;

    final updated = await _api.updateProfile(
      currentUser.userId,
      fullName,
      phone,
      gender,
      birthDate,
      university,
    );
    if (updated) {
      updateUser(
        currentUser.copyWith(
          fullName: fullName,
          phone: phone,
          gender: gender,
          birthDate: birthDate,
          university: university,
        ),
      );
    }
    return updated;
  }

  void signOut() {
    _api.clearAuthToken();
    _user = null;
    notifyListeners();
  }
}
