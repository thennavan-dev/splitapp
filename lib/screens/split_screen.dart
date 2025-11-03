import 'package:flutter/material.dart';
import 'package:splitapp/utils/database_helper.dart';

class SplitScreen extends StatefulWidget {
  final Map<String, dynamic> split;

  const SplitScreen({super.key, required this.split});

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> participants = [];
  List<Map<String, dynamic>> allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadParticipants();
    _loadAllUsers();
  }

  Future<void> _loadParticipants() async {
    final list = await dbHelper.getParticipants(widget.split['id']);
    setState(() {
      participants = list;
    });
  }

  Future<void> _loadAllUsers() async {
    final users = await dbHelper.getUsers();
    setState(() {
      allUsers = users;
    });
  }

  Future<void> _addParticipant(int userId) async {
    await dbHelper.addParticipant(widget.split['id'], userId);
    _loadParticipants();
  }

  Future<void> _removeParticipant(int userId) async {
    await dbHelper.removeParticipant(widget.split['id'], userId);
    _loadParticipants();
  }

  void _showAddParticipantDialog() {
    showDialog(
      context: context,
      builder: (_) {
        final availableUsers = allUsers
            .where(
              (u) =>
                  u['id'] != widget.split['created_by'] &&
                  !participants.any((p) => p['id'] == u['id']),
            )
            .toList();
        return AlertDialog(
          title: const Text('Add Participant'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableUsers.length,
              itemBuilder: (context, index) {
                final user = availableUsers[index];
                return ListTile(
                  title: Text(user['user_name']),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _addParticipant(user['id']);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.split['split_title']),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete split',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.split['split_title'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  "Created By: ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                Text(
                  widget.split['created_by_name'],
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  "Amount: ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                Text(
                  '₹${widget.split['amount']}',
                  style: const TextStyle(fontSize: 18, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Users:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: _showAddParticipantDialog,
                ),
              ],
            ),
            Expanded(
              child: participants.isEmpty
                  ? const Center(child: Text('No users yet.'))
                  : ListView.builder(
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final user = participants[index];
                        final numAmount = (widget.split['amount'] as num)
                            .toDouble();
                        final perPerson = participants.isNotEmpty
                            ? numAmount / (participants.length + 1)
                            : 0.0;

                        return ListTile(
                          title: Text(user['user_name']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${perPerson.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeParticipant(user['id']),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Split'),
        content: const Text(
          'Are you sure you want to delete this split? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await dbHelper.deleteSplit(widget.split['id']);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }
}
