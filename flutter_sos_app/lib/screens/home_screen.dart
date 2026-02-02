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

  void _startDangerCheck() {
    // Check for nearby danger periodically
    _dangerCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkForNearbyDangers();
    });
  }

  Future<void> _checkForNearbyDangers() async {
    try {
      final position = await Geolocator.getCurrentPosition();

      // Query 'buoys' for high water levels near user (+/- 0.05 degrees)
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
          DashboardView(
              onTabChange: (i) =>
                  setState(() => _selectedIndex = i)), // New Command Center UI
          const SocialFeedScreen(), // Social Media News
          const MapScreen(), // Resources & Routes
          const SOSView(), // Dedicated SOS/Report Page
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF0f172a),
        selectedItemColor: const Color(0xFF00ff9d),
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        onTap: (index) => setState(() => _selectedIndex = index),
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
// DASHBOARD VIEW (COMMAND CENTER)
// ============================================================================
class DashboardView extends StatefulWidget {
  final Function(int) onTabChange;
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
          .limit(1);

      if (buoyData.isNotEmpty) {
        final latest = buoyData[0];
        setState(() {
          _stats['water'] = "${latest['water_level'].toStringAsFixed(1)}m";
          _stats['wave'] = "${latest['wave_height'].toStringAsFixed(1)}m";
          // Calculate a simple risk score like in app.js
          double wl = (latest['water_level'] as num).toDouble();
          double wh = (latest['wave_height'] as num).toDouble();
          _stats['risk'] =
              ((wl / 8 * 50) + (wh / 5 * 50)).clamp(0, 100).toInt();
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
              // HEADER
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("COMMAND CENTER",
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              letterSpacing: 2)),
                      SizedBox(height: 4),
                      Text("Sector: Central City",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.person, color: Color(0xFF00ff9d)),
                  )
                ],
              ),
              const SizedBox(height: 30),

              // LIVE ALERTS BANNER (Risk Score)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      _stats['risk'] > 70
                          ? Colors.red
                          : const Color(0xFF00C9A7),
                      const Color(0xFF00ff9d)
                    ]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF00ff9d).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 5))
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("AI RISK ASSESSMENT",
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text("${_stats['risk']}% PROBABILITY",
                                style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)))
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                        _stats['risk'] > 60
                            ? "HIGH RISK OF FLOOD SURGE"
                            : "SYSTEM STABLE - NO IMMEDIATE THREAT",
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // TELEMETRY ROW
              const Text("LIVE TELEMETRY",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 15),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildStatCard("WATER LEVEL", _stats['water'], Colors.blue,
                        Icons.water),
                    const SizedBox(width: 15),
                    _buildStatCard("WAVE HEIGHT", _stats['wave'], Colors.cyan,
                        Icons.tsunami),
                    const SizedBox(width: 15),
                    _buildStatCard("SYSTEM TEMP", "24.5°C", Colors.orange,
                        Icons.thermostat),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // QUICK ACCESS
              const Text("QUICK ACCESS",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                      child: GestureDetector(
                          onTap: () => widget.onTabChange(2),
                          child: _buildSmallBtn(
                              "SHELTERS", Icons.home, Colors.blue))),
                  const SizedBox(width: 15),
                  Expanded(
                      child: GestureDetector(
                          onTap: () => widget.onTabChange(3),
                          child: _buildSmallBtn(
                              "EMERGENCY", Icons.call, Colors.green))),
                ],
              ),
              const SizedBox(height: 30),

              // REPORT BUTTON (LARGE)
              Center(
                child: GestureDetector(
                  onTap: () => widget.onTabChange(3),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [Color(0xFFff2a2a), Color(0xFFd90429)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFff2a2a)
                                  .withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 5)
                        ]),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_rounded,
                            color: Colors.white, size: 48),
                        SizedBox(height: 8),
                        Text("SOS",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16))
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF0f172a),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSmallBtn(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
          color: const Color(0xFF0f172a),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold))
        ],
      ),
    );
  }
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
    // 1. Check Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // 2. Prompt Description
    String? description = await _showDescriptionDialog();
    if (description == null || description.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final position = await Geolocator.getCurrentPosition();

      // 3. Send to Supabase
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
      if (mounted) _showSnack("Failed to broadcast SOS: $e");
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
                color: Color(0xFFff2a2a),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "e.g. Floodwater entered house, Need medical help",
            hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white12)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFff2a2a))),
          ),
          onChanged: (val) => desc = val,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child:
                  const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFff2a2a),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, desc),
            child: const Text("SEND SOS",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
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
            Icon(Icons.radar, color: Color(0xFF00ff9d), size: 64),
            SizedBox(height: 20),
            Text(
              "Your location is being tracked by the Command Center. Maintain radio silence and stay on high ground.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("DISMISS",
                  style: TextStyle(
                      color: Color(0xFF00ff9d), fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: NetworkImage(
                  "https://www.transparenttextures.com/patterns/carbon-fibre.png"),
              repeat: ImageRepeat.repeat,
              opacity: 0.1)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.radio_button_checked,
              color: Color(0xFFff2a2a), size: 12),
          const SizedBox(height: 8),
          const Text("LIVE TELEMETRY: ACTIVE",
              style: TextStyle(
                  color: Color(0xFF00ff9d),
                  letterSpacing: 3,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 60),
          GestureDetector(
            onLongPress: _isSending ? null : _handleSOS,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Glow
                _buildPulseCircle(300, 0.1),
                _buildPulseCircle(260, 0.2),

                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                        colors: [Color(0xFFff2a2a), Color(0xFF880000)]),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFff2a2a).withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 10)
                    ],
                  ),
                  child: Center(
                    child: _isSending
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 6)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("SOS",
                                  style: TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -2)),
                              Text("HOLD TO BROADCAST",
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              "OPERATOR: ${UserProfile.name.toUpperCase()}",
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: const Color(0xFFff2a2a).withValues(alpha: opacity),
            width: 2),
      ),
    );
  }
}
