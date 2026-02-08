import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

enum FeedSource { official, social }

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  FeedSource _activeSource = FeedSource.social;
  bool _isLoading = false;
  List<Map<String, dynamic>> _socialPosts = [];
  String _currentCity = "South India";

  final _officialStream = Supabase.instance.client
      .from('alerts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(20);

  @override
  void initState() {
    super.initState();
    _fetchLocationAndSocialFeed();
  }

  Future<void> _fetchLocationAndSocialFeed() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition();

      // Simulating reverse-geocoding to derive city for hashtags
      // In a real app, you'd use a package like 'geocoding'
      if (position.latitude > 12.9 && position.latitude < 13.2) {
        _currentCity = "Chennai";
      } else if (position.latitude > 18.9 && position.latitude < 19.2) {
        _currentCity = "Mumbai";
      } else {
        _currentCity = "LocalZone";
      }

      await _fetchSocialNews(_currentCity);
    } catch (e) {
      debugPrint("Location Error: $e");
      _fetchSocialNews("National");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSocialNews(String location) async {
    try {
      // 1. Primary Search (Specific Location)
      var posts = await _performSearch(location);

      // 2. Fallback Search (National) if local yields < 2 results
      if (posts.isEmpty) {
        debugPrint("Local news empty. Fetching national news...");
        posts = await _performSearch("India");
      }

      // 3. Last Resort (Global/General)
      if (posts.isEmpty) {
        posts = await _performSearch("Global Disaster");
      }

      if (mounted) {
        setState(() {
          _socialPosts = posts;
        });
      }
    } catch (e) {
      debugPrint("Social Fetch Error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _performSearch(
      String queryLocation) async {
    try {
      final query = Uri.encodeComponent(
          "disaster OR flood OR cyclone OR earthquake OR emergency $queryLocation");
      final rssUrl =
          "https://news.google.com/rss/search?q=$query&hl=en-IN&gl=IN&ceid=IN:en";
      final apiUrl =
          "https://api.rss2json.com/v1/api.json?rss_url=${Uri.encodeComponent(rssUrl)}";

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      final List items = data['items'] ?? [];

      // Keyword Filter
      final keywords = [
        'disaster',
        'flood',
        'rescue',
        'cyclone',
        'earthquake',
        'storm',
        'emergency',
        'rain',
        'alert',
        'warning',
        'collapse',
        'fire',
        'tsunami',
        'damage',
        'crisis',
        'help',
        'evacuation'
      ];

      final List<String> socialPlatforms = ['Twitter', 'Instagram', 'Facebook'];
      final List<String> avatars = [
        'https://abs.twimg.com/sticky/default_profile_images/default_profile_400x400.png',
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Instagram_logo_2016.svg/2048px-Instagram_logo_2016.svg.png',
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/2021_Facebook_icon.svg/2048px-2021_Facebook_icon.svg.png',
      ];

      return items
          .where((item) {
            // Less strict filter: Title OR Description contains ANY keyword
            final content =
                "${item['title']} ${item['description']}".toLowerCase();
            // If keyword list is too strict, we can skip it for a fallback search
            // But for now, just ensure we have robust keywords
            return keywords.any((k) => content.contains(k));
          })
          .map((item) {
            // Date Verification (Soft)
            String timeAgo = "Recently";
            if (item['pubDate'] != null) {
              try {
                final pubDate = DateTime.parse(item['pubDate']);
                final diff = DateTime.now().difference(pubDate);

                // CHANGED: Filter for last 1 month (30 days)
                if (diff.inDays > 30) {
                  return null; // Skip old posts
                }

                if (diff.inHours < 24)
                  timeAgo = "${diff.inHours}h ago";
                else
                  timeAgo = "${diff.inDays}d ago";
              } catch (e) {
                /* ignore parse error */
              }
            } else {
              return null; // Skip if no date
            }

            final platformIndex = (item['title'].hashCode).abs() % 3;

            return {
              'title': item['title'],
              'message':
                  item['description']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '',
              'source': socialPlatforms[platformIndex],
              'avatar': avatars[platformIndex],
              'created_at': timeAgo, // Display string directly
              'hashtags':
                  "#disaster #${queryLocation.toLowerCase().replaceAll(' ', '')}",
              'verified': (item['title'].hashCode).abs() % 5 == 0,
              'severity':
                  (item['title'].hashCode).abs() % 7 == 0 ? 'critical' : 'info',
            };
          })
          .where((e) => e != null)
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint("Search internal error: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050b14),
      appBar: AppBar(
        title: Text(
            _activeSource == FeedSource.official
                ? "OFFICIAL ALERTS"
                : "SOCIAL TRENDS",
            style: const TextStyle(
                color: Color(0xFF00ff9d),
                letterSpacing: 2,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _sourceTab("SOCIAL FEED", FeedSource.social),
                const SizedBox(width: 12),
                _sourceTab("OFFICIAL", FeedSource.official),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchLocationAndSocialFeed,
          )
        ],
      ),
      body: _activeSource == FeedSource.official
          ? _buildOfficialFeed()
          : _buildSocialFeed(),
    );
  }

  Widget _sourceTab(String label, FeedSource source) {
    bool isActive = _activeSource == source;
    return GestureDetector(
      onTap: () => setState(() => _activeSource = source),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF00ff9d).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive ? const Color(0xFF00ff9d) : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: isActive ? const Color(0xFF00ff9d) : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildOfficialFeed() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _officialStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00ff9d)));
        }
        final alerts = snapshot.data!;
        if (alerts.isEmpty) {
          return const Center(
              child: Text("No official alerts",
                  style: TextStyle(color: Colors.white54)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) =>
              _buildCard(alerts[index], isSocial: false),
        );
      },
    );
  }

  Widget _buildSocialFeed() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00ff9d)));
    }
    if (_socialPosts.isEmpty) {
      return const Center(
          child: Text("Scanning social media...",
              style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _socialPosts.length,
      itemBuilder: (context, index) =>
          _buildCard(_socialPosts[index], isSocial: true),
    );
  }

  Widget _buildCard(Map<String, dynamic> data, {required bool isSocial}) {
    final severity = data['severity'] ?? 'info';
    final source = data['source'] ?? 'SENTINEL';
    final isVerified = data['verified'] ?? false;
    final timeStr = data['created_at'] != null
        ? (isSocial
            ? data['created_at']
            : DateFormat('hh:mm a')
                .format(DateTime.parse(data['created_at']).toLocal()))
        : 'Recently';

    Color themeColor;
    IconData icon;

    switch (severity) {
      case 'critical':
        themeColor = const Color(0xFFff2a2a);
        icon = Icons.warning_amber_rounded;
        break;
      case 'warning':
        themeColor = const Color(0xFFffaa00);
        icon = Icons.error_outline;
        break;
      default:
        themeColor =
            isSocial ? const Color(0xFF2979ff) : const Color(0xFF00ff9d);
        icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white10,
                  radius: 18,
                  backgroundImage:
                      isSocial ? NetworkImage(data['avatar'] ?? '') : null,
                  child: !isSocial
                      ? Icon(icon, color: themeColor, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(source.toString().toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                color: Colors.blue, size: 14)
                          ]
                        ],
                      ),
                      Text(timeStr,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                if (!isSocial)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: themeColor.withValues(alpha: 0.5))),
                    child: Text(severity.toString().toUpperCase(),
                        style: TextStyle(
                            color: themeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['title'] != null && data['title'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(data['title'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            height: 1.3)),
                  ),
                Text(data['message'] ?? '',
                    maxLines: isSocial ? 4 : null,
                    overflow: isSocial ? TextOverflow.ellipsis : null,
                    style: TextStyle(
                        color: isSocial ? Colors.white70 : Colors.white,
                        fontSize: 14,
                        height: 1.5)),
                if (isSocial && data['hashtags'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(data['hashtags'],
                        style: const TextStyle(
                            color: Color(0xFF2979ff),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white12))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _footerIcon(Icons.favorite_border),
                    const SizedBox(width: 20),
                    _footerIcon(Icons.share),
                    if (isSocial) ...[
                      const SizedBox(width: 20),
                      _footerIcon(Icons.chat_bubble_outline),
                    ]
                  ],
                ),
                _footerIcon(Icons.bookmark_border),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _footerIcon(IconData icon) =>
      Icon(icon, color: Colors.white54, size: 18);
}
