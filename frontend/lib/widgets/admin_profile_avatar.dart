import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../services/api_service.dart';

/// The interactive profile avatar used in the admin header.
class AdminProfileAvatar extends StatelessWidget {
  const AdminProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Tài khoản quản trị viên',
      onSelected: (value) {
        if (value == 'user_app') {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else if (value == 'logout') {
          ApiService().clearAuthToken();
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'user_app',
          child: Row(
            children: [
              Icon(Icons.home_outlined, color: Color(0xFF087E6B), size: 20),
              SizedBox(width: 10),
              Text('Về ứng dụng người dùng'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent, size: 20),
              SizedBox(width: 10),
              Text('Đăng xuất quản trị'),
            ],
          ),
        ),
      ],
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          color: const Color(0xFFEAF8F5),
          child: const Icon(Icons.person, color: Color(0xFF087E6B)),
        ),
      ),
    );
  }
}
