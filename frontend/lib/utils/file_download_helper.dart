import 'package:flutter/material.dart';

import 'file_download_helper_stub.dart'
    if (dart.library.js_interop) 'file_download_helper_web.dart' as impl;

class FileDownloadHelper {
  FileDownloadHelper._();

  static Future<void> downloadCsv({
    required BuildContext context,
    required String fileName,
    required String csvContent,
  }) async {
    await impl.saveCsvFile(
      context: context,
      fileName: fileName,
      csvContent: csvContent,
    );
  }
}
