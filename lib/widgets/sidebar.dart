import 'package:flutter/material.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });
}

class Sidebar extends StatelessWidget {
  final List<SidebarItem> items;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const Sidebar({
    super.key,
    required this.items,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 800;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSmallScreen
          ? (isCollapsed ? 70 : 200)
          : (isCollapsed ? 80 : 250),
      color: const Color(0xFF2c3e50),
      child: Column(
        children: [
          const SizedBox(height: 30),
          if (!isCollapsed)
            Column(
              children: const [
                Icon(Icons.shield, color: Colors.white, size: 60),
                SizedBox(height: 10),
                Text(
                  "DeKUT Security",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            const Icon(Icons.shield, color: Colors.white, size: 40),
          const SizedBox(height: 30),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: items.map((item) => _buildSidebarItem(item)).toList(),
              ),
            ),
          ),

          IconButton(
            icon: Icon(
              isCollapsed ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: Colors.white,
            ),
            onPressed: onToggleCollapse,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(SidebarItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: item.isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(item.icon, color: Colors.white),
        title: !item.isCollapsed
            ? Text(
                item.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: item.isActive ? FontWeight.bold : FontWeight.normal,
                ),
              )
            : null,
        onTap: item.onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}