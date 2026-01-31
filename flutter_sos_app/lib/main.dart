import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

const supabaseUrl = 'https://nqipgzknhlfsrezssoyr.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5xaXBnemtuaGxmc3JlenNzb3lyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzNzQ4ODYsImV4cCI6MjA3Mzk1MDg4Nn0.M1xc6HtScdDjemguonpPgmo8EF0A93OoHvy4LACO24E';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const SentinelSOSApp());
}

class SentinelSOSApp extends StatelessWidget {
  const SentinelSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentinel SOS',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00ff9d),
        scaffoldBackgroundColor: const Color(0xFF050b14),
        useMaterial3: true,
        fontFamily: 'Roboto', // Fallback, assume GoogleFonts used inside
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Simple check if "user" is locally stored or not.
  // For this demo, we just check if static user details exist in LoginScreen
  // In a real app, use Supabase Auth or SharedPreferences.
  
  bool _isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? const HomeScreen() : LoginScreen(onLogin: () {
      setState(() {
        _isLoggedIn = true;
      });
    });
  }
}
