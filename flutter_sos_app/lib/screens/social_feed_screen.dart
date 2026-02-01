import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final _stream = Supabase.instance.client
      .from('alerts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050b14),
      appBar: AppBar(
        title: const Text("LIVE NEWS FEED", style: TextStyle(color: Color(0xFF00ff9d), letterSpacing: 2, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white70),
            onPressed: () {},
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00ff9d)));
          }
          final alerts = snapshot.data!;
          
          if (alerts.isEmpty) {
            return const Center(child: Text("No active alerts", style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _buildSocialCard(alert);
            },
          );
        },
      ),
    );
  }

  Widget _buildSocialCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] ?? 'info';
    final source = alert['source'] ?? 'Unknown Source';
    final isVerified = alert['verified'] ?? false;
    final timeStr = alert['created_at'] != null 
        ? DateFormat('hh:mm a').format(DateTime.parse(alert['created_at']).toLocal()) 
        : 'Just now';

    Color cardColor;
    IconData icon;

    switch (severity) {
      case 'critical':
        cardColor = const Color(0xFFff2a2a);
        icon = Icons.warning_amber_rounded;
        break;
      case 'warning':
        cardColor = const Color(0xFFffaa00);
        icon = Icons.error_outline;
        break;
      default:
        cardColor = const Color(0xFF2979ff);
        icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white10,
                  radius: 18,
                  child: Icon(icon, color: cardColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(source.toString().toUpperCase(), 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Colors.blue, size: 14)
                          ]
                        ],
                      ),
                      Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: cardColor.withOpacity(0.5))
                  ),
                  child: Text(severity.toString().toUpperCase(), style: TextStyle(color: cardColor, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          
          // Image / Map placeholder (Simulate media)
          Container(
            height: 150,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.black26,
              image: DecorationImage(
                image: NetworkImage("https://www.transparenttextures.com/patterns/diagmonds-light.png"), // Placeholder pattern
                fit: BoxFit.cover,
                opacity: 0.2
              )
            ),
            child: Center(
              child: Icon(Icons.image, color: Colors.white12, size: 48),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert['title'] ?? 'Alert', 
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.3)),
                const SizedBox(height: 8),
                Text(alert['message'] ?? '', 
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
              ],
            ),
          ),

          // Footer Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white12))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.favorite_border, color: Colors.white54, size: 20),
                    SizedBox(width: 20),
                    Icon(Icons.share, color: Colors.white54, size: 20),
                  ],
                ),
                Icon(Icons.bookmark_border, color: Colors.white54, size: 20),
              ],
            ),
          )
        ],
      ),
    );
  }
}
