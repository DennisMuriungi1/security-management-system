import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_table.dart';
import 'user_filters.dart';
import 'user_statistics.dart';
import 'add_edit_user_dialog.dart';
import 'bulk_actions.dart';

class UserManagementPage extends StatefulWidget {
  final String userRole;
  const UserManagementPage({super.key, required this.userRole});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String filterRole = "all";
  String searchQuery = "";
  bool showActiveOnly = true;
  bool showRecentOnly = false;
  Set<String> selectedUsers = {};
  int currentPage = 1;
  final int itemsPerPage = 10;

  final firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF5F7FA),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            UserFilters(
              filterRole: filterRole,
              showActiveOnly: showActiveOnly,
              showRecentOnly: showRecentOnly,
              onFilterChange: (role, activeOnly, recentOnly) {
                setState(() {
                  filterRole = role;
                  showActiveOnly = activeOnly;
                  showRecentOnly = recentOnly;
                });
              },
              onSearchChanged: (query) => setState(() => searchQuery = query),
            ),
            const SizedBox(height: 20),
            UserStatistics(firestore: firestore),
            const SizedBox(height: 20),
            Expanded(
              child: UserTable(
                firestore: firestore,
                filterRole: filterRole,
                showActiveOnly: showActiveOnly,
                showRecentOnly: showRecentOnly,
                searchQuery: searchQuery,
                currentPage: currentPage,
                itemsPerPage: itemsPerPage,
                selectedUsers: selectedUsers,
                onSelectionChanged: (newSelected) =>
                    setState(() => selectedUsers = newSelected),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.userRole == "admin"
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const AddEditUserDialog(),
              ),
            )
          : null,
      bottomNavigationBar:
          selectedUsers.isNotEmpty ? BulkActions(selectedUsers: selectedUsers) : null,
    );
  }
}
