import 'package:flutter/material.dart';
import 'package:splitapp/utils/database_helper.dart';
import 'package:splitapp/widgets/dashboard/show_add_split.dart';
import 'package:splitapp/widgets/dashboard/show_add_user.dart';
import 'package:splitapp/widgets/dashboard/split_screen/show_split.dart';
import 'package:splitapp/screens/split_screen.dart';
import 'package:splitapp/screens/user_screen.dart';
import 'package:splitapp/widgets/users_screen/save_csv.dart';
import 'package:splitapp/widgets/users_screen/save_pdf.dart';
import 'package:splitapp/widgets/bottom_nav_widget.dart';
import 'package:splitapp/screens/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _splits = [];
  List<Map<String, dynamic>> _users = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSplits();
  }

  Future<void> _loadSplits() async {
    final splits = await dbHelper.getSplits();
    final users = await dbHelper.getUsers();

    _users = users;

    final userMap = {for (var u in users) u['id']: u['user_name']};

    final splitsWithUser = splits.map((split) {
      final userId = split['created_by'];
      return {...split, 'created_by_name': userMap[userId] ?? 'Unknown User'};
    }).toList();

    setState(() {
      _splits = splitsWithUser;
    });
  }

  Future<void> _showAddSplit() async {
    await showAddSplitDialog(context);
    _loadSplits();
  }

  Future<void> _showAddUser() async {
    await showAddUserDialog(context);
    _loadSplits();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> screens = [
      _splits.isEmpty
          ? const Center(child: Text("No splits yet."))
          : ListView.builder(
              itemCount: _splits.length,
              itemBuilder: (context, index) {
                final split = _splits[index];
                return SplitCard(
                  split: split,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SplitScreen(split: split),
                      ),
                    );
                  },
                );
              },
            ),
      UserScreen(splits: _splits, users: _users),
      SettingsScreen(onDatabaseChanged: _loadSplits),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Split App"),
        centerTitle: true,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Add User',
              onPressed: _showAddUser,
            ),
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download user summary',
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                var dialogOpen = true;

                try {
                  final debts = <int, Map<int, double>>{
                    for (var u in _users) u['id'] as int: <int, double>{},
                  };

                  for (var split in _splits) {
                    final splitId = split['id'] as int;
                    final creator = split['created_by'] as int;
                    final amount = (split['amount'] as num).toDouble();

                    final parts = await dbHelper.getParticipants(splitId);
                    final participantIds = parts
                        .map((p) => p['id'] as int)
                        .toList();

                    final involvedCount = 1 + participantIds.length;
                    if (participantIds.isEmpty) continue;

                    final perPerson = amount / involvedCount;

                    for (var pid in participantIds) {
                      debts[pid] ??= {};
                      debts[pid]![creator] =
                          (debts[pid]![creator] ?? 0.0) + perPerson;
                    }
                  }

                  final pendingToPay = <int, double>{};
                  for (var u in debts.keys) {
                    double pending = 0.0;
                    for (var v in debts.keys) {
                      if (u == v) continue;
                      final userOwes = debts[u]?[v] ?? 0.0;
                      final otherOwes = debts[v]?[u] ?? 0.0;
                      final netUserOwesToV = (userOwes - otherOwes) > 0
                          ? (userOwes - otherOwes)
                          : 0.0;
                      pending += netUserOwesToV;
                    }
                    pendingToPay[u] = pending;
                  }

                  final userMap = {for (var u in _users) u['id'] as int: u['user_name'] as String};

                  final summary = _users.map((u) {
                    final uid = u['id'] as int;
                    final name = u['user_name'] as String;
                    final details = <Map<String, dynamic>>[];
                    double total = 0.0;

                    for (var v in debts.keys) {
                      if (u['id'] == v) continue;
                      final userOwes = debts[uid]?[v] ?? 0.0;
                      final otherOwes = debts[v]?[uid] ?? 0.0;
                      final net = (userOwes - otherOwes) > 0 ? (userOwes - otherOwes) : 0.0;
                      if (net > 0) {
                        details.add({'to': userMap[v] ?? 'Unknown', 'amount': net});
                        total += net;
                      }
                    }

                    return {
                      'name': name,
                      'amount': total,
                      'details': details,
                    };
                  }).toList();

                  if (!mounted) return;

                  if (dialogOpen && Navigator.canPop(context)) {
                    Navigator.pop(context);
                    dialogOpen = false;
                  }

                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.picture_as_pdf),
                            title: const Text('Save as PDF'),
                            onTap: () async {
                              Navigator.of(ctx).pop();
                              final fileName =
                                  'user_summary_${DateTime.now().millisecondsSinceEpoch}.pdf';
                              await SavePdf.save(
                                context,
                                List<Map<String, dynamic>>.from(summary),
                                fileName,
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.table_chart),
                            title: const Text('Save as CSV'),
                            onTap: () async {
                              Navigator.of(ctx).pop();
                              final fileName =
                                  'user_summary_${DateTime.now().millisecondsSinceEpoch}.csv';
                              await SaveCsv.save(
                                context,
                                List<Map<String, dynamic>>.from(summary),
                                fileName,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to build summary: $e')),
                  );
                } finally {
                  if (dialogOpen && Navigator.canPop(context))
                    Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddSplit,
              tooltip: 'Add Split',
              child: const Icon(Icons.add),
            )
          : null,
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavWidget(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
