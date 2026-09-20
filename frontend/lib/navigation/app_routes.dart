import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/admin_screen.dart';
import '../screens/auth_support_screen.dart';
import '../screens/avatar_picker_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/conversation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/penpot_state_screens.dart';
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
import '../screens/privacy_screen.dart';
import '../screens/report_violation_screen.dart';
import '../screens/report_received_screen.dart';
import '../screens/help_safety_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_user_details_screen.dart';
import '../screens/admin/admin_confirm_lock_screen.dart';
import '../screens/admin/admin_locked_account_screen.dart';
import '../screens/admin/admin_moderate_post_screen.dart';
import '../screens/admin/admin_post_approved_screen.dart';
import '../screens/admin/admin_post_needs_edit_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/admin/admin_report_resolved_screen.dart';
import '../screens/survey_screen.dart';
import '../state/auth_session.dart';

class AppRoutes {
  AppRoutes._();

  // Auth routes
  static const login = '/login';
  static const welcome = '/welcome';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const newPassword = '/new-password';
  static const changePassword = '/change-password';

  // Main routes
  static const home = '/home';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const avatarPicker = '/avatar-picker';
  static const requests = '/requests';
  static const survey = '/survey';
  static const createPost = '/create-post';
  static const settings = '/settings';

  // Social routes
  static const roommateProfile = '/roommate-profile';
  static const posterProfile = '/poster-profile';
  static const contactDetails = '/contact-details';
  static const chat = '/chat';
  static const conversation = '/conversation';
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

  // State routes (penpot)
  static const noResults = '/no-results';
  static const offline = '/offline';
  static const roomUnavailable = '/room-unavailable';
  static const loadingRoom = '/loading-room';

  // Admin routes
  static const admin = '/admin';
  static const adminDashboard = '/admin/dashboard';
  static const adminUsers = '/admin/users';
  static const adminUserDetails = '/admin/user-details';
  static const adminConfirmLock = '/admin/confirm-lock';
  static const adminLockedAccount = '/admin/locked-account';
  static const adminModeratePost = '/admin/moderate-post';
  static const adminPostApproved = '/admin/post-approved';
  static const adminPostNeedsEdit = '/admin/post-needs-edit';
  static const adminReports = '/admin/reports';
  static const adminReportResolved = '/admin/report-resolved';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    return MaterialPageRoute<dynamic>(
      settings: routeSettings,
      builder: (context) {
        final session = context.read<AuthSession>();

        // Handle login with optional register flag
        if (routeSettings.name == login) {
          final arguments = routeSettings.arguments;
          final initialRegister =
              arguments is Map && arguments['register'] == true;
          return LoginScreen(initialRegister: initialRegister);
        }

        // Pre-auth support screens (no login required)
        switch (routeSettings.name) {
          case welcome:
            return const AuthSupportScreen(mode: AuthSupportMode.welcome);
          case verifyEmail:
            return AuthSupportScreen(
              mode: AuthSupportMode.verifyEmail,
              email: routeSettings.arguments is String
                  ? routeSettings.arguments as String
                  : null,
            );
          case forgotPassword:
            return AuthSupportScreen(
              mode: AuthSupportMode.forgotPassword,
              email: routeSettings.arguments is String
                  ? routeSettings.arguments as String
                  : null,
            );
          case newPassword:
            return const AuthSupportScreen(mode: AuthSupportMode.newPassword);
        }

        // Guard: require authentication
        final user = session.user;
        if (!session.isAuthenticated || user == null) {
          return const LoginScreen();
        }

        switch (routeSettings.name) {
          case changePassword:
            return const AuthSupportScreen(
              mode: AuthSupportMode.changePassword,
            );
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
          case conversation:
            final contactName = routeSettings.arguments is String
                ? routeSettings.arguments as String
                : 'Minh Anh';
            return ConversationScreen(contactName: contactName);
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
            return NotificationsScreen(
              onItemTap: (_) =>
                  Navigator.pushNamed(context, conversation),
            );
          case privacy:
            return const PrivacyScreen();
          case reportViolation:
            return const ReportViolationScreen();
          case reportReceived:
            return const ReportReceivedScreen();
          case helpSafety:
            return const HelpSafetyScreen();
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
          case adminDashboard:
            return const AdminDashboardScreen();
          case adminUsers:
            return const AdminUsersScreen();
          case adminUserDetails:
            return const AdminUserDetailsScreen();
          case adminConfirmLock:
            return const AdminConfirmLockScreen();
          case adminLockedAccount:
            return const AdminLockedAccountScreen();
          case adminModeratePost:
            return const AdminModeratePostScreen();
          case adminPostApproved:
            return const AdminPostApprovedScreen();
          case adminPostNeedsEdit:
            return const AdminPostNeedsEditScreen();
          case adminReports:
            return const AdminReportsScreen();
          case adminReportResolved:
            return const AdminReportResolvedScreen();
          case requests:
            return RequestsScreen(currentUserId: user.userId);
          case survey:
            final arguments = routeSettings.arguments;
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
                child: Text('Không tìm thấy trang: ${routeSettings.name}'),
              ),
            );
        }
      },
    );
  }
}
