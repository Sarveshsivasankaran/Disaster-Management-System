import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../user_profile.dart';
import 'map_screen.dart';
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
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
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
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          SOSView(),
          MapScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF050b14),
        selectedItemColor: const Color(0xFF00ff9d),
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.emergency_share, size: 28), label: "SOS"),
          BottomNavigationBarItem(icon: Icon(Icons.map, size: 28), label: "MAPS"),
        ],
      ),
    );
  }
}

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
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      await Supabase.instance.client.from('sos_alerts').insert({
        'name': UserProfile.name,
        'phone': UserProfile.phone,
        'description': description,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'location_text': "Mobile GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
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
        title: const Text("DESCRIBE EMERGENCY", style: TextStyle(color: Color(0xFFff2a2a), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "e.g. Floodwater entered house, Need medical help",
            hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFff2a2a))),
          ),
          onChanged: (val) => desc = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFff2a2a), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, desc),
            child: const Text("SEND SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: const Text("TRANSMISSION SUCCESS", style: TextStyle(color: Color(0xFF00ff9d))),
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
              child: const Text("DISMISS", style: TextStyle(color: Color(0xFF00ff9d), fontWeight: FontWeight.bold)),
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
          image: NetworkImage("https://www.transparenttextures.com/patterns/carbon-fibre.png"),
          repeat: ImageRepeat.repeat,
          opacity: 0.1
        )
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.radio_button_checked, color: Color(0xFFff2a2a), size: 12),
          const SizedBox(height: 8),
          const Text("LIVE TELEMETRY: ACTIVE", style: TextStyle(color: Color(0xFF00ff9d), letterSpacing: 3, fontSize: 10, fontWeight: FontWeight.bold)),
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
                    gradient: const RadialGradient(colors: [Color(0xFFff2a2a), Color(0xFF880000)]),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFff2a2a).withOpacity(0.5), blurRadius: 40, spreadRadius: 10)
                    ],
                  ),
                  child: Center(
                    child: _isSending
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 6)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("SOS", style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -2)),
                              Text("HOLD TO BROADCAST", style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
            child: Text(
              "OPERATOR: ${UserProfile.name.toUpperCase()}",
              style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 30),
          IconButton(
            onPressed: () async {
              await UserProfile.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.power_settings_new, color: Colors.white24),
          )
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
        border: Border.all(color: const Color(0xFFff2a2a).withOpacity(opacity), width: 2),
      ),
    );
  }
}
