import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/admin_screen.dart';
import '../screens/avatar_picker_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/requests_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/roommate_profile_screen.dart';
import '../screens/poster_profile_screen.dart';
import '../screens/contact_details_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/send_request_screen.dart';
import '../screens/sent_request_screen.dart';
import '../screens/received_requests_screen.dart';
import '../screens/cancel_connection_screen.dart';
import '../screens/blocked_users_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/report_violation_screen.dart';
import '../screens/report_received_screen.dart';
import '../screens/help_safety_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_user_details_screen.dart';
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
  static const editProfile = '/edit-profile';
  static const avatarPicker = '/avatar-picker';
  static const settings = '/settings';
  static const roommateProfile = '/roommate-profile';
  static const posterProfile = '/poster-profile';
  static const contactDetails = '/contact-details';
  static const chat = '/chat';
  static const sendRequest = '/send-request';
  static const sentRequest = '/sent-request';
  static const receivedRequests = '/received-requests';
  static const cancelConnection = '/cancel-connection';
  static const blockedUsers = '/blocked-users';
  static const notifications = '/notifications';
  static const privacy = '/privacy';
  static const reportViolation = '/report-violation';
  static const reportReceived = '/report-received';
  static const helpSafety = '/help-safety';
  static const adminDashboard = '/admin/dashboard';
  static const adminUsers = '/admin/users';
  static const adminUserDetails = '/admin/user-details';

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
          case editProfile:
            return EditProfileScreen(currentUser: user);
          case avatarPicker:
            return AvatarPickerScreen(currentUser: user);
          case settings:
            return const SettingsScreen();
          case roommateProfile:
            return const RoommateProfileScreen();
          case posterProfile:
            return const PosterProfileScreen();
          case contactDetails:
            return const ContactDetailsScreen();
          case chat:
            return const ChatScreen();
          case sendRequest:
            return const SendRequestScreen();
          case sentRequest:
            return const SentRequestScreen();
          case receivedRequests:
            return const ReceivedRequestsScreen();
          case cancelConnection:
            return const CancelConnectionScreen();
          case blockedUsers:
            return const BlockedUsersScreen();
          case notifications:
            return const NotificationsScreen();
          case privacy:
            return const PrivacyScreen();
          case reportViolation:
            return const ReportViolationScreen();
          case reportReceived:
            return const ReportReceivedScreen();
          case helpSafety:
            return const HelpSafetyScreen();
          case adminDashboard:
            return const AdminDashboardScreen();
          case adminUsers:
            return const AdminUsersScreen();
          case adminUserDetails:
            return const AdminUserDetailsScreen();
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
