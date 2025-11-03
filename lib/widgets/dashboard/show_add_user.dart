import 'package:flutter/material.dart';
import 'package:splitapp/utils/database_helper.dart';

Future<void> showAddUserDialog(BuildContext context) async {
  final TextEditingController userController = TextEditingController();
  final dbHelper = DatabaseHelper();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Add User'),
        content: TextField(
          controller: userController,
          decoration: const InputDecoration(
            labelText: 'User Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userName = userController.text.trim();
              if (userName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User name cannot be empty')),
                );
                return;
              }

              await dbHelper.insertUser({'user_name': userName});
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User added successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
