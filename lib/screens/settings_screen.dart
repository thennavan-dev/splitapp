import 'package:flutter/material.dart';
import 'package:splitapp/utils/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onDatabaseChanged;

  const SettingsScreen({super.key, this.onDatabaseChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final users = await dbHelper.getUsers();
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  Future<void> _confirmAndDeleteUser(int userId, String userName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete user'),
        content: Text(
          'Delete user "$userName"? This will remove associated participant entries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await dbHelper.deleteUser(userId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted user: $userName')));
      await _loadUsers();
      widget.onDatabaseChanged?.call();
    }
  }

  Future<void> _confirmAndClearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all data'),
        content: const Text(
          'Delete ALL data (users, splits, participants)? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await dbHelper.clearAllData();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All data cleared')));
      await _loadUsers();
      widget.onDatabaseChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _confirmAndClearAll,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Clear all data'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          const Text(
            'Users',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _users.isEmpty
                ? const Center(child: Text('No users'))
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final u = _users[index];
                      final id = u['id'] as int;
                      final name = u['user_name'] as String;
                      return Card(
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text('id: $id'),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _confirmAndDeleteUser(id, name),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
