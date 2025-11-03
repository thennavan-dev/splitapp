import 'package:flutter/material.dart';

class UserScreen extends StatelessWidget {
  final List<Map<String, dynamic>> splits;
  final List<Map<String, dynamic>> users;

  const UserScreen({super.key, required this.splits, required this.users});

  @override
  Widget build(BuildContext context) {
    final Map<int, String> userMap = {for (var u in users) u['id']: u['user_name']};

    final userIds = splits.map((s) => s['created_by']).toSet();
    final Map<int, double> totalPaid = {for (var id in userIds) id: 0};

    for (var split in splits) {
      final userId = split['created_by'];
      totalPaid[userId] = (totalPaid[userId] ?? 0) + (split['amount'] as num).toDouble();
    }

    final totalAmount = totalPaid.values.fold(0.0, (sum, val) => sum + val);
    final perUserShare = totalAmount / userIds.length;

    final Map<int, double> balance = {};
    totalPaid.forEach((userId, paid) {
      balance[userId] = paid - perUserShare;
    });

    return ListView(
      children: balance.entries.map((entry) {
        final userId = entry.key;
        final amount = entry.value;
        final status = amount >= 0 ? 'Receives' : 'Owes';
        final userName = userMap[userId] ?? 'Unknown User';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            title: Text(userName),
            subtitle: Text('$status: ₹${amount.abs().toStringAsFixed(2)}'),
          ),
        );
      }).toList(),
    );
  }
}
