import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_page.dart';

class DashboardHeader extends StatelessWidget {
  final String pageTitle;
  final Widget? trailing; // Optional trailing widget (like theme toggle)

  const DashboardHeader({
    super.key,
    required this.pageTitle,
    this.trailing,
  });

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page Title
          Text(
            pageTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2c3e50),
            ),
          ),

          // Right side: notifications + user info + logout + optional trailing
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.grey),
                onPressed: () {
                  // TODO: Navigate to Notifications Page
                },
              ),
              const SizedBox(width: 16),

              // User info
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF1a2a6c),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user?.email ?? "Guest",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Logout button
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                tooltip: "Logout",
                onPressed: () => _logout(context),
              ),

              // Optional trailing widget
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
