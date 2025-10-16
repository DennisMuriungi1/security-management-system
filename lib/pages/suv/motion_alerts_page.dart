import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MotionAlertsPage extends StatelessWidget {
  const MotionAlertsPage({super.key});

  String _formatTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat("MMM dd, HH:mm").format(date);
    }
    return "Unknown time";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Motion Detection Alerts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("motion_alerts")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading alerts"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No motion alerts"));
          }

          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final camera = data["cameraId"] ?? "Unknown";
              final status = data["status"] ?? "Alert";
              final time = _formatTime(data["timestamp"]);

              return ListTile(
                leading: const Icon(Icons.motion_photos_on, color: Colors.red),
                title: Text("Camera: $camera"),
                subtitle: Text("$status\n$time"),
                isThreeLine: true,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
