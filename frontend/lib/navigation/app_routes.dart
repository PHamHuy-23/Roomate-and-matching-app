import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/admin_screen.dart';
import '../screens/auth_support_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/conversation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/penpot_state_screens.dart';
import '../screens/requests_screen.dart';
import '../screens/survey_screen.dart';
import '../state/auth_session.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const home = '/home';
  static const profile = '/profile';
  static const requests = '/requests';
  static const survey = '/survey';
  static const createPost = '/create-post';
  static const admin = '/admin';
  static const welcome = '/welcome';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const newPassword = '/new-password';
  static const changePassword = '/change-password';
  static const blockedUsers = '/blocked-users';
  static const notifications = '/notifications';
  static const noResults = '/no-results';
  static const offline = '/offline';
  static const roomUnavailable = '/room-unavailable';
  static const loadingRoom = '/loading-room';
  static const conversation = '/conversation';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (context) {
        final session = context.read<AuthSession>();
        if (settings.name == login) {
          final arguments = settings.arguments;
          final initialRegister =
              arguments is Map && arguments['register'] == true;
          return LoginScreen(initialRegister: initialRegister);
        }
        switch (settings.name) {
          case welcome:
            return const AuthSupportScreen(mode: AuthSupportMode.welcome);
          case verifyEmail:
            return AuthSupportScreen(
              mode: AuthSupportMode.verifyEmail,
              email: settings.arguments is String
                  ? settings.arguments as String
                  : null,
            );
          case forgotPassword:
            return AuthSupportScreen(
              mode: AuthSupportMode.forgotPassword,
              email: settings.arguments is String
                  ? settings.arguments as String
                  : null,
            );
          case newPassword:
            return const AuthSupportScreen(mode: AuthSupportMode.newPassword);
        }

        final user = session.user;
        if (!session.isAuthenticated || user == null) {
          return const LoginScreen();
        }

        switch (settings.name) {
          case changePassword:
            return const AuthSupportScreen(
              mode: AuthSupportMode.changePassword,
            );
          case blockedUsers:
            return const BlockedUsersScreen();
          case notifications:
            return NotificationsScreen(
              onItemTap: (_) => Navigator.pushNamed(context, conversation),
            );
          case noResults:
            return const PenpotStateScreen(mode: PenpotStateMode.noResults);
          case offline:
            return const PenpotStateScreen(mode: PenpotStateMode.offline);
          case roomUnavailable:
            return const PenpotStateScreen(
              mode: PenpotStateMode.roomUnavailable,
            );
          case loadingRoom:
            return const PenpotStateScreen(mode: PenpotStateMode.loadingRoom);
          case conversation:
            final contactName = settings.arguments is String
                ? settings.arguments as String
                : 'Minh Anh';
            return ConversationScreen(contactName: contactName);
          case home:
            return HomeScreen(currentUser: user);
          case profile:
            return ProfileScreen(currentUser: user);
          case requests:
            return RequestsScreen(currentUserId: user.userId);
          case survey:
            final arguments = settings.arguments;
            final fromRegistration =
                arguments is Map && arguments['fromRegistration'] == true;
            return SurveyScreen(
              userId: user.userId,
              redirectToHomeOnComplete: fromRegistration,
            );
          case createPost:
            return CreatePostScreen(authorId: user.userId);
          case admin:
            if (user.role == 'ROLE_ADMIN' || user.role == 'ADMIN') {
              return const AdminScreen();
            }
            return HomeScreen(currentUser: user);
          default:
            return Scaffold(
              body: Center(
                child: Text('Không tìm thấy trang: ${settings.name}'),
              ),
            );
        }
      },
    );
  }
}
