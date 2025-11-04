import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class SavePdf {
  static Future<void> save(
    BuildContext context,
    List<Map<String, dynamic>> summary,
    String fileName,
  ) async {
    try {
      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          build: (pw.Context ctx) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Split Summary',
                  style: pw.TextStyle(fontSize: 24),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Generated: ${DateTime.now()}'),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: ['User', 'To', 'Amount'],
                data: () {
                  final rows = <List<String>>[];
                  for (final s in summary) {
                    final name = s['name'] ?? '';
                    final details = s['details'];
                    if (details is List && details.isNotEmpty) {
                      for (final d in details) {
                        final to = d['to'] ?? '';
                        final amount = d['amount'] is num
                            ? (d['amount'] as num).toStringAsFixed(2)
                            : d['amount'].toString();
                        rows.add([name, to, amount]);
                      }
                    } else {
                      final amount = s['amount'] is num
                          ? (s['amount'] as num).toStringAsFixed(2)
                          : s['amount'].toString();
                      rows.add([name, '', amount]);
                    }
                  }
                  return rows;
                }(),
              ),
            ];
          },
        ),
      );

      final bytes = await doc.save();

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
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF saved to ${file.path}')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save PDF: $e')));
    }
  }
}
