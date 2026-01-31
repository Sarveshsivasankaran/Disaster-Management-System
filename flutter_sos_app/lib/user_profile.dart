import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  static String name = "";
  static String phone = "";

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_phone', phone);
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString('user_name') ?? "";
    phone = prefs.getString('user_phone') ?? "";
  }

  static bool get isLoggedIn => name.isNotEmpty && phone.isNotEmpty;

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    name = "";
    phone = "";
  }
}
