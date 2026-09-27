import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/auth_support_screen.dart';
import '../screens/avatar_picker_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/listing_management_screen.dart';
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
  static const listingManagement = '/listing-management';
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

        const adminRouteNames = {
          admin,
          adminDashboard,
          adminUsers,
          adminUserDetails,
          adminConfirmLock,
          adminLockedAccount,
          adminModeratePost,
          adminPostApproved,
          adminPostNeedsEdit,
          adminReports,
          adminReportResolved,
        };
        final isAdmin = {
          'ADMIN',
          'ROLE_ADMIN',
        }.contains(user.role.trim().toUpperCase());
        if (adminRouteNames.contains(routeSettings.name) && !isAdmin) {
          return HomeScreen(currentUser: user);
        }

        switch (routeSettings.name) {
          case changePassword:
            return const AuthSupportScreen(
              mode: AuthSupportMode.changePassword,
            );
          case home:
            final arguments = routeSettings.arguments;
            final initialTab = arguments is Map && arguments['initialTab'] is int
                ? arguments['initialTab'] as int
                : 0;
            return HomeScreen(currentUser: user, initialTab: initialTab);
          case profile:
            return ProfileScreen(currentUser: user);
          case editProfile:
            return EditProfileScreen(currentUser: user);
          case avatarPicker:
            return AvatarPickerScreen(currentUser: user);
          case settings:
            return const SettingsScreen();
          case roommateProfile:
            final arguments = routeSettings.arguments;
            final userId = arguments is Map && arguments['userId'] is int
                ? arguments['userId'] as int
                : null;
            final displayName = arguments is Map && arguments['partnerName'] is String
                ? arguments['partnerName'] as String
                : null;
            return RoommateProfileScreen(
              userId: userId,
              displayName: displayName,
            );
          case posterProfile:
            final arguments = routeSettings.arguments;
            final userId = arguments is Map && arguments['userId'] is int
                ? arguments['userId'] as int
                : null;
            final roomId = arguments is Map && arguments['roomId'] is int
                ? arguments['roomId'] as int
                : null;
            return PosterProfileScreen(userId: userId, roomId: roomId);
          case contactDetails:
            final arguments = routeSettings.arguments;
            final contactId = arguments is Map && arguments['contactId'] is int
                ? arguments['contactId'] as int
                : null;
            final contactName = arguments is Map && arguments['partnerName'] is String
                ? arguments['partnerName'] as String
                : null;
            return ContactDetailsScreen(
              contactId: contactId,
              contactName: contactName,
            );
          case chat:
            final arguments = routeSettings.arguments;
            final partnerId = arguments is Map && arguments['partnerId'] is int
                ? arguments['partnerId'] as int
                : null;
            final partnerName = arguments is Map && arguments['partnerName'] is String
                ? arguments['partnerName'] as String
                : null;
            return ChatScreen(partnerId: partnerId, partnerName: partnerName);
          case conversation:
            final contactName = routeSettings.arguments is String
                ? routeSettings.arguments as String
                : 'Minh Anh';
            return ConversationScreen(contactName: contactName);
          case sendRequest:
            final arguments = routeSettings.arguments;
            final partnerId = arguments is Map && arguments['partnerId'] is int
                ? arguments['partnerId'] as int
                : null;
            final partnerName = arguments is Map && arguments['partnerName'] is String
                ? arguments['partnerName'] as String
                : null;
            final matchScore = arguments is Map && arguments['matchScore'] is num
                ? (arguments['matchScore'] as num).toDouble()
                : 0.0;
            return SendRequestScreen(
              currentUserId: user.userId,
              partnerId: partnerId,
              partnerName: partnerName,
              matchScore: matchScore,
            );
          case sentRequest:
            final arguments = routeSettings.arguments;
            final partnerId = arguments is Map && arguments['partnerId'] is int
                ? arguments['partnerId'] as int
                : null;
            final partnerName = arguments is Map && arguments['partnerName'] is String
                ? arguments['partnerName'] as String
                : null;
            return SentRequestScreen(
              currentUserId: user.userId,
              partnerId: partnerId,
              partnerName: partnerName,
            );
          case receivedRequests:
            return ReceivedRequestsScreen(currentUserId: user.userId);
          case cancelConnection:
            final arguments = routeSettings.arguments;
            final partnerId = arguments is Map && arguments['partnerId'] is int
                ? arguments['partnerId'] as int
                : null;
            return CancelConnectionScreen(partnerId: partnerId);
          case blockedUsers:
            return const BlockedUsersScreen();
          case notifications:
            return NotificationsScreen(
              onItemTap: (item) {
                if (item.title.contains('lời mời')) {
                  Navigator.pushNamed(context, requests);
                } else if (item.title.contains('Lịch xem phòng')) {
                  Navigator.pushNamed(context, listingManagement);
                } else {
                  Navigator.pushNamed(
                    context,
                    conversation,
                    arguments: item.title,
                  );
                }
              },
            );
          case privacy:
            return const PrivacyScreen();
          case reportViolation:
            final arguments = routeSettings.arguments;
            final targetUserId = arguments is Map && arguments['targetUserId'] is int
                ? arguments['targetUserId'] as int
                : null;
            return ReportViolationScreen(targetUserId: targetUserId);
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
            final arguments = routeSettings.arguments;
            final rawDetailUser = arguments is Map && arguments['user'] is Map
                ? arguments['user'] as Map
                : arguments is Map
                    ? arguments
                    : null;
            final detailUser = rawDetailUser == null
                ? null
                : <String, String>{
                    for (final entry in rawDetailUser.entries)
                      entry.key.toString(): entry.value.toString(),
                  };
            final onStatusChanged = arguments is Map &&
                    arguments['onStatusChanged'] is void Function(String)
                ? arguments['onStatusChanged'] as void Function(String)
                : null;
            return AdminUserDetailsScreen(
              user: detailUser,
              onStatusChanged: onStatusChanged,
            );
          case adminConfirmLock:
            final arguments = routeSettings.arguments;
            final rawConfirmUser = arguments is Map && arguments['user'] is Map
                ? arguments['user'] as Map
                : arguments is Map
                    ? arguments
                    : null;
            final confirmUser = rawConfirmUser == null
                ? null
                : <String, String>{
                    for (final entry in rawConfirmUser.entries)
                      entry.key.toString(): entry.value.toString(),
                  };
            final onStatusChanged = arguments is Map &&
                    arguments['onStatusChanged'] is void Function(String)
                ? arguments['onStatusChanged'] as void Function(String)
                : null;
            return AdminConfirmLockScreen(
              user: confirmUser,
              onStatusChanged: onStatusChanged,
            );
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
          case listingManagement:
            return ListingManagementScreen(
              mode: ListingFlowMode.myListings,
              authorId: user.userId,
            );
          case admin:
            if ({
              'ADMIN',
              'ROLE_ADMIN',
            }.contains(user.role.trim().toUpperCase())) {
              return const AdminDashboardScreen();
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
