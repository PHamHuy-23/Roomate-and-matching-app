import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  ApiService.configureUnauthorizedHandler(() {
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    appScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Phiên làm việc đã hết hạn')),
    );
  });
  runApp(const RoommateHubApp());
}

class RoommateHubApp extends StatelessWidget {
  const RoommateHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      title: 'Roommate Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
