import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

import '../pages/user_management/user_management_page.dart';
import '../pages/incidents/incident_page.dart'; 
import '../pages/notification_page.dart';
import '../pages/visitors_management.dart';
import '../pages/surveillance_page.dart';

import '../pages/analytics.dart';
import '../widgets/stat_card.dart';

class PageContentBuilder {
  static String getPageTitle(String page) {
    switch (page) {
      case "dashboard":
        return "Security Dashboard";
      case "users":
        return "User Management";
      case "incidents":
        return "Incident Management";
      case "visitors":
        return "Visitor Management";
      case "notifications":
        return "Notifications";
      case "analytics":
        return "Analytics";
      case "surveillance":
        return "surveillance";
      default:
        return page[0].toUpperCase() + page.substring(1);
    }
  }

  static Widget buildPageContent(String page, String userRole) {
    switch (page) {
      case "dashboard":
        return _buildDashboardContent(userRole);

      case "surveillance":
  return SurveillancePage(userRole: userRole);



      case "users":
        return UserManagementPage(userRole: userRole);

      case "incidents":
        return IncidentsPage(userRole: userRole); 

      case "visitors":
        return VisitorsManagementPage(userRole: userRole);

      case "analytics":
        return AnalyticsPage();

      case "notifications":
        return NotificationsPage(userRole: userRole);

      default:
        return _buildDefaultContent();
    }
  }

  
  static Widget _buildDashboardContent(String userRole) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Security Dashboard",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),

          // 🔹 Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              // 🔴 Incidents
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("incidents")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _errorStat("Incidents", Icons.error, Colors.red);
                  }
                  if (!snapshot.hasData) {
                    return _loadingStat("Incidents", Icons.error, Colors.red);
                  }

                  int count = snapshot.data!.docs.length;
                  return StatCard(
                    title: "Incidents",
                    value: "$count",
                    icon: Icons.warning,
                    color: Colors.red,
                  );
                },
              ),

              // 🟢 Visitors
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("visitors")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _errorStat("Visitors", Icons.people, Colors.green);
                  }
                  if (!snapshot.hasData) {
                    return _loadingStat("Visitors", Icons.people, Colors.green);
                  }

                  int count = snapshot.data!.docs.length;
                  return StatCard(
                    title: "Visitors",
                    value: "$count",
                    icon: Icons.people,
                    color: Colors.green,
                  );
                },
              ),

              // 🔵 Notifications
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("notifications")
                    .where("isRead", isEqualTo: false) // ✅ only unread
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _errorStat(
                        "Notifications", Icons.notifications, Colors.blue);
                  }
                  if (!snapshot.hasData) {
                    return _loadingStat(
                        "Notifications", Icons.notifications, Colors.blue);
                  }

                  // ✅ Filter by role manually to avoid Firestore index errors
                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data["role"] == userRole || data["role"] == "all";
                  }).toList();

                  return StatCard(
                    title: "Notifications",
                    value: "${docs.length}",
                    icon: Icons.notifications,
                    color: Colors.blue,
                  );
                },
              ),

              // 🟠 Cameras (static for now)
              StatCard(
                title: "Cameras Online",
                value: "15",
                icon: Icons.videocam,
                color: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 30),

          // 🔹 Recent Activity Section
          _buildRecentActivitySection(userRole),
        ],
      ),
    );
  }

  // 🔹 Reusable loading/error stat cards
  static Widget _loadingStat(String title, IconData icon, Color color) {
    return StatCard(title: title, value: "Loading...", icon: icon, color: color);
  }

  static Widget _errorStat(String title, IconData icon, Color color) {
    return StatCard(title: title, value: "Error", icon: icon, color: color);
  }

  // 🔹 Recent Activity Section
  static Widget _buildRecentActivitySection(String userRole) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recent Activity",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("recent_activity")
                  .orderBy("timestamp", descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error loading recent activity'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: _getActivityIcon(data['type'] ?? 'general'),
                      title: Text(data['title'] ?? 'Activity'),
                      subtitle: Text(
                        _formatTimestamp(data['timestamp']),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: _getStatusChip(data['status']),
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Format timestamp
  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${DateFormat('MMM dd').format(date)} at ${DateFormat('HH:mm').format(date)}';
    }
    return 'Unknown time';
  }

  // 🔹 Get activity icon
  static Icon _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case "incident":
        return const Icon(Icons.warning, color: Colors.orange, size: 20);
      case "visitor":
        return const Icon(Icons.person, color: Colors.green, size: 20);
      case "notification":
        return const Icon(Icons.notifications, color: Colors.blue, size: 20);
      default:
        return const Icon(Icons.info, color: Colors.grey, size: 20);
    }
  }

  // 🔹 Get status chip
  static Widget _getStatusChip(String? status) {
    if (status == null) return const SizedBox();

    Color color = Colors.grey;
    switch (status.toLowerCase()) {
      case "resolved":
        color = Colors.green;
        break;
      case "critical":
        color = Colors.red;
        break;
      case "in progress":
        color = Colors.orange;
        break;
      case "new":
        color = Colors.blue;
        break;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  // 🔹 Default content for unknown pages
  static Widget _buildDefaultContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Page Not Found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
