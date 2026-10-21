import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Future<void> saveCsvFile({
  required BuildContext context,
  required String fileName,
  required String csvContent,
}) async {
  // Chuẩn bị byte dữ liệu với UTF-8 BOM để Excel hiển thị tiếng Việt có dấu không bị lỗi font
  final bom = [0xEF, 0xBB, 0xBF];
  final contentBytes = utf8.encode(csvContent);
  final allBytes = Uint8List.fromList([...bom, ...contentBytes]);

  final jsArray = [allBytes.buffer.toJS].toJS;
  final blobPropertyBag = web.BlobPropertyBag(type: 'text/csv;charset=utf-8;');
  final blob = web.Blob(jsArray, blobPropertyBag);

  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;

  web.document.body?.appendChild(anchor);
  anchor.click();

  anchor.remove();
  web.URL.revokeObjectURL(url);
}
