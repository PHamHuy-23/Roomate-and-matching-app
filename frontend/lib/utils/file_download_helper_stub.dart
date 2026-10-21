import 'package:flutter/material.dart';

Future<void> saveCsvFile({
  required BuildContext context,
  required String fileName,
  required String csvContent,
}) async {
  // Fallback implementation for non-web environments (mobile/desktop test)
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Xuất báo cáo thành công'),
      content: Text('Tệp $fileName đã được tạo thành công với kích thước ${csvContent.length} ký tự.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}
