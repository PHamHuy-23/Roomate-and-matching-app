import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/room_post.dart';
import '../screens/admin_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/requests_screen.dart';
import '../screens/room_detail_screen.dart';
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
  static const roomDetail = '/room-detail';
  static const admin = '/admin';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (context) {
        final session = context.read<AuthSession>();
        if (settings.name == login) return const LoginScreen();

        final user = session.user;
        if (!session.isAuthenticated || user == null) {
          return const LoginScreen();
        }

        switch (settings.name) {
          case home:
            return HomeScreen(currentUser: user);
          case profile:
            return ProfileScreen(currentUser: user);
          case requests:
            return RequestsScreen(currentUserId: user.userId);
          case survey:
            return SurveyScreen(userId: user.userId);
          case createPost:
            return CreatePostScreen(authorId: user.userId);
          case roomDetail:
            final post = settings.arguments as RoomPost;
            return RoomDetailScreen(post: post);
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
