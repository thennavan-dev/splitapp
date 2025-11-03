import 'package:flutter/material.dart';
import 'package:splitapp/utils/database_helper.dart';

class UserScreen extends StatefulWidget {
  final List<Map<String, dynamic>> splits;
  final List<Map<String, dynamic>> users;

  const UserScreen({super.key, required this.splits, required this.users});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Map<int, Map<int, double>> debts = {};
  Map<int, double> netBalance = {};
  Map<int, double> pendingToPay = {};
  Map<int, String> userMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _computeBalances();
  }

  @override
  void didUpdateWidget(covariant UserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users != widget.users || oldWidget.splits != widget.splits) {
      setState(() {
        _loading = true;
      });
      _computeBalances();
    }
  }

  Future<void> _computeBalances() async {
    userMap = {
      for (var u in widget.users) u['id'] as int: u['user_name'] as String,
    };

    debts = {for (var u in widget.users) u['id'] as int: <int, double>{}};

    final futures = <Future<void>>[];

    for (var split in widget.splits) {
      futures.add(_processSplit(split));
    }

    await Future.wait(futures);

    netBalance = {};
    pendingToPay = {};
    for (var u in debts.keys) {
      double receive = 0.0;
      double owe = 0.0;
      double pending = 0.0;
      for (var v in debts.keys) {
        if (u == v) continue;
        receive += debts[v]?[u] ?? 0.0;
        owe += debts[u]?[v] ?? 0.0;

        final userOwes = debts[u]?[v] ?? 0.0;
        final otherOwes = debts[v]?[u] ?? 0.0;
        final netUserOwesToV = (userOwes - otherOwes) > 0
            ? (userOwes - otherOwes)
            : 0.0;
        pending += netUserOwesToV;
      }
      netBalance[u] = receive - owe;
      pendingToPay[u] = pending;
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _processSplit(Map<String, dynamic> split) async {
    final splitId = split['id'] as int;
    final creator = split['created_by'] as int;
    final amount = (split['amount'] as num).toDouble();

    final parts = await dbHelper.getParticipants(splitId);
    final participantIds = parts.map((p) => p['id'] as int).toList();

    final involvedCount = 1 + participantIds.length;
    if (participantIds.isEmpty) return;

    final perPerson = amount / involvedCount;

    for (var pid in participantIds) {
      debts[pid] ??= {};
      debts[pid]![creator] = (debts[pid]![creator] ?? 0.0) + perPerson;
    }
  }

  void _showUserDetails(int userId) {
    final entries = <Map<String, dynamic>>[];

    for (var other in debts.keys) {
      if (other == userId) continue;
      final userOwes = debts[userId]?[other] ?? 0.0;
      final otherOwes = debts[other]?[userId] ?? 0.0;
      final netUserOwesToOther = userOwes - otherOwes;
      if (netUserOwesToOther > 0) {
        entries.add({
          'otherId': other,
          'otherName': userMap[other] ?? 'Unknown',
          'amount': netUserOwesToOther,
        });
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(userMap[userId] ?? 'To pay'),
        content: entries.isEmpty
            ? const Text('No pending payments — 0')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    final amt = e['amount'] as double;
                    return ListTile(
                      title: Text(e['otherName']),
                      subtitle: Text('You owe: ₹${amt.toStringAsFixed(2)}'),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final users = widget.users;

    return ListView(
      children: users.map((u) {
        final userId = u['id'] as int;
        final name = u['user_name'] as String;
        final pending = pendingToPay[userId] ?? 0.0;

        final Widget subtitleWidget = Text(
          'Pending to pay: ₹${pending.toStringAsFixed(2)}',
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            title: Text(name),
            subtitle: subtitleWidget,
            onTap: () => _showUserDetails(userId),
          ),
        );
      }).toList(),
    );
  }
}
