import 'package:flutter/material.dart';
import 'package:splitapp/utils/database_helper.dart';
import 'package:splitapp/widgets/show_add_split.dart';
import 'package:splitapp/widgets/show_add_user.dart';
import 'package:splitapp/widgets/show_split.dart';
import 'package:splitapp/screens/split_screen.dart';
import 'package:splitapp/screens/user_screen.dart';
import 'package:splitapp/widgets/bottom_nav_widget.dart';

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

    _users = users; // store users for UserScreen

    final userMap = {for (var u in users) u['id']: u['user_name']};

    final splitsWithUser = splits.map((split) {
      final userId = split['created_by'];
      return {
        ...split,
        'created_by_name': userMap[userId] ?? 'Unknown User',
      };
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
    // Local variable should not start with underscore
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
      UserScreen(
        splits: _splits,
        users: _users, // ✅ pass users here
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Split App"),
        centerTitle: true,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Split',
              onPressed: _showAddSplit,
            ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add User',
            onPressed: _showAddUser,
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavWidget(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
