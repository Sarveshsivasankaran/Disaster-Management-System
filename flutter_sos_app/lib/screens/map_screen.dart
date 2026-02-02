import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

enum MapLayer { risk, resources, evac }

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final SupabaseClient _supabase = Supabase.instance.client;

  LatLng _userLocation = const LatLng(13.0827, 80.2707); // Default Chennai
  String _address = "Locating via Satellite...";
  String _currentSector = "ALL";
  bool _isLoading = true;

  MapLayer _activeLayer = MapLayer.risk;

  List<Marker> _buoyMarkers = [];
  final Map<String, LatLng> _sectors = {
    "ALL": const LatLng(13.0827, 80.2707),
    "NORTH COAST": const LatLng(13.14, 80.29),
    "CENTRAL CITY": const LatLng(13.08, 80.27),
    "EAST MOUNTAINS": const LatLng(13.02, 80.20),
  };
  List<CircleMarker> _riskCircles = [];
  List<Marker> _sosMarkers = [];
  List<Marker> _resourceMarkers = [];
  List<Polyline> _evacRoutes = [];

  Map<String, dynamic>? _weatherInfo;
  Map<String, dynamic>? _seismicInfo;

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  Future<void> _initializeMapData() async {
    await _getCurrentLocation();
    _fetchSensors();
    _fetchSOSAlerts();
    _fetchWeather();
    _fetchSeismicData();
    _fetchEvacRoutes();
    _generateResources();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _address =
            "Active Sector: ${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}";
      });
      _mapController.move(_userLocation, 12);
    } catch (e) {
      debugPrint("Location Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- DATA FETCHING ---

  Future<void> _fetchSensors() async {
    try {
      final List<Marker> markers = [];
      final List<CircleMarker> circles = [];

      // 1. Fetch Buoys
      final buoyData = await _supabase.from('buoys').select();
      for (var buoy in buoyData) {
        final lat = buoy['latitude'] as double;
        final lng = buoy['longitude'] as double;
        final waterLevel = (buoy['water_level'] as num).toDouble();

        Color color = const Color(0xFF00ff9d);
        if (waterLevel > 4.0) color = const Color(0xFFffaa00);
        if (waterLevel > 5.5) color = const Color(0xFFff2a2a);

        markers.add(Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showSensorDetails("Marine Buoy ${buoy['id']}", {
              "Water Level": "${waterLevel}m",
              "Wave Height": "${buoy['wave_height']}m",
              "Battery": "${buoy['battery_level']}%",
              "Status": buoy['status'].toString().toUpperCase(),
            }),
            child: Icon(Icons.waves, color: color, size: 24),
          ),
        ));

        circles.add(CircleMarker(
          point: LatLng(lat, lng),
          color: color.withOpacity(0.2),
          borderStrokeWidth: 2,
          borderColor: color,
          useRadiusInMeter: true,
          radius: 1200,
        ));
      }

      // 2. Fetch Landslide Poles
      final poleData = await _supabase.from('landslide_poles').select();
      for (var pole in poleData) {
        final lat = (pole['latitude'] as num).toDouble();
        final lng = (pole['longitude'] as num).toDouble();

        Color color = const Color(0xFF00ff9d);
        if (pole['risk_level'] == 'warning') color = const Color(0xFFffaa00);
        if (pole['risk_level'] == 'critical') color = const Color(0xFFff2a2a);

        markers.add(Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showSensorDetails("Landslide Pole ${pole['id']}", {
              "Soil Moisture": "${pole['soil_moisture']}%",
              "Displacement": "${pole['displacement']}mm",
              "Battery": "${pole['battery_level']}%",
              "Risk": pole['risk_level'].toString().toUpperCase(),
            }),
            child: Icon(Icons.terrain, color: color, size: 24),
          ),
        ));

        circles.add(CircleMarker(
          point: LatLng(lat, lng),
          color: color.withOpacity(0.2),
          borderStrokeWidth: 2,
          borderColor: color,
          useRadiusInMeter: true,
          radius: 800,
        ));
      }

      setState(() {
        _buoyMarkers = markers;
        _riskCircles = circles;
      });
    } catch (e) {
      debugPrint("Fetch Sensors Error: $e");
    }
  }

  Future<void> _fetchSOSAlerts() async {
    try {
      final data =
          await _supabase.from('sos_alerts').select().neq('status', 'RESOLVED');
      final List<Marker> markers = [];

      for (var alert in data) {
        markers.add(
          Marker(
            point: LatLng(alert['latitude'], alert['longitude']),
            width: 50,
            height: 50,
            child: const Icon(Icons.emergency, color: Colors.red, size: 40),
          ),
        );
      }

      setState(() => _sosMarkers = markers);
    } catch (e) {
      debugPrint("Fetch SOS Error: $e");
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=${_userLocation.latitude}&longitude=${_userLocation.longitude}&current_weather=true';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _weatherInfo = data['current_weather']);
      }
    } catch (e) {
      debugPrint("Weather Error: $e");
    }
  }

  Future<void> _fetchSeismicData() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final startTime = DateFormat("yyyy-MM-dd").format(yesterday);

      final url =
          'https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&latitude=${_userLocation.latitude}&longitude=${_userLocation.longitude}&maxradiuskm=500&starttime=$startTime&minmagnitude=2';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          setState(() => _seismicInfo = data['features'][0]['properties']);
        }
      }
    } catch (e) {
      debugPrint("Seismic Error: $e");
    }
  }

  Future<void> _fetchEvacRoutes() async {
    // Using OSRM API for real routes
    final destLat = _userLocation.latitude + 0.02;
    final destLng = _userLocation.longitude - 0.02;

    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${_userLocation.longitude},${_userLocation.latitude};$destLng,$destLat?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates =
            data['routes'][0]['geometry']['coordinates'] as List;

        setState(() {
          _evacRoutes = [
            Polyline(
              points: coordinates
                  .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
                  .toList(),
              color: const Color(0xFF00ff9d),
              strokeWidth: 5,
            )
          ];
        });
      }
    } catch (e) {
      debugPrint("Evac Routes Error: $e");
    }
  }

  void _showSensorDetails(String title, Map<String, String> details) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Color(0xFF00ff9d),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Icon(Icons.analytics, color: Color(0xFF00ff9d)),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            ...details.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 14)),
                      Text(e.value,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ff9d),
                    foregroundColor: Colors.black),
                onPressed: () => Navigator.pop(context),
                child: const Text("CLOSE ANALYTICS",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _generateResources() {
    final List<Map<String, dynamic>> realResources = [
      {
        'name': 'Rajiv Gandhi Govt General Hospital',
        'type': 'HOSPITAL',
        'lat': 13.0827,
        'lng': 80.2753,
        'icon': Icons.local_hospital,
        'color': Colors.red
      },
      {
        'name': 'Apollo Hospital - Greams Road',
        'type': 'HOSPITAL',
        'lat': 13.0605,
        'lng': 80.2520,
        'icon': Icons.local_hospital,
        'color': Colors.red
      },
      {
        'name': 'Stanley Medical College Hospital',
        'type': 'HOSPITAL',
        'lat': 13.1065,
        'lng': 80.2801,
        'icon': Icons.local_hospital,
        'color': Colors.red
      },
      {
        'name': 'Nehru Indoor Stadium (Shelter)',
        'type': 'SHELTER',
        'lat': 13.0855,
        'lng': 80.2711,
        'icon': Icons.home,
        'color': Colors.orange
      },
      {
        'name': 'Corporation School (Shelter)',
        'type': 'SHELTER',
        'lat': 13.0566,
        'lng': 80.2582,
        'icon': Icons.home,
        'color': Colors.orange
      },
      {
        'name': 'Anna Nagar Relief Hub',
        'type': 'SHELTER',
        'lat': 13.0837,
        'lng': 80.2114,
        'icon': Icons.home,
        'color': Colors.orange
      },
      {
        'name': 'Chennai Food Bank Hub',
        'type': 'FOOD_BANK',
        'lat': 13.0645,
        'lng': 80.2645,
        'icon': Icons.restaurant,
        'color': Colors.green
      },
      {
        'name': 'No Food Waste Hub',
        'type': 'FOOD_BANK',
        'lat': 13.0394,
        'lng': 80.2337,
        'icon': Icons.restaurant,
        'color': Colors.green
      },
      {
        'name': 'Akshayapatra Kitchen',
        'type': 'FOOD_BANK',
        'lat': 13.1118,
        'lng': 80.2458,
        'icon': Icons.restaurant,
        'color': Colors.green
      },
      {
        'name': 'Kilpauk Water Works',
        'type': 'WATER_POINT',
        'lat': 13.0829,
        'lng': 80.2427,
        'icon': Icons.water_drop,
        'color': Colors.blue
      },
      {
        'name': 'T.Nagar MetroWater',
        'type': 'WATER_POINT',
        'lat': 13.0410,
        'lng': 80.2350,
        'icon': Icons.water_drop,
        'color': Colors.blue
      },
      {
        'name': 'Adyar Water Station',
        'type': 'WATER_POINT',
        'lat': 13.0064,
        'lng': 80.2514,
        'icon': Icons.water_drop,
        'color': Colors.blue
      },
    ];

    final List<Marker> markers = [];
    for (var res in realResources) {
      markers.add(Marker(
        point: LatLng(res['lat'] as double, res['lng'] as double),
        width: 60,
        height: 60,
        child: Column(
          children: [
            Icon(res['icon'] as IconData,
                color: res['color'] as Color, size: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                res['type'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 8),
              ),
            ),
          ],
        ),
      ));
    }
    setState(() => _resourceMarkers = markers);
  }

  // --- UI COMPONENTS ---

  Widget _buildLayerToggle() {
    return Positioned(
      top: 120,
      left: 15,
      right: 15,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF050b14).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            _layerButton("RISK ZONES", MapLayer.risk),
            _layerButton("RESOURCES", MapLayer.resources),
            _layerButton("EVAC ROUTES", MapLayer.evac),
          ],
        ),
      ),
    );
  }

  Widget _layerButton(String title, MapLayer layer) {
    bool isActive = _activeLayer == layer;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeLayer = layer),
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF00ff9d).withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? const Color(0xFF00ff9d) : Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataOverlay() {
    return Positioned(
      bottom: 100,
      left: 15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_weatherInfo != null)
            _infoCard(
                "🌡️ ${_weatherInfo!['temperature']}°C | 💨 ${_weatherInfo!['windspeed']} km/h",
                const Color(0xFF00f3ff)),
          const SizedBox(height: 8),
          if (_seismicInfo != null)
            _infoCard(
                "🫨 SEISMIC: ${_seismicInfo!['mag']} Mag - ${_seismicInfo!['place']}",
                const Color(0xFFffaa00)),
        ],
      ),
    );
  }

  Widget _infoCard(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF050b14).withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
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
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              if (_activeLayer == MapLayer.risk) ...[
                CircleLayer(circles: _riskCircles),
                MarkerLayer(markers: _buoyMarkers),
              ],
              if (_activeLayer == MapLayer.resources)
                MarkerLayer(markers: _resourceMarkers),
              if (_activeLayer == MapLayer.evac)
                PolylineLayer(polylines: _evacRoutes),
              MarkerLayer(markers: _sosMarkers),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.person_pin_circle,
                        color: Color(0xFF2979ff), size: 45),
                  ),
                ],
              ),
            ],
          ),

          // Header
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
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _currentSector,
                            dropdownColor: const Color(0xFF0f172a),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Color(0xFF00ff9d), size: 16),
                            style: const TextStyle(
                                color: Color(0xFF00ff9d),
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                            items: _sectors.keys.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _currentSector = val;
                                  _userLocation = _sectors[val]!;
                                  _mapController.move(
                                      _userLocation, val == "ALL" ? 11 : 13);
                                });
                                _initializeMapData();
                              }
                            },
                          ),
                        ),
                        Text(_address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: _initializeMapData,
                  )
                ],
              ),
            ),
          ),

          _buildLayerToggle(),
          _buildDataOverlay(),

          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(color: Color(0xFF00ff9d))),

          // FABs
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "gps",
                  backgroundColor: const Color(0xFF1e293b),
                  onPressed: () => _mapController.move(_userLocation, 14),
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
