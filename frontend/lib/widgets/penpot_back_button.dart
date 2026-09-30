import 'package:flutter/material.dart';

/// Back control shared by the profile and profile-related Penpot screens.
///
/// The compact chevron keeps the header aligned with the Penpot reference
/// while still providing a full, accessible tap target.
class PenpotBackButton extends StatelessWidget {
  const PenpotBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 40,
      child: IconButton(
        onPressed: onPressed ?? () => Navigator.maybePop(context),
        tooltip: 'Quay lại',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 40),
        splashRadius: 18,
        icon: const Icon(
          Icons.chevron_left,
          size: 28,
          color: Color(0xFF142523),
        ),
      ),
    );
  }
}
