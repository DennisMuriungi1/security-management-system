import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentDetailsDialog extends StatefulWidget {
  final String incidentId;
  final Map<String, dynamic> incidentData;
  final String userRole; // ✅ Required

  const IncidentDetailsDialog({
    super.key,
    required this.incidentId,
    required this.incidentData,
    required this.userRole, // ✅ Pass this when calling
  });

  @override
  State<IncidentDetailsDialog> createState() => _IncidentDetailsDialogState();
}

class _IncidentDetailsDialogState extends State<IncidentDetailsDialog> {
  final TextEditingController _commentController = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.incidentData['status'] ?? 'Pending';
  }

  /// ✅ Update status (Admins only)
  Future<void> _updateStatus(String newStatus) async {
    if (widget.userRole != "admin") return; 
    await FirebaseFirestore.instance
        .collection('incidents')
        .doc(widget.incidentId)
        .update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() => _status = newStatus);
  }

  /// ✅ Add a comment (Admins only)
  Future<void> _addComment(String message) async {
    if (widget.userRole != "admin") return; 
    if (message.isEmpty) return;

    final comment = {
      'author': widget.incidentData['reporter'] ?? 'Unknown',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('incidents')
        .doc(widget.incidentId)
        .update({
      'comments': FieldValue.arrayUnion([comment]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
    setState(() {
      final comments = widget.incidentData['comments'] as List<dynamic>? ?? [];
      comments.add(comment);
      widget.incidentData['comments'] = comments;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.incidentData;
    final attachments = data['attachments'] as List<dynamic>? ?? [];
    final comments = data['comments'] as List<dynamic>? ?? [];

    return AlertDialog(
      title: const Text('Incident Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${data['title'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Description: ${data['description'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Reporter: ${data['reporter'] ?? 'Unknown'} (${data['reporterRole'] ?? ''})'),
            const SizedBox(height: 8),
            Text('Location: ${data['location'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Severity: ${data['severity'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Assigned To: ${data['assignedTo'] ?? 'Unassigned'}'),
            const SizedBox(height: 8),
            Text(
              'Created At: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toLocal() : 'N/A'}',
            ),
            Text(
              'Updated At: ${data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate().toLocal() : 'N/A'}',
            ),
            const SizedBox(height: 8),

            // ✅ Status dropdown (Admins only)
            if (widget.userRole == "admin") 
              Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                      DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                    ],
                    onChanged: (val) {
                      if (val != null) _updateStatus(val);
                    },
                  ),
                ],
              )
            else
              Text("Status: $_status"), 

            const Divider(),
            const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (attachments.isEmpty) const Text('No attachments'),
            ...attachments.map((a) => Text(a.toString())),
            const Divider(),
            const Text('Comments:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (comments.isEmpty) const Text('No comments yet'),
            ...comments.map((c) {
              final time = (c['timestamp'] as Timestamp?)?.toDate().toLocal().toString() ?? '';
              return Text('${c['author']}: ${c['message']} ($time)');
            }),

            if (widget.userRole == "admin") ...[
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Add Comment',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _addComment(_commentController.text.trim()),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
