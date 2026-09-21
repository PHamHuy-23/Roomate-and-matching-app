import 'package:flutter/material.dart';

/// The neutral profile placeholder used in the admin header.
class AdminProfileAvatar extends StatelessWidget {
  const AdminProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        color: Colors.grey.shade300,
        child: const Icon(Icons.person, color: Colors.grey),
      ),
    );
  }
}
