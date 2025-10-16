// visitors_management.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visitor_model.dart';
import '../widgets/visitor_card.dart';
import '../widgets/add_visitor_dialog.dart';

class VisitorsManagementPage extends StatefulWidget {
  final String userRole;

  const VisitorsManagementPage({Key? key, required this.userRole}) : super(key: key);

  @override
  State<VisitorsManagementPage> createState() => _VisitorsManagementPageState();
}

class _VisitorsManagementPageState extends State<VisitorsManagementPage> {
  String filterStatus = 'All';
  String searchQuery = '';

  Future<void> _showAddVisitorDialog() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AddVisitorDialog(addedBy: widget.userRole),
    );

    if (added == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visitor added successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _checkOutVisitor(String visitorId) async {
    try {
      await FirebaseFirestore.instance.collection('visitors').doc(visitorId).update({
        'checkOut': Timestamp.fromDate(DateTime.now()),
        'status': 'Checked Out',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visitor checked out successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to check out: $e')));
    }
  }

  Future<void> _deleteVisitor(String visitorId) async {
    if (widget.userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only admins can delete visitors')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Visitor'),
        content: const Text('Are you sure you want to delete this visitor record?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('visitors').doc(visitorId).delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visitor deleted successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Add button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Visitor Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                if (widget.userRole == 'admin' || widget.userRole == 'security')
                  ElevatedButton.icon(
                    onPressed: _showAddVisitorDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Visitor'),
                  ),
              ],
            ),
          ),

          // Filters & Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: filterStatus,
                    items: ['All', 'Checked In', 'Checked Out', 'Expected']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      filterStatus = v ?? 'All';
                    }),
                    decoration: const InputDecoration(labelText: 'Filter by Status', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: TextField(
                    onChanged: (v) => setState(() => searchQuery = v.trim()),
                    decoration: const InputDecoration(
                      labelText: 'Search visitors...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List (live)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('visitors').orderBy('checkIn', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;

                  // compute stats
                  final totalToday = docs.length;
                  final checkedInCount = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'Checked In').length;
                  final expectedCount = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'Expected').length;

                  // filter & search
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final matchesStatus = filterStatus == 'All' || (data['status'] ?? '') == filterStatus;
                    final matchesSearch = searchQuery.isEmpty ||
                        (data['name'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                        (data['company'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                        (data['personToVisit'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase());
                    return matchesStatus && matchesSearch;
                  }).toList();

                  return Column(
                    children: [
                      // Stats row with actual values
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            _buildStatCard('Total Today', totalToday.toString(), Icons.people),
                            const SizedBox(width: 10),
                            _buildStatCard('Checked In', checkedInCount.toString(), Icons.login, color: Colors.green),
                            const SizedBox(width: 10),
                            _buildStatCard('Expected', expectedCount.toString(), Icons.schedule, color: Colors.orange),
                          ],
                        ),
                      ),

                      Expanded(
                        child: filteredDocs.isEmpty
                            ? const Center(child: Text('No visitors found'))
                            : ListView.builder(
                                itemCount: filteredDocs.length,
                                itemBuilder: (context, i) {
                                  final doc = filteredDocs[i];
                                  // use factory to safely parse fields
                                  final visitor = Visitor.fromDocument(doc);

                                  return VisitorCard(
                                    visitor: visitor,
                                    userRole: widget.userRole,
                                    onCheckOut: () => _checkOutVisitor(visitor.id),
                                    onDelete: () => _deleteVisitor(visitor.id),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {Color color = Colors.blue}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                Icon(icon, color: color),
              ]),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
