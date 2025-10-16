import 'package:flutter/material.dart';

class UserFilters extends StatefulWidget {
  final String filterRole;
  final bool showActiveOnly;
  final bool showRecentOnly;
  final void Function(String role, bool activeOnly, bool recentOnly) onFilterChange;
  final void Function(String) onSearchChanged;

  const UserFilters({
    super.key,
    required this.filterRole,
    required this.showActiveOnly,
    required this.showRecentOnly,
    required this.onFilterChange,
    required this.onSearchChanged,
  });

  @override
  State<UserFilters> createState() => _UserFiltersState();
}

class _UserFiltersState extends State<UserFilters> {
  late TextEditingController _searchController;
  late String _selectedRole;
  late bool _activeOnly;
  late bool _recentOnly;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.filterRole;
    _activeOnly = widget.showActiveOnly;
    _recentOnly = widget.showRecentOnly;
    _searchController = TextEditingController();
    _searchController.addListener(() {
      widget.onSearchChanged(_searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilters() {
    widget.onFilterChange(_selectedRole, _activeOnly, _recentOnly);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search users by email or name...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Filters:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(value: "all", child: Text("All Users")),
                    DropdownMenuItem(value: "admin", child: Text("Admin")),
                    DropdownMenuItem(value: "staff", child: Text("Staff")),
                    DropdownMenuItem(value: "security", child: Text("Security")),
                    DropdownMenuItem(value: "student", child: Text("Student")),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRole = value;
                      });
                      _updateFilters();
                    }
                  },
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text("Active Only"),
                  selected: _activeOnly,
                  onSelected: (val) {
                    setState(() => _activeOnly = val);
                    _updateFilters();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text("Recent Only"),
                  selected: _recentOnly,
                  onSelected: (val) {
                    setState(() => _recentOnly = val);
                    _updateFilters();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
