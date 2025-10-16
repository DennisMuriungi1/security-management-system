import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/dashboard_header.dart';
import '../utils/sidebar_items_generator.dart';
import '../utils/page_content_builder.dart';

class DashboardPage extends StatefulWidget {
  final String userRole;

  const DashboardPage({super.key, required this.userRole});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedPage = "dashboard";
  bool isSidebarCollapsed = false;

  // Example badge counts (replace with real data)
  Map<String, int> badgeCounts = {
    "incidents": 3,
    "visitors": 5,
    "notifications": 7,
  };

  // Quick action config
  final List<Map<String, dynamic>> quickActions = [
    {'icon': Icons.warning, 'label': 'Incidents', 'color': Colors.red, 'page': 'incidents'},
    {'icon': Icons.people, 'label': 'Visitors', 'color': Colors.green, 'page': 'visitors'},
    {'icon': Icons.notifications, 'label': 'Notifications', 'color': Colors.blue, 'page': 'notifications'},
    {'icon': Icons.bar_chart, 'label': 'Analytics', 'color': Colors.orange, 'page': 'analytics'},
    {'icon': Icons.videocam, 'label': 'Surveillance', 'color': Colors.purple, 'page': 'surveillance'},
    {'icon': Icons.manage_accounts, 'label': 'Users', 'color': Colors.teal, 'page': 'users'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 800;

          return Row(
            children: [
              // Sidebar
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSmallScreen
                    ? isSidebarCollapsed
                        ? 0
                        : 200
                    : isSidebarCollapsed
                        ? 70
                        : 250,
                child: Sidebar(
                  items: SidebarItemsGenerator.generateItems(
                    selectedPage: selectedPage,
                    userRole: widget.userRole,
                    isCollapsed: isSidebarCollapsed,
                    onPageChange: (page) => setState(() => selectedPage = page),
                  ),
                  isCollapsed: isSidebarCollapsed,
                  onToggleCollapse: () =>
                      setState(() => isSidebarCollapsed = !isSidebarCollapsed),
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  color: isDark ? Colors.grey[900] : const Color(0xFFF5F7FA),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      DashboardHeader(
                        pageTitle: PageContentBuilder.getPageTitle(selectedPage),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Theme toggle
                            IconButton(
                              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                              onPressed: () {
                                // Implement theme toggle logic
                              },
                            ),

                            // Profile Avatar & Menu
                            PopupMenuButton<String>(
                              icon: const CircleAvatar(child: Icon(Icons.person)),
                              onSelected: (value) {
                                if (value == 'logout') {
                                  // handle logout
                                } else if (value == 'settings') {
                                  // handle settings
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'settings', child: Text('Settings')),
                                PopupMenuItem(value: 'logout', child: Text('Logout')),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Quick Action Buttons (only for Dashboard)
                      if (selectedPage == "dashboard") ...[
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: quickActions.map((action) {
                            int badge = badgeCounts[action['page']] ?? 0;
                            return _quickActionButton(
                              icon: action['icon'],
                              label: action['label'],
                              color: action['color'],
                              badgeCount: badge,
                              onTap: () => setState(() => selectedPage = action['page']),
                            );
                          }).toList(),
                        ),
                        const Divider(height: 30),
                      ],

                      // Page Content with loading placeholder
                      Expanded(
                        child: _buildPageContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageContent() {
    // For now just directly returning the page content
    // You can replace with FutureBuilder if content is async
    return PageContentBuilder.buildPageContent(selectedPage, widget.userRole);
  }

  /// 🔹 Quick Action Button with optional badge
  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(icon, size: 20),
          label: Text(label),
          onPressed: onTap,
        ),
        if (badgeCount > 0)
          Positioned(
            top: -5,
            right: -5,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.red,
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
