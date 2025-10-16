import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  // 🔹 Stream live count from Firestore
  Stream<int> _getStreamCount(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map((s) => s.size);
  }

  // 🔹 Fetch Visitors grouped by day for chart (last 7 days)
  Stream<Map<String, int>> _getVisitorsPerDay() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    return FirebaseFirestore.instance
        .collection("visitors")
        .where("checkIn", isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
        .snapshots()
        .map((snapshot) {
      final counts = <String, int>{};

      // Initialize last 7 days with 0
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final key = DateFormat('MMM dd').format(date);
        counts[key] = 0;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final checkIn = (data["checkIn"] as Timestamp?)?.toDate();
        if (checkIn != null) {
          final day = DateFormat('MMM dd').format(checkIn);
          counts[day] = (counts[day] ?? 0) + 1;
        }
      }
      return counts;
    });
  }

  // 🔹 Fetch Incidents per month for chart (current year)
  Stream<Map<String, int>> _getIncidentsTrend() {
    final yearStart = DateTime(DateTime.now().year, 1, 1);

    return FirebaseFirestore.instance
        .collection("incidents")
        .where("timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart))
        .snapshots()
        .map((snapshot) {
      final counts = <String, int>{};

      // Initialize months with 0
      for (int i = 1; i <= 12; i++) {
        counts[DateFormat('MMM').format(DateTime(DateTime.now().year, i))] = 0;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final date = (data["timestamp"] as Timestamp?)?.toDate();
        if (date != null) {
          final month = DateFormat('MMM').format(date);
          counts[month] = (counts[month] ?? 0) + 1;
        }
      }
      return counts;
    });
  }

  // 🔹 Get real-time dashboard stats (safe fallback)
  Stream<Map<String, dynamic>> _getDashboardStats() {
    return FirebaseFirestore.instance
        .collection("dashboard_stats")
        .doc("current")
        .snapshots()
        .map((doc) => doc.exists ? (doc.data() as Map<String, dynamic>) : {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header with last update time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("📊 Analytics Dashboard",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("dashboard_stats")
                      .doc("current")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Text(
                        "Updated: --:--",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      );
                    }
                    final data =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final lastUpdate = data["last_updated"] as Timestamp?;
                    return Text(
                      "Updated: ${lastUpdate != null ? DateFormat('HH:mm').format(lastUpdate.toDate()) : '--:--'}",
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Summary Stats Row
            _buildStatsGrid(),

            const SizedBox(height: 30),

            // 🔹 Charts Section
            _buildChartsSection(),

            const SizedBox(height: 30),

            // 🔹 Recent Activity
            _buildRecentActivitySection(),
          ],
        ),
      ),
    );
  }

  // 📊 Stats Grid
  Widget _buildStatsGrid() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _getDashboardStats(),
      builder: (context, statsSnapshot) {
        final stats = statsSnapshot.data ?? {};
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.5,
          children: [
            _buildEnhancedStatCard(
              "Total Users",
              _getStreamCount("users"),
              Icons.people_outline,
              Colors.blue,
              stats['users_trend'] ?? 0,
            ),
            _buildEnhancedStatCard(
              "Today's Events",
              _getTodaysEventsCount(),
              Icons.event_outlined,
              Colors.purple,
              stats['events_trend'] ?? 0,
            ),
          ],
        );
      },
    );
  }

  // 🔹 Helper: real-time counts
  Stream<int> _getTodaysEventsCount() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection("events")
        .where("timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where("timestamp", isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((s) => s.size);
  }

  // 📊 Stat Card
  Widget _buildEnhancedStatCard(
    String title,
    Stream<int> countStream,
    IconData icon,
    Color color,
    int trend,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<int>(
          stream: countStream,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            final isPositiveTrend = trend >= 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPositiveTrend
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPositiveTrend
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 12,
                            color: isPositiveTrend ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${trend.abs()}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  isPositiveTrend ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 📊 Charts Section
  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("📈 Activity Overview",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        // Visitors Chart
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: _buildEnhancedVisitorsChart(),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Incidents Chart
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: _buildEnhancedIncidentsChart(),
            ),
          ),
        ),
      ],
    );
  }

  // Visitors Chart
  Widget _buildEnhancedVisitorsChart() {
    return StreamBuilder<Map<String, int>>(
      stream: _getVisitorsPerDay(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final keys = data.keys.toList();
        final values = keys.map((key) => data[key]!.toDouble()).toList();

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < keys.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(keys[index], style: const TextStyle(fontSize: 10)),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
            ),
            borderData: FlBorderData(show: true),
            barGroups: List.generate(keys.length, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: values[index],
                    color: Colors.blue,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // Incidents Chart
  Widget _buildEnhancedIncidentsChart() {
    return StreamBuilder<Map<String, int>>(
      stream: _getIncidentsTrend(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        final spots = months.map((month) {
          return FlSpot(
            months.indexOf(month).toDouble(),
            (data[month] ?? 0).toDouble(),
          );
        }).toList();

        return LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < months.length && index % 2 == 0) {
                      return Text(months[index], style: const TextStyle(fontSize: 10));
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                spots: spots,
                color: Colors.red,
                barWidth: 3,
                belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
                dotData: const FlDotData(show: true),
              )
            ],
          ),
        );
      },
    );
  }

  // 🔹 Recent Activity
  Widget _buildRecentActivitySection() {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Recent Activity",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: "All"),
                    Tab(text: "Incidents"),
                    Tab(text: "Events"),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      _buildActivityStream("recent_activity"),
                      _buildActivityStream("incidents"),
                      _buildActivityStream("events"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStream(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .orderBy("timestamp", descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildActivityList(snapshot.data!.docs);
      },
    );
  }

  Widget _buildActivityList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Center(child: Text("No activity yet"));
    }
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>? ?? {};
        final timestamp = (data["timestamp"] as Timestamp?)?.toDate();
        final type = data["type"] ?? "Activity";

        return ListTile(
          leading: _getActivityIcon(type),
          title: Text(data["title"] ?? type),
          subtitle: Text(
            timestamp != null ? DateFormat('MMM dd, HH:mm').format(timestamp) : "",
          ),
          trailing: _getStatusChip(data["status"]),
        );
      },
    );
  }

  Icon _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case "incident":
        return const Icon(Icons.warning, color: Colors.orange);
      case "event":
        return const Icon(Icons.event, color: Colors.purple);
      case "visitor":
        return const Icon(Icons.person, color: Colors.green);
      default:
        return const Icon(Icons.notifications, color: Colors.blue);
    }
  }

  Widget _getStatusChip(String? status) {
    Color color = Colors.grey;
    if (status == "Resolved") color = Colors.green;
    if (status == "Critical") color = Colors.red;
    if (status == "In Progress") color = Colors.orange;

    return status != null
        ? Chip(
            label: Text(status, style: const TextStyle(fontSize: 10)),
            backgroundColor: color.withOpacity(0.1),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          )
        : const SizedBox();
  }
}
