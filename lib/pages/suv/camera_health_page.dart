import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CameraHealthPage extends StatelessWidget {
  const CameraHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camera Health")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("cameras").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading health data"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No camera health data"));
          }

          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data["name"] ?? "Camera";
              final health = data["health"] ?? "unknown";

              return ListTile(
                leading: const Icon(Icons.health_and_safety),
                title: Text(name),
                subtitle: Text("Health: $health"),
                trailing: Icon(
                  Icons.circle,
                  color: health == "good" ? Colors.green : Colors.red,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
