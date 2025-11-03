import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SaveCsv {
  static Future<void> save(
    BuildContext context,
    List<Map<String, dynamic>> summary,
    String fileName,
  ) async {
    try {
      final header = 'User,Amount\n';
      final rows = summary
          .map((row) {
            final name = row['name'] ?? '';
            final amount = row['amount'] is num
                ? (row['amount'] as num).toStringAsFixed(2)
                : row['amount'].toString();
            return '"$name",$amount';
          })
          .join('\n');

      final csv = '$header$rows';
      Directory? targetDir;

      try {
        if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'];
          if (userProfile != null && userProfile.isNotEmpty) {
            targetDir = Directory(p.join(userProfile, 'Documents'));
          }
        } else if (Platform.isMacOS || Platform.isLinux) {
          final home = Platform.environment['HOME'];
          if (home != null && home.isNotEmpty) {
            targetDir = Directory(p.join(home, 'Documents'));
          }
        }
      } catch (_) {}

      if (targetDir == null) {
        try {
          final dirs = await getExternalStorageDirectories(
              type: StorageDirectory.documents);
          if (dirs != null && dirs.isNotEmpty) {
            targetDir = dirs.first;
          }
        } catch (_) {}

        targetDir ??= await getApplicationDocumentsDirectory();
      }

      final splitDir = Directory(p.join(targetDir.path, 'splitapp'));
      if (!await splitDir.exists()) {
        await splitDir.create(recursive: true);
      }

      final file = File(p.join(splitDir.path, fileName));
      await file.writeAsString(csv);

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV saved to ${file.path}')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save CSV: $e')));
    }
  }
}
