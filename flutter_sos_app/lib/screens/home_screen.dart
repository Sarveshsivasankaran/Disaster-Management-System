import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../user_profile.dart';
import 'map_screen.dart';
import 'social_feed_screen.dart';
import '../main.dart'; // To access the global notification plugin

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Timer? _dangerCheckTimer;
  final GlobalKey<MapScreenState> _mapScreenKey = GlobalKey<MapScreenState>();

  @override
  void initState() {
    super.initState();
    _startDangerCheck();
  }

  @override
  void dispose() {
    _dangerCheckTimer?.cancel();
    super.dispose();
  }

  void _changeTab(int index, [MapLayer? layer]) {
    setState(() => _selectedIndex = index);
    if (index == 2 && layer != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _mapScreenKey.currentState?.setActiveLayer(layer);
      });
    }
  }

  void _startDangerCheck() {
    _dangerCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkForNearbyDangers();
    });
  }

  Future<void> _checkForNearbyDangers() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final response = await Supabase.instance.client
          .from('buoys')
          .select()
          .gt('water_level', 5.0)
          .filter('latitude', 'gt', position.latitude - 0.05)
          .filter('latitude', 'lt', position.latitude + 0.05);

      if (response != null && response.isNotEmpty) {
        _triggerSystemNotification(response.length);
      }
    } catch (e) {
      debugPrint("Danger check error: $e");
    }
  }

  Future<void> _triggerSystemNotification(int count) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'danger_alerts',
      'Danger Alerts',
      channelDescription: 'Notifications for nearby disaster threats',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.red,
      playSound: true,
      enableVibration: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      '⚠️ IMMEDIATE DANGER DETECTED',
      '$count sensors reporting extreme water levels in your vicinity. Evacuate if necessary.',
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050b14),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardView(onTabChange: (i, [layer]) => _changeTab(i, layer)),
          const SocialFeedScreen(),
          MapScreen(key: _mapScreenKey),
          const SOSView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF0f172a),
        selectedItemColor: const Color(0xFF00ff9d),
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        onTap: (index) => _changeTab(index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_rounded), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: "Map"),
          BottomNavigationBarItem(
              icon: Icon(Icons.emergency_share), label: "Report"),
        ],
      ),
    );
  }
}

// ============================================================================
// DASHBOARD VIEW (COMMAND CENTER) - Custom Visualization
// ============================================================================
class DashboardView extends StatefulWidget {
  final Function(int, [MapLayer?]) onTabChange;
  const DashboardView({super.key, required this.onTabChange});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final Map<String, dynamic> _stats = {
    'water': '0.0m',
    'wave': '0.0m',
    'wind': '--- km/h',
    'risk': 0,
  };
  List<double> _waterHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveStats();
  }

  Future<void> _fetchLiveStats() async {
    try {
      final supabase = Supabase.instance.client;
      final buoyData = await supabase
          .from('buoys')
          .select()
          .order('last_update', ascending: false)
          .limit(10);

      if (buoyData.isNotEmpty) {
        final latest = buoyData[0];
        setState(() {
          _stats['water'] = "${latest['water_level'].toStringAsFixed(1)}m";
          _stats['wave'] = "${latest['wave_height'].toStringAsFixed(1)}m";
          double wl = (latest['water_level'] as num).toDouble();
          double wh = (latest['wave_height'] as num).toDouble();
          _stats['risk'] =
              ((wl / 8 * 50) + (wh / 5 * 50)).clamp(0, 100).toInt();

          // Map history for custom chart
          _waterHistory = buoyData
              .map((e) => (e['water_level'] as num).toDouble())
              .toList()
              .reversed
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Dashboard Stats Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildRiskBanner(),
              const SizedBox(height: 30),
              const Text("LIVE TELEMETRY ANALYTICS",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
              const SizedBox(height: 20),
              _buildChartSection(),
              const SizedBox(height: 30),
              _buildStatGrid(),
              const SizedBox(height: 30),
              _buildActionGrid(),
              const SizedBox(height: 30),
              _buildSOSAnchor(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("COMMAND CENTER",
                style: TextStyle(
                    color: Colors.white54, fontSize: 12, letterSpacing: 2)),
            SizedBox(height: 4),
            Text("Satellite Status: ONLINE",
                style: TextStyle(
                    color: Color(0xFF00ff9d),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        Icon(Icons.radar, color: Color(0xFF00ff9d), size: 30)
      ],
    );
  }

  Widget _buildRiskBanner() {
    bool highRisk = _stats['risk'] > 60;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF0f172a),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: highRisk
                  ? Colors.red.withValues(alpha: 0.5)
                  : const Color(0xFF00ff9d).withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
                color: (highRisk ? Colors.red : const Color(0xFF00ff9d))
                    .withValues(alpha: 0.1),
                blurRadius: 20)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("AI THREAT ASSESSMENT",
                  style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Text("${_stats['risk']}%",
                  style: TextStyle(
                      color: highRisk ? Colors.red : const Color(0xFF00ff9d),
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white12, borderRadius: BorderRadius.circular(3)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_stats['risk'] / 100.0).clamp(0.0, 1.0),
              child: Container(
                  decoration: BoxDecoration(
                      color: highRisk ? Colors.red : const Color(0xFF00ff9d),
                      borderRadius: BorderRadius.circular(3))),
            ),
          ),
          const SizedBox(height: 15),
          Text(
              highRisk
                  ? "CRITICAL SURGE PROBABILITY - EVACUATE COASTAL SECTORS"
                  : "CONDITION GREEN - NORMAL SECTOR STABILITY",
              style: TextStyle(
                  color: highRisk ? Colors.redAccent : Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF0f172a),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10)),
      child: _waterHistory.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00ff9d)))
          : CustomPaint(
              painter: TelemetryPainter(points: _waterHistory),
            ),
    );
  }

  Widget _buildStatGrid() {
    return Row(
      children: [
        Expanded(
            child: _buildStatItem(
                "WATER", _stats['water'], Icons.water, Colors.blue)),
        const SizedBox(width: 15),
        Expanded(
            child: _buildStatItem(
                "SURGE", _stats['wave'], Icons.tsunami, Colors.cyan)),
        const SizedBox(width: 15),
        Expanded(
            child: _buildStatItem("SECTOR", "C-01", Icons.map, Colors.orange)),
      ],
    );
  }

  Widget _buildStatItem(String label, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: const Color(0xFF0f172a),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
          Text(val,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return Row(
      children: [
        Expanded(
            child: _actionBtn(
                "SHELTERS",
                Icons.apartment,
                const Color(0xFF00f3ff),
                () => widget.onTabChange(2, MapLayer.resources))),
        const SizedBox(width: 15),
        Expanded(
            child: _actionBtn(
                "EVAC PATH",
                Icons.alt_route,
                const Color(0xFFffaa00),
                () => widget.onTabChange(2, MapLayer.evac))),
      ],
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSAnchor() {
    return Center(
      child: GestureDetector(
        onTap: () => widget.onTabChange(3),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                colors: [Color(0xFFff2a2a), Color(0xFF880000)]),
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5)
            ],
          ),
          child: const Center(
              child: Text("SOS",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }
}

class TelemetryPainter extends CustomPainter {
  final List<double> points;
  TelemetryPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = const Color(0xFF00ff9d)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00ff9d).withValues(alpha: 0.3),
          Colors.transparent
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    double maxVal = points.reduce((a, b) => a > b ? a : b);
    if (maxVal < 1.0) maxVal = 1.0;

    double stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      double x = i * stepX;
      double y = size.height - (points[i] / maxVal * (size.height * 0.8));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TelemetryPainter oldDelegate) =>
      oldDelegate.points != points;
}

// ============================================================================
// SOS VIEW (Direct Report)
// ============================================================================
class SOSView extends StatefulWidget {
  const SOSView({super.key});

  @override
  State<SOSView> createState() => _SOSViewState();
}

class _SOSViewState extends State<SOSView> {
  bool _isSending = false;

  Future<void> _handleSOS() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    String? description = await _showDescriptionDialog();
    if (description == null || description.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final position = await Geolocator.getCurrentPosition();
      final now = DateTime.now();
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      await Supabase.instance.client.from('sos_alerts').insert({
        'name': UserProfile.name,
        'phone': UserProfile.phone,
        'description': description,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'location_text':
            "Mobile GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
        'status': 'NEW',
        'date': dateStr,
        'time': timeStr,
      });

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to broadcast SOS: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<String?> _showDescriptionDialog() async {
    String desc = "";
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0f172a),
        title: const Text("DESCRIBE EMERGENCY",
            style: TextStyle(
                color: Color(0xFFff2a2a), fontWeight: FontWeight.bold)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: "e.g. Floodwater entered house",
              hintStyle: TextStyle(color: Colors.white24, fontSize: 13)),
          onChanged: (val) => desc = val,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("CANCEL")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, desc),
              child: const Text("SEND SOS")),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0f172a),
        title: const Text("TRANSMISSION SUCCESS",
            style: TextStyle(color: Color(0xFF00ff9d))),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radar, color: Color(0xFF00ff9d), size: 60),
            SizedBox(height: 20),
            Text("Rescue coordinators have been notified of your location.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("DISMISS"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF050b14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("EMERGENCY BROADCAST UNIT",
              style: TextStyle(
                  color: Color(0xFF00ff9d),
                  letterSpacing: 2,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 100),
          GestureDetector(
            onLongPress: _isSending ? null : _handleSOS,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.red, width: 4)),
              child: Center(
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.red)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text("SOS",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold)),
                            Text("HOLD TO SEND",
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 10))
                          ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
