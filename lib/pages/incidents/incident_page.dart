import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'incident_details_dialog.dart';

class IncidentsPage extends StatelessWidget {
  final String userRole; // admin, staff, security, student

  const IncidentsPage({super.key, required this.userRole});

  // Add new incident
  Future<void> _addIncident(BuildContext context) async {
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _locationController = TextEditingController();

    String severity = "Low";
    String category = "General";
    DateTime? incidentDate;
    List<String> attachments = [];

    final picker = ImagePicker();

    // Pick date
    Future<void> pickDate() async {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (pickedDate != null) {
        incidentDate = pickedDate;
      }
    }

    // Pick file (photo or video)
    Future<void> pickFile() async {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File file = File(pickedFile.path);
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();

        try {
          final ref =
              FirebaseStorage.instance.ref().child("incident_files/$fileName");
          await ref.putFile(file);
          final downloadUrl = await ref.getDownloadURL();
          attachments.add(downloadUrl);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: $e")),
          );
        }
      }
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report New Incident"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: severity,
                decoration: const InputDecoration(
                  labelText: "Severity",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Low", child: Text("Low")),
                  DropdownMenuItem(value: "Medium", child: Text("Medium")),
                  DropdownMenuItem(value: "High", child: Text("High")),
                  DropdownMenuItem(value: "Critical", child: Text("Critical")),
                ],
                onChanged: (val) {
                  if (val != null) severity = val;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "General", child: Text("General")),
                  DropdownMenuItem(value: "Theft", child: Text("Theft")),
                  DropdownMenuItem(value: "Fire", child: Text("Fire")),
                  DropdownMenuItem(value: "Accident", child: Text("Accident")),
                  DropdownMenuItem(
                      value: "Suspicious", child: Text("Suspicious Activity")),
                ],
                onChanged: (val) {
                  if (val != null) category = val;
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: pickDate,
                child: const Text("Pick Incident Date"),
              ),
              if (incidentDate != null)
                Text("Selected: ${incidentDate!.toLocal()}".split(' ')[0]),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload Photo"),
              ),
              if (attachments.isNotEmpty)
                Column(
                  children: attachments
                      .map((a) => ListTile(
                            leading: const Icon(Icons.attach_file),
                            title: Text(a),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final description = _descriptionController.text.trim();
              final title = _titleController.text.trim();
              final location = _locationController.text.trim();

              if (title.isEmpty || description.isEmpty || location.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Please fill all required fields")),
                );
                return;
              }

              final user = FirebaseAuth.instance.currentUser;

              await FirebaseFirestore.instance.collection("incidents").add({
                "title": title,
                "description": description,
                "location": location,
                "severity": severity,
                "category": category,
                "incidentDate": incidentDate ?? DateTime.now(),
                "attachments": attachments,
                "reporter": user?.email ?? "Unknown",
                "reporterRole": userRole,
                "status": "Pending",
                "createdAt": FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Incident reported successfully")),
              );
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final incidentsQuery = (userRole == "admin")
        ? FirebaseFirestore.instance
            .collection("incidents")
            .orderBy("createdAt", descending: true)
        : FirebaseFirestore.instance
            .collection("incidents")
            .where("reporter", isEqualTo: user?.email ?? "")
            .orderBy("createdAt", descending: true);

    return Scaffold(
      // ✅ Removed AppBar
      floatingActionButton: (userRole != "admin")
          ? FloatingActionButton(
              onPressed: () => _addIncident(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: incidentsQuery.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final incidents = snapshot.data!.docs;

            if (incidents.isEmpty) {
              return const Center(child: Text("No incidents reported yet."));
            }

            return ListView(
              children: incidents.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      child: const Icon(Icons.warning, color: Colors.redAccent),
                    ),
                    title: Text(
                      data["title"] ?? "No title",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Description: ${data["description"] ?? "N/A"}"),
                        Text("Location: ${data["location"] ?? "N/A"}"),
                        Text("Severity: ${data["severity"] ?? "N/A"}"),
                        Text("Category: ${data["category"] ?? "N/A"}"),
                        Text(
                          "Status: ${data["status"] ?? "Pending"}",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.blue),
                        ),
                        Text(
                          "Reported by: ${data["reporter"] ?? "Unknown"} (${data["reporterRole"] ?? ""})",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (userRole == "admin") {
                        showDialog(
                          context: context,
                          builder: (context) => IncidentDetailsDialog(
                            incidentId: doc.id,
                            incidentData: data,
                            userRole: userRole, // ✅ FIXED
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
