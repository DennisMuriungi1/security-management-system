// lib/pages/suv/live_camera_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

class LiveCameraPage extends StatefulWidget {
  const LiveCameraPage({super.key});

  @override
  State<LiveCameraPage> createState() => _LiveCameraPageState();
}

class _LiveCameraPageState extends State<LiveCameraPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  
  String _searchQuery = '';
  ViewMode _viewMode = ViewMode.grid;
  String? _selectedCameraId;

  @override
  void initState() {
    super.initState();
    _setupMotionAlerts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _setupMotionAlerts() {
    FirebaseFirestore.instance
        .collection('alerts')
        .where('timestamp', isGreaterThan: Timestamp.now())
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          _showMotionAlert(doc.doc.data()! as Map<String, dynamic>, doc.doc.id);
        }
      }
    });
  }

  void _showMotionAlert(Map<String, dynamic> alert, String alertId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Motion Detected!'),
        content: Text('Camera: ${alert['cameraName'] ?? 'Unknown'}'),
        actions: [
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('alerts').doc(alertId).update({'dismissed': true});
              Navigator.pop(context);
            },
            child: const Text('Dismiss'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCameraId = alert['cameraId'];
                _viewMode = ViewMode.single;
              });
              Navigator.pop(context);
            },
            child: const Text('View Live'),
          ),
        ],
      ),
    );
  }

  // Camera controls
  void _zoomCamera(String cameraId, String direction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Zoom ${direction} for camera $cameraId')),
    );
  }

  void _rotateCamera(String cameraId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rotating camera $cameraId')),
    );
  }

  void _takeScreenshot(String cameraId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Screenshot saved to gallery')),
    );
  }

  void _startRecording(String cameraId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recording started')),
    );
  }

  void _changeViewMode(ViewMode mode) {
    setState(() {
      _viewMode = mode;
    });
  }

  void _enterFullScreenMode(String cameraId) {
    setState(() {
      _selectedCameraId = cameraId;
      _viewMode = ViewMode.single;
    });
  }

  void _exitFullScreenMode() {
    setState(() {
      _selectedCameraId = null;
      _viewMode = ViewMode.grid;
    });
  }

  void _filterCameras(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<QueryDocumentSnapshot> _getFilteredCameras(List<QueryDocumentSnapshot> cameras) {
    if (_searchQuery.isEmpty) return cameras;
    return cameras.where((camera) {
      final data = camera.data() as Map<String, dynamic>;
      final name = data['name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildCameraHealth(Map<String, dynamic> data) {
    final health = data['health'] ?? 'unknown';
    final uptime = data['uptime'] ?? 0;
    final lastActive = data['lastActive'] as Timestamp?;

    Color healthColor = Colors.grey;
    switch (health) {
      case 'good': healthColor = Colors.green; break;
      case 'warning': healthColor = Colors.orange; break;
      case 'critical': healthColor = Colors.red; break;
      default: healthColor = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 8, color: healthColor),
            const SizedBox(width: 4),
            Text('Health: ${health.toUpperCase()}',
                style: TextStyle(fontSize: 10, color: healthColor)),
          ],
        ),
        Text('Uptime: ${uptime}h', style: const TextStyle(fontSize: 10)),
        if (lastActive != null)
          Text('Last: ${_formatTimestamp(lastActive)}', 
               style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildCameraControls(String cameraId) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 20),
            onPressed: () => _zoomCamera(cameraId, 'in'),
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right, size: 20),
            onPressed: () => _rotateCamera(cameraId),
            tooltip: 'Rotate',
          ),
          IconButton(
            icon: const Icon(Icons.screenshot, size: 20),
            onPressed: () => _takeScreenshot(cameraId),
            tooltip: 'Screenshot',
          ),
          IconButton(
            icon: const Icon(Icons.videocam, size: 20),
            onPressed: () => _startRecording(cameraId),
            tooltip: 'Record',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(List<QueryDocumentSnapshot> cameras) {
    final onlineCameras = cameras.where((camera) {
      final data = camera.data() as Map<String, dynamic>;
      return data['status'] == 'online';
    }).length;

    final offlineCameras = cameras.length - onlineCameras;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Online', onlineCameras.toString(), Icons.check_circle, Colors.green),
            _buildStatItem('Offline', offlineCameras.toString(), Icons.error, Colors.red),
            _buildStatItem('Total', cameras.length.toString(), Icons.videocam, Colors.blue),
            _buildStatItem('Alerts', '0', Icons.warning, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildCameraView(String cameraUrl) {
    if (!kIsWeb) {
      return const Center(
        child: Text('Camera streaming is supported on Web only in this demo'),
      );
    }

    final String viewId = 'cameraView-${cameraUrl.hashCode}';

    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) {
        final element = web.HTMLIFrameElement()
          ..src = cameraUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true;
        return element;
      },
    );

    return HtmlElementView(viewType: viewId);
  }

  Widget _buildCameraCard(QueryDocumentSnapshot cameraDoc) {
    final data = cameraDoc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unnamed';
    final url = data['url'] ?? '';
    final status = data['status'] ?? 'offline';
    final cameraId = cameraDoc.id;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: status == 'online' ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.fullscreen, size: 16),
                      onPressed: () => _enterFullScreenMode(cameraId),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: url.isNotEmpty
                ? _buildCameraView(url)
                : const Center(child: Text("Invalid camera URL")),
          ),
          
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildCameraControls(cameraId),
                const SizedBox(height: 4),
                _buildCameraHealth(data),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCameraDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Camera'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Camera Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'IP Webcam URL (e.g. http://192.168.0.101:8080/video)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final url = _urlController.text.trim();
              if (name.isEmpty || url.isEmpty) return;

              await FirebaseFirestore.instance.collection('cameras').add({
                'name': name,
                'url': url,
                'status': 'online',
                'health': 'good',
                'uptime': 0,
                'lastActive': Timestamp.now(),
              });

              _nameController.clear();
              _urlController.clear();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camera added successfully')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Simplified view mode selector - only grid and single view
  Widget _buildViewModeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.grid_view, 
                  color: _viewMode == ViewMode.grid ? Colors.blue : Colors.grey),
              onPressed: () => _changeViewMode(ViewMode.grid),
              tooltip: 'Grid View',
            ),
            IconButton(
              icon: Icon(Icons.fullscreen,
                  color: _viewMode == ViewMode.single ? Colors.blue : Colors.grey),
              onPressed: () {
                if (_viewMode == ViewMode.single) {
                  _exitFullScreenMode();
                } else {
                  // If no camera is selected for single view, select the first one
                  if (_selectedCameraId == null) {
                    setState(() {
                      _selectedCameraId = 'default'; // You can set this to first camera ID
                    });
                  }
                  _changeViewMode(ViewMode.single);
                }
              },
              tooltip: _viewMode == ViewMode.single ? 'Exit Fullscreen' : 'Single View',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search cameras...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        onChanged: _filterCameras,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live CCTV Dashboard'),
        backgroundColor: Colors.black87,
        actions: [_buildViewModeSelector()],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('cameras').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading cameras'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final cameras = snapshot.data!.docs;
          if (cameras.isEmpty) {
            return const Center(child: Text('No cameras added yet.'));
          }

          final filteredCameras = _getFilteredCameras(cameras);

          // Single camera view (fullscreen)
          if (_viewMode == ViewMode.single) {
            QueryDocumentSnapshot cameraDoc;
            if (_selectedCameraId != null) {
              cameraDoc = cameras.firstWhere(
                (doc) => doc.id == _selectedCameraId,
                orElse: () => cameras.first,
              );
            } else {
              cameraDoc = cameras.first;
            }
            
            return Column(
              children: [
                _buildStatsOverview(cameras),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildCameraCard(cameraDoc),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _exitFullScreenMode,
                    child: const Text('Back to Grid View'),
                  ),
                ),
              ],
            );
          }

          // Grid view (default)
          return Column(
            children: [
              _buildSearchBar(),
              _buildStatsOverview(cameras),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 cameras per row
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 16 / 9,
                  ),
                  itemCount: filteredCameras.length,
                  itemBuilder: (context, index) {
                    return _buildCameraCard(filteredCameras[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCameraDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum ViewMode { grid, single }