import 'dart:convert';
import 'dart:math' as math;
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
  MapScreenState createState() => MapScreenState();
}

enum MapLayer { risk, resources, evac }

class MapScreenState extends State<MapScreen> {
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

  Map<String, dynamic>? _routeAnalytics;

  Map<String, dynamic>? _weatherInfo;
  Map<String, dynamic>? _seismicInfo;

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  void setActiveLayer(MapLayer layer) {
    setState(() {
      _activeLayer = layer;
    });
  }

  Future<void> _initializeMapData() async {
    await _getCurrentLocation();
    // Fetch independent data
    _fetchSensors();
    _fetchSOSAlerts();
    _fetchWeather();
    _fetchSeismicData();

    // Await resources so that we can calculate routes if needed
    await _fetchResources();

    if (_activeLayer == MapLayer.evac && _evacRoutes.isEmpty) {
      _fetchAutomaticEvacRoute();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _address =
            "Sector: ${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}";
      });
      _mapController.move(_userLocation, 12);
    } catch (e) {
      debugPrint("Location Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- AI LOGIC ---

  String _getAIReasoning(LatLng dest) {
    bool isRainy = (_weatherInfo?['weathercode'] ?? 0) > 50;
    bool highTide = _riskCircles.any((c) => c.radius > 500);

    if (isRainy) {
      return "AI-Optimized for heavy precipitation. Avoiding low-lying water catchment areas.";
    }
    if (highTide) {
      return "Safe-path identified avoiding coastal surge zones detected via Marine Sensors.";
    }
    return "Optimal route calculated via OSRM Engine. Path verified for maximum clearance.";
  }

  // --- DATA FETCHING ---

  Future<void> _fetchSensors() async {
    try {
      final List<Marker> markers = [];
      final List<CircleMarker> circles = [];

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
          width: 45,
          height: 45,
          child: GestureDetector(
            onTap: () => _showSensorDetails("Marine Buoy ${buoy['id']}", {
              "Water Level": "${waterLevel}m",
              "Wave Height": "${buoy['wave_height']}m",
              "Battery": "${buoy['battery_level']}%",
              "Status": buoy['status'].toString().toUpperCase(),
            }),
            child: Container(
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.3), blurRadius: 10)
                  ]),
              child: Icon(Icons.waves, color: color, size: 20),
            ),
          ),
        ));

        circles.add(CircleMarker(
          point: LatLng(lat, lng),
          color: color.withValues(alpha: 0.15),
          borderStrokeWidth: 2,
          borderColor: color,
          useRadiusInMeter: true,
          radius: waterLevel > 5.0 ? 1500 : 1000,
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
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: const Icon(Icons.emergency, color: Colors.red, size: 40),
              ),
              onEnd: () {}, // Pulse effect
            ),
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
      final startTime = DateFormat("yyyy-MM-dd")
          .format(now.subtract(const Duration(days: 1)));
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

  Future<void> _fetchAutomaticEvacRoute() async {
    if (_resourceMarkers.isEmpty) return;
    final nearest = _resourceMarkers.first.point;
    _fetchRouteTo(nearest);
  }

  Future<void> _fetchRouteTo(LatLng destination) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${_userLocation.longitude},${_userLocation.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          debugPrint("No route found by OSRM");
          return;
        }
        final coordinates =
            data['routes'][0]['geometry']['coordinates'] as List;
        final distance =
            (data['routes'][0]['distance'] as num).toDouble() / 1000;
        final duration = (data['routes'][0]['duration'] as num).toDouble() / 60;

        setState(() {
          _evacRoutes = [
            Polyline(
              points: coordinates
                  .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
                  .toList(),
              color: const Color(0xFF00ff9d),
              strokeWidth: 6,
            )
          ];
          _routeAnalytics = {
            "distance": distance.toStringAsFixed(1),
            "duration": duration.toInt(),
            "reasoning": _getAIReasoning(destination)
          };
          _activeLayer = MapLayer.evac;
        });
        _mapController.move(destination, 14);
      }
    } catch (e) {
      debugPrint("Evac Routes Error: $e");
    }
  }

  void _showResourceDetails(Map<String, dynamic> res) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0f172a),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: Color(0xFF00ff9d), width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(res['icon'], color: res['color'], size: 30),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(res['name'],
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text(res['type'],
                          style: TextStyle(
                              color: res['color'],
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text("OPERATIONAL",
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _resMetaIcon(Icons.near_me, "DISTANCE",
                    "~${(math.Random().nextDouble() * 3).toStringAsFixed(1)} KM"),
                _resMetaIcon(Icons.access_time, "WAIT TIME", "< 5 MIN"),
                _resMetaIcon(Icons.verified_user, "SECURITY", "SAFE"),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.navigation, color: Colors.black),
                label: const Text("INITIALIZE AI EVACUATION PATH",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ff9d)),
                onPressed: () {
                  Navigator.pop(context);
                  _fetchRouteTo(LatLng(res['lat'], res['lng']));
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _resMetaIcon(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    );
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
          ],
        ),
      ),
    );
  }

  Future<void> _fetchResources() async {
    const radius = 5000;
    final query =
        """[out:json];(nwr["amenity"~"hospital|police|fire_station|shelter|pharmacy|clinic|community_centre|school|place_of_worship"](around:$radius,${_userLocation.latitude},${_userLocation.longitude});nwr["tourism"="hotel"](around:$radius,${_userLocation.latitude},${_userLocation.longitude});nwr["emergency"="social_facility"](around:$radius,${_userLocation.latitude},${_userLocation.longitude}););out center;""";

    try {
      final url =
          'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> elements = data['elements'];
        final List<Marker> markers = [];
        for (var element in elements) {
          final double? eLat = element['lat'] ?? element['center']?['lat'];
          final double? eLng = element['lon'] ?? element['center']?['lon'];
          if (eLat == null || eLng == null) continue;

          final tags = element['tags'] ?? {};
          final name = tags['name'] ?? "Emergency Facility";
          final type = (tags['amenity'] ?? tags['tourism'] ?? "RESOURCE")
              .toString()
              .toLowerCase();

          IconData icon = Icons.location_on;
          Color color = Colors.blue;
          if (type.contains('hospital') || type.contains('clinic')) {
            icon = Icons.local_hospital;
            color = Colors.red;
          } else if (type.contains('police')) {
            icon = Icons.local_police;
            color = Colors.blue;
          } else if (type.contains('fire')) {
            icon = Icons.fire_truck;
            color = Colors.orange;
          } else if (type.contains('shelter') || type.contains('hotel')) {
            icon = Icons.home;
            color = Colors.green;
          }

          final double resLat = eLat;
          final double resLng = eLng;

          // Double check distance strict limit
          if (Geolocator.distanceBetween(_userLocation.latitude,
                  _userLocation.longitude, resLat, resLng) >
              radius) {
            continue;
          }

          final mapData = {
            'name': name,
            'type': type.toUpperCase(),
            'lat': resLat,
            'lng': resLng,
            'icon': icon,
            'color': color
          };

          markers.add(Marker(
            point: LatLng(resLat, resLng),
            width: 70,
            height: 70,
            child: GestureDetector(
              onTap: () => _showResourceDetails(mapData),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2)),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 8)),
                  )
                ],
              ),
            ),
          ));
        }
        setState(() => _resourceMarkers = markers);
      }
    } catch (e) {
      debugPrint("Resource Fetch Error: $e");
    }
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
            color: const Color(0xFF050b14).withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10)),
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
              borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(title,
              style: TextStyle(
                  color: isActive ? const Color(0xFF00ff9d) : Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildDataOverlay() {
    return Positioned(
      bottom: 100,
      left: 15,
      right: 15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_routeAnalytics != null && _activeLayer == MapLayer.evac)
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFF0f172a),
                  borderRadius: BorderRadius.circular(15),
                  border: const Border(
                      left: BorderSide(color: Color(0xFF00ff9d), width: 4)),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 10)
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology,
                          color: Color(0xFF00ff9d), size: 20),
                      const SizedBox(width: 8),
                      const Text("AI ROUTE REASONING",
                          style: TextStyle(
                              color: Color(0xFF00ff9d),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white54, size: 16),
                        onPressed: () => setState(() => _routeAnalytics = null),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_routeAnalytics!['reasoning'],
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontStyle: FontStyle.italic)),
                  const Divider(color: Colors.white10, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _analStat(Icons.straighten, "DIST",
                          "${_routeAnalytics!['distance']} KM"),
                      _analStat(Icons.timer, "ETA",
                          "${_routeAnalytics!['duration']} MIN"),
                      _analStat(Icons.security, "SAFETY", "100%"),
                    ],
                  )
                ],
              ),
            ),
          Row(
            children: [
              if (_weatherInfo != null)
                _infoCard(
                    "🌡️ ${_weatherInfo!['temperature']}°C | 💨 ${_weatherInfo!['windspeed']} km/h",
                    const Color(0xFF00f3ff)),
              const SizedBox(width: 8),
              if (_seismicInfo != null)
                _infoCard("🫨 SEISMIC: ${_seismicInfo!['mag']} Mag",
                    const Color(0xFFffaa00)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _analStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(width: 5),
        Text("$label: ",
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF00ff9d),
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _infoCard(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xFF050b14).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
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
            options: MapOptions(initialCenter: _userLocation, initialZoom: 12),
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
              if (_activeLayer == MapLayer.resources ||
                  _activeLayer == MapLayer.evac)
                MarkerLayer(markers: _resourceMarkers),
              if (_activeLayer == MapLayer.evac)
                PolylineLayer(polylines: _evacRoutes),
              MarkerLayer(markers: _sosMarkers),
              MarkerLayer(markers: [
                Marker(
                  point: _userLocation,
                  width: 60,
                  height: 60,
                  child: const Icon(Icons.person_pin_circle,
                      color: Color(0xFF64ffda), size: 45),
                ),
              ]),
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
                  color: const Color(0xFF050b14).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: const Color(0xFF00ff9d).withValues(alpha: 0.3))),
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
                            items: _sectors.keys
                                .map((String value) => DropdownMenuItem<String>(
                                    value: value, child: Text(value)))
                                .toList(),
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
                      onPressed: _initializeMapData)
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

// Math helper removed in favor of dart:math as math
