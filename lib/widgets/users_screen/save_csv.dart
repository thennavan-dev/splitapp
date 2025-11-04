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
      final header = 'User,To,Amount\n';
      final rows = <String>[];

      for (final row in summary) {
        final name = row['name'] ?? '';
        final details = row['details'];

        if (details is List && details.isNotEmpty) {
          for (final d in details) {
            final to = d['to'] ?? '';
            final amount = d['amount'] is num
                ? (d['amount'] as num).toStringAsFixed(2)
                : d['amount'].toString();
            rows.add('"$name","$to",$amount');
          }
        } else {
          final amount = row['amount'] is num
              ? (row['amount'] as num).toStringAsFixed(2)
              : row['amount'].toString();
          rows.add('"$name","",$amount');
        }
      }

      final csv = '$header${rows.join('\n')}';
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
            type: StorageDirectory.documents,
          );
          if (dirs != null && dirs.isNotEmpty) {
            targetDir = dirs.first;
          }
        } catch (_) {}

        targetDir ??= await getApplicationDocumentsDirectory();
      }

      Directory target = targetDir;

      try {
        if (Platform.isAndroid) {
          final publicDocs = Directory('/storage/emulated/0/Documents');
          try {
            if (!await publicDocs.exists()) {
              await publicDocs.create(recursive: true);
            }
          } catch (_) {}

          if (await publicDocs.exists()) {
            target = publicDocs;
          } else {
            final pathStr = target.path.replaceAll('\\', '/');
            final idx = pathStr.indexOf('/Android/data');
            if (idx != -1) {
              final derived = pathStr.substring(0, idx) + '/Documents';
              final derivedDir = Directory(derived);
              try {
                if (!await derivedDir.exists())
                  await derivedDir.create(recursive: true);
              } catch (_) {}
              if (await derivedDir.exists()) target = derivedDir;
            }
          }
        }
      } catch (_) {}

      final splitDir = Directory(p.join(target.path, 'splitapp'));
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
