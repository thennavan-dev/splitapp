import 'package:flutter/material.dart';
import 'package:splitapp/utils/database_helper.dart';

Future<void> showAddSplitDialog(BuildContext context) async {
  final dbHelper = DatabaseHelper();
  final users = await dbHelper.getUsers();

  if (users.isEmpty) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('No Users Found'),
        content: const Text(
          'You need to add at least one user before creating a split.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  int? selectedUserId;

  try {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Split'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(titleController, 'Split Title'),
                const SizedBox(height: 10),
                _buildTextField(amountController, 'Amount', isNumber: true),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Created By',
                    border: OutlineInputBorder(),
                  ),
                  items: users
                      .map<DropdownMenuItem<int>>(
                        (user) => DropdownMenuItem<int>(
                          value: user['id'] as int,
                          child: Text(user['user_name']),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => selectedUserId = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final amountText = amountController.text.trim();

                if (title.isEmpty ||
                    amountText.isEmpty ||
                    selectedUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All fields are required')),
                  );
                  return;
                }

                final amount = double.tryParse(amountText);
                if (amount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid amount')),
                  );
                  return;
                }

                await dbHelper.insertSplit({
                  'split_title': title,
                  'amount': amount,
                  'created_by': selectedUserId,
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Split saved successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  } finally {
    titleController.dispose();
    amountController.dispose();
  }
}

Widget _buildTextField(
  TextEditingController controller,
  String label, {
  bool isNumber = false,
}) {
  return TextField(
    controller: controller,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );
}
