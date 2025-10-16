import 'package:flutter/material.dart';
import '../models/visitor_model.dart';

class VisitorCard extends StatelessWidget {
  final Visitor visitor;
  final String userRole;
  final VoidCallback onCheckOut;
  final VoidCallback onDelete;

  const VisitorCard({
    super.key,
    required this.visitor,
    required this.userRole,
    required this.onCheckOut,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: visitor.status == 'Checked In' ? Colors.green : Colors.grey,
          child: Text(
            visitor.name.isNotEmpty ? visitor.name[0] : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(visitor.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company: ${visitor.company}'),
            Text('Visiting: ${visitor.personToVisit}'),
            Text('Purpose: ${visitor.purpose}'),
            Text('Check-in: ${visitor.checkIn != null ? _formatTime(visitor.checkIn!) : "N/A"}'),
            if (visitor.checkOut != null)
              Text('Check-out: ${_formatTime(visitor.checkOut!)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (visitor.status == 'Checked In' && (userRole == 'admin' || userRole == 'security'))
              IconButton(
                onPressed: onCheckOut,
                icon: const Icon(Icons.logout, color: Colors.orange),
                tooltip: 'Check Out',
              ),
            if (userRole == 'admin')
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete',
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
