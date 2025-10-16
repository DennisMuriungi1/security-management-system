import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BulkActions extends StatelessWidget {
  final Set<String> selectedUsers;
  const BulkActions({super.key, required this.selectedUsers});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    Future<void> _updateStatus(bool isActive) async {
      for (final id in selectedUsers) {
        await firestore.collection('users').doc(id).update({
          'isActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${selectedUsers.length} users updated")),
      );
    }

    Future<void> _deleteUsers() async {
      for (final id in selectedUsers) {
        await firestore.collection('users').doc(id).delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${selectedUsers.length} users deleted")),
      );
    }

    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Text("${selectedUsers.length} selected"),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Activate"),
              onPressed: () => _updateStatus(true),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.block),
              label: const Text("Deactivate"),
              onPressed: () => _updateStatus(false),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text("Delete"),
              onPressed: _deleteUsers,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
