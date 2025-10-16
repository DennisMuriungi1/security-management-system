import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserStatistics extends StatelessWidget {
  final FirebaseFirestore firestore;
  const UserStatistics({super.key, required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final users = snapshot.data!.docs;
        final activeUsers = users.where((u) => u['isActive'] != false).length;
        final roleCounts = {
          'admin': users.where((u) => u['role'] == 'admin').length,
          'staff': users.where((u) => u['role'] == 'staff').length,
          'security': users.where((u) => u['role'] == 'security').length,
          'student': users.where((u) => u['role'] == 'student').length,
        };

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatCard("Total Users", users.length, Colors.blue),
              _buildStatCard("Active Users", activeUsers, Colors.green),
              _buildStatCard("Admins", roleCounts['admin']!, Colors.red),
              _buildStatCard("Staff", roleCounts['staff']!, Colors.orange),
              _buildStatCard("Security", roleCounts['security']!, Colors.purple),
              _buildStatCard("Students", roleCounts['student']!, Colors.teal),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(right: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(count.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
