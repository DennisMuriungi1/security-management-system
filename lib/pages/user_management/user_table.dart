import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/role_badge.dart';
import 'add_edit_user_dialog.dart';

class UserTable extends StatefulWidget {
  final FirebaseFirestore firestore;
  final String filterRole;
  final bool showActiveOnly;
  final bool showRecentOnly;
  final String searchQuery;
  final int currentPage;
  final int itemsPerPage;
  final Set<String> selectedUsers;
  final void Function(Set<String>) onSelectionChanged;

  const UserTable({
    super.key,
    required this.firestore,
    required this.filterRole,
    required this.showActiveOnly,
    required this.showRecentOnly,
    required this.searchQuery,
    required this.currentPage,
    required this.itemsPerPage,
    required this.selectedUsers,
    required this.onSelectionChanged,
  });

  @override
  State<UserTable> createState() => _UserTableState();
}

class _UserTableState extends State<UserTable> {
  @override
  Widget build(BuildContext context) {
    Query usersQuery = widget.firestore.collection('users');

    if (widget.filterRole != "all") {
      usersQuery = usersQuery.where('role', isEqualTo: widget.filterRole);
    }
    if (widget.showActiveOnly) {
      usersQuery = usersQuery.where('isActive', isEqualTo: true);
    }
    if (widget.showRecentOnly) {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      usersQuery = usersQuery.where('createdAt', isGreaterThan: weekAgo);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: usersQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        var users = snapshot.data!.docs;

        // Sort by creation date safely
        users.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aDate = aData['createdAt'] is Timestamp ? aData['createdAt'] as Timestamp : null;
          final bDate = bData['createdAt'] is Timestamp ? bData['createdAt'] as Timestamp : null;

          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

        // Search filter
        if (widget.searchQuery.isNotEmpty) {
          users = users.where((user) {
            final userData = user.data() as Map<String, dynamic>;
            final query = widget.searchQuery.toLowerCase();
            return userData.values
                .any((value) => value != null && value.toString().toLowerCase().contains(query));
          }).toList();
        }

        final startIndex = (widget.currentPage - 1) * widget.itemsPerPage;
        final endIndex = (startIndex + widget.itemsPerPage).clamp(0, users.length);
        final paginatedUsers = users.sublist(startIndex.clamp(0, users.length), endIndex);

        // Dynamically get all keys for the table header
        final allKeys = <String>{};
        for (var user in paginatedUsers) {
          final data = user.data() as Map<String, dynamic>;
          allKeys.addAll(data.keys);
        }
        final columns = allKeys.toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFF1a2a6c)),
            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            columns: [
              ...columns.map((key) => DataColumn(label: Text(key))),
              const DataColumn(label: Text("Actions")),
            ],
            rows: paginatedUsers.map((user) {
              final userData = user.data() as Map<String, dynamic>;

              return DataRow(
                selected: widget.selectedUsers.contains(user.id),
                onSelectChanged: (selected) {
                  final newSelected = Set<String>.from(widget.selectedUsers);
                  if (selected == true) {
                    newSelected.add(user.id);
                  } else {
                    newSelected.remove(user.id);
                  }
                  widget.onSelectionChanged(newSelected);
                },
                cells: [
                  ...columns.map((key) {
                    final value = userData[key];
                    if (key == "role") {
                      return DataCell(RoleBadge(role: value ?? "No Role"));
                    } else if (key == "isActive") {
                      return DataCell(Switch(
                        value: value ?? true,
                        onChanged: (val) async {
                          await widget.firestore.collection('users').doc(user.id).update({
                            'isActive': val,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                          if (mounted) setState(() {});
                        },
                      ));
                    } else if (value is Timestamp) {
                      return DataCell(Text(value.toDate().toString()));
                    } else {
                      return DataCell(Text(value?.toString() ?? ""));
                    }
                  }),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => AddEditUserDialog(userId: user.id, userData: userData),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
