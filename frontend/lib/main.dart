import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const RoommateHubApp());
}

class RoommateHubApp extends StatelessWidget {
  const RoommateHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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