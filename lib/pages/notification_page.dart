import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatelessWidget {
  final String userRole; // 👈 passed from login

  const NotificationsPage({super.key, required this.userRole});

  bool get canSendNotification =>
      userRole == "admin" || userRole == "security" || userRole == "staff";

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where("role", whereIn: [userRole, "all"])
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No notifications available"),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final readBy = List<String>.from(data["readBy"] ?? []);
              final isRead = readBy.contains(userId);

              return _NotificationItem(
                icon: Icons.notifications,
                title: data["title"] ?? "No Title",
                message: data["message"] ?? "No Message",
                color: isRead ? Colors.grey : const Color(0xFF1a2a6c),
                docId: doc.id,
                userId: userId,
              );
            },
          );
        },
      ),

      // ✅ Only admins, staff, and security can send notifications
      floatingActionButton: canSendNotification
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF1a2a6c),
              child: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => SendNotificationDialog(senderRole: userRole),
                );
              },
            )
          : null,
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final String docId;
  final String userId;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.docId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // ✅ Mark notification as read
        await FirebaseFirestore.instance
            .collection("notifications")
            .doc(docId)
            .update({
          "readBy": FieldValue.arrayUnion([userId])
        });

        // Optional: Show details
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SendNotificationDialog extends StatefulWidget {
  final String senderRole;

  const SendNotificationDialog({super.key, required this.senderRole});

  @override
  State<SendNotificationDialog> createState() => _SendNotificationDialogState();
}

class _SendNotificationDialogState extends State<SendNotificationDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String selectedRole = "all"; // Default: broadcast to everyone

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Send Notification"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: "Message"),
              maxLines: 3,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: const [
                DropdownMenuItem(value: "all", child: Text("All Users")),
                DropdownMenuItem(value: "admin", child: Text("Admins")),
                DropdownMenuItem(value: "security", child: Text("Security")),
                DropdownMenuItem(value: "staff", child: Text("Staff")),
                DropdownMenuItem(value: "student", child: Text("Students")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
              decoration: const InputDecoration(labelText: "Target Role"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1a2a6c),
          ),
          child: const Text("Send"),
          onPressed: () async {
            if (_titleController.text.trim().isEmpty ||
                _messageController.text.trim().isEmpty) return;

            await FirebaseFirestore.instance.collection("notifications").add({
              "title": _titleController.text.trim(),
              "message": _messageController.text.trim(),
              "role": selectedRole,
              "senderRole": widget.senderRole,
              "timestamp": FieldValue.serverTimestamp(),
              "readBy": [], // 👈 track who read this
            });

            Navigator.pop(context); // Close dialog
          },
        ),
      ],
    );
  }
}
