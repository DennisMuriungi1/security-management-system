import 'package:flutter/material.dart';
import 'suv/live_camera_page.dart';
import 'suv/camera_health_page.dart';
import 'suv/ptz_controls_page.dart';
import 'suv/video_playback_page.dart';
import 'suv/motion_alerts_page.dart';

class SurveillancePage extends StatelessWidget {
  final String userRole;

  const SurveillancePage({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Removed the AppBar
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(
            context,
            icon: Icons.videocam,
            title: "Live Camera Feeds",
            description: "Real-time video monitoring",
            page: const LiveCameraPage(),
          ),
          _buildCard(
            context,
            icon: Icons.health_and_safety,
            title: "Camera Health",
            description: "Status of all cameras",
            page: const CameraHealthPage(),
          ),
          _buildCard(
            context,
            icon: Icons.screen_rotation,
            title: "PTZ Controls",
            description: "Pan-Tilt-Zoom for cameras",
            page: const PTZControlsPage(),
          ),
          _buildCard(
            context,
            icon: Icons.play_circle,
            title: "Video Playback",
            description: "Historical footage review",
            page: const VideoPlaybackPage(),
          ),
          _buildCard(
            context,
            icon: Icons.motion_photos_on,
            title: "Motion Detection Alerts",
            description: "Automated notifications",
            page: const MotionAlertsPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Widget page,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.blueGrey[800]),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
