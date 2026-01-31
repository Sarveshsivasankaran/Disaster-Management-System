import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _userLocation = const LatLng(40.7128, -74.0060); // Default
  String _address = "Locating via Satellite...";
  bool _isLoading = true;

  List<Marker> _nearbyResources = [];
  List<Polyline> _evacRoutes = [];

  @override
  void initState() {
    super.initState();
    _startNavigation();
  }

  Future<void> _startNavigation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_userLocation, 14);

      // Simulation of address to avoid Google Maps Dependency
      _address =
          "Sector 7, HQ Vicinity (${_userLocation.latitude.toStringAsFixed(3)}, ${_userLocation.longitude.toStringAsFixed(3)})";

      _generateMockResources();
      _generateEvacRoutes();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Map Error: $e");
    }
  }

  void _generateMockResources() {
    // Simulated Resources logic for standalone use
    final mockRes = [
      {
        'lat': _userLocation.latitude + 0.008,
        'lng': _userLocation.longitude + 0.012,
        'name': 'City Hospital',
        'icon': Icons.local_hospital,
        'color': Colors.red,
        'type': 'MEDICAL'
      },
      {
        'lat': _userLocation.latitude - 0.005,
        'lng': _userLocation.longitude - 0.008,
        'name': 'Emergency Shelter',
        'icon': Icons.home,
        'color': Colors.orange,
        'type': 'SHELTER'
      },
      {
        'lat': _userLocation.latitude + 0.015,
        'lng': _userLocation.longitude - 0.005,
        'name': 'Supply Center',
        'icon': Icons.restaurant,
        'color': Colors.green,
        'type': 'FOOD'
      },
    ];

    setState(() {
      _nearbyResources = mockRes.map((r) {
        return Marker(
          point: LatLng(r['lat'] as double, r['lng'] as double),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showMockDetails(r),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(r['type'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
                Icon(r['icon'] as IconData,
                    color: r['color'] as Color, size: 30),
              ],
            ),
          ),
        );
      }).toList();
    });
  }

  void _showMockDetails(Map<String, dynamic> res) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0f172a),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(res['name'] as String,
                style: const TextStyle(
                    color: Color(0xFF00ff9d),
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Type: ${res['type']}",
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            const Text(
                "This facility is verified and active. Personnel are on standby for disaster response.",
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ff9d),
                    foregroundColor: Colors.black),
                icon: const Icon(Icons.directions),
                label: const Text("INITIALIZE NAVIGATION",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateEvacRoutes() {
    setState(() {
      _evacRoutes = [
        Polyline(
          points: [
            _userLocation,
            LatLng(_userLocation.latitude + 0.015,
                _userLocation.longitude + 0.015),
            LatLng(
                _userLocation.latitude + 0.03, _userLocation.longitude + 0.04),
          ],
          color: const Color(0xFF00ff9d),
          strokeWidth: 6,
          isDotted: true,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050b14),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              PolylineLayer(polylines: _evacRoutes),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.person_pin_circle,
                        color: Color(0xFF2979ff), size: 45),
                  ),
                  ..._nearbyResources,
                ],
              ),
            ],
          ),

          // Header Overlay
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF050b14).withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                border:
                    Border.all(color: const Color(0xFF00ff9d).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.5), blurRadius: 10)
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.satellite_alt, color: Color(0xFF00ff9d)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("DATA FEED: SATELLITE",
                            style: TextStyle(
                                color: Color(0xFF00ff9d),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1)),
                        Text(
                          _address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(color: Color(0xFF00ff9d))),

          // Floating Action Buttons
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "gps",
                  backgroundColor: const Color(0xFF1e293b),
                  onPressed: _startNavigation,
                  child: const Icon(Icons.gps_fixed, color: Color(0xFF00ff9d)),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "sos_fab",
                  backgroundColor: Colors.red,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(Icons.emergency, color: Colors.white),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
