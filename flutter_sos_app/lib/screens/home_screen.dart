import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSending = false;

  Future<void> _handleSOS() async {
    // 1. Get Location
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showSnack("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) _showSnack("Location permissions are denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showSnack("Location permissions are permanently denied");
      return;
    }

    // 2. Prompt Description
    String? description = await _showDescriptionDialog();
    if (description == null || description.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final position = await Geolocator.getCurrentPosition();

      // 3. Send to Supabase
      await Supabase.instance.client.from('sos_alerts').insert({
        'name': UserProfile.name,
        'phone': UserProfile.phone,
        'description': description,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'location_text': "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}",
        'status': 'NEW',
      });

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) _showSnack("Failed to send SOS: $e");
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
        title: const Text("Emergency Details", style: TextStyle(color: Color(0xFFff2a2a))),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Describe the emergency (e.g. Flood, Injury)",
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (val) => desc = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFff2a2a)),
            onPressed: () => Navigator.pop(context, desc),
            child: const Text("SEND SOS", style: TextStyle(color: Colors.white)),
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
        title: const Text("SOS SENT!", style: TextStyle(color: Color(0xFF00ff9d))),
        content: const Text(
          "Your emergency alert has been received by the control center. Help is being coordinated.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF00ff9d))),
          )
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("SENTINEL USER APP"),
        actions: [
           Padding(
             padding: const EdgeInsets.only(right: 16.0),
             child: Center(child: Text(UserProfile.name, style: const TextStyle(color: Color(0xFF00f3ff)))),
           )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "EMERGENCY ASSISTANCE",
              style: TextStyle(
                fontSize: 16,
                letterSpacing: 2,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _isSending ? null : _handleSOS,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFff2a2a).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFFff2a2a), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFff2a2a).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: Center(
                  child: _isSending
                      ? const CircularProgressIndicator(color: Color(0xFFff2a2a))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "SOS",
                              style: TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFff2a2a),
                              ),
                            ),
                            Text(
                              "PRESS FOR HELP",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFff2a2a),
                              ),
                            )
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                   Icon(Icons.info_outline, color: Colors.blue),
                   SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       "Sending an SOS will share your real-time location and profile details with the Command Center.",
                       style: TextStyle(color: Colors.white70, fontSize: 12),
                     ),
                   )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
