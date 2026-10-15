import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigation/app_routes.dart';
import 'services/api_service.dart';
import 'state/auth_session.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authSession = AuthSession();
  await authSession.restoreSession();

  ApiService.configureUnauthorizedHandler(() {
    appNavigatorKey.currentContext?.read<AuthSession>().signOut();
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
    appScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Phiên làm việc đã hết hạn')),
    );
  });
  runApp(RoommateHubApp(authSession: authSession));
}

class RoommateHubApp extends StatelessWidget {
  const RoommateHubApp({super.key, this.authSession});

  final AuthSession? authSession;

  @override
  Widget build(BuildContext context) {
    final session = authSession;
    final initialRoute = session != null && session.isAuthenticated
        ? (session.user?.role.toUpperCase().contains('ADMIN') == true
            ? AppRoutes.adminDashboard
            : AppRoutes.home)
        : AppRoutes.welcome;

    return ChangeNotifierProvider(
      create: (_) => authSession ?? AuthSession(),
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        title: 'Roommate Hub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        initialRoute: initialRoute,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
