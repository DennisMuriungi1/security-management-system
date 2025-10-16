import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';

class SidebarItemsGenerator {
  static List<SidebarItem> generateItems({
    required String selectedPage,
    required String userRole,
    required bool isCollapsed,
    required Function(String) onPageChange,
  }) {
    final List<SidebarItem> items = [];

    // ✅ Dashboard (Admin only, but you can open to all if needed)
    if (userRole == "admin") {
      items.add(
        SidebarItem(
          icon: Icons.home,
          label: "Dashboard",
          isActive: selectedPage == "dashboard",
          isCollapsed: isCollapsed,
          onTap: () => onPageChange("dashboard"),
        ),
      );
    }

    // ✅ Surveillance (Admin & Security)
    if (userRole == "security" || userRole == "admin") {
      items.add(
        SidebarItem(
          icon: Icons.videocam, // 👈 better icon
          label: "Surveillance",
          isActive: selectedPage == "surveillance",
          isCollapsed: isCollapsed,
          onTap: () => onPageChange("surveillance"),
        ),
      );
    }

    // ✅ Admin-only: Manage Users
    if (userRole == "admin") {
      items.add(
        SidebarItem(
          icon: Icons.person_add,
          label: "Users",
          isActive: selectedPage == "users",
          isCollapsed: isCollapsed,
          onTap: () => onPageChange("users"),
        ),
      );
    }

    // ✅ Visitor Management (Admin & Security)
    if (userRole == "security" || userRole == "admin") {
      items.add(
        SidebarItem(
          icon: Icons.people,
          label: "Visitor Management",
          isActive: selectedPage == "visitors",
          isCollapsed: isCollapsed,
          onTap: () => onPageChange("visitors"),
        ),
      );
    }

    // ✅ Everyone: Incidents
    items.add(
      SidebarItem(
        icon: Icons.error,
        label: "Incidents",
        isActive: selectedPage == "incidents",
        isCollapsed: isCollapsed,
        onTap: () => onPageChange("incidents"),
      ),
    );

    // ✅ Everyone: Notifications
    items.add(
      SidebarItem(
        icon: Icons.notifications,
        label: "Notifications",
        isActive: selectedPage == "notifications",
        isCollapsed: isCollapsed,
        onTap: () => onPageChange("notifications"),
      ),
    );

    // ✅ Admin-only: Analytics
    if (userRole == "admin") {
      items.add(
        SidebarItem(
          icon: Icons.analytics,
          label: "Analytics",
          isActive: selectedPage == "analytics",
          isCollapsed: isCollapsed,
          onTap: () => onPageChange("analytics"),
        ),
      );
    }

    return items;
  }
}
