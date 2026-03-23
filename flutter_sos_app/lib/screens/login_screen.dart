import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_profile.dart';
import '../services/sms_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;
  bool _isDemoMode = false;
  String _manualOTP = ""; // Store locally generated OTP

  // --- DYNAMIC OTP GENERATION & SMS SENDING ---
  Future<void> _sendOTP() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      _showSnack("Please enter Name and Phone Number");
      return;
    }

    String phone = _phoneController.text.trim();
    setState(() => _isLoading = true);

    try {
      // 1. Generate a Dynamic 6-digit OTP
      _manualOTP = (100000 + Random().nextInt(900000)).toString();
      debugPrint("SYSTEM: Generated OTP for $phone is $_manualOTP");

      // 2. Trigger SMS Gateway via Centralized Service
      bool smsSent = await SmsService.sendOtp(phone, _manualOTP);

      if (smsSent) {
        setState(() {
          _otpSent = true;
          _isDemoMode = false;
        });
        _showSnack("OTP Code broadcasting to $phone...");
      } else {
        // Fallback to Test Mode if SMS fails (e.g. no API key)
        throw Exception("SMS Gateway unreachable");
      }
    } catch (e) {
      debugPrint("OTP Broadcast Failed: $e");
      setState(() {
        _otpSent = true;
        _isDemoMode = true;
      });
      _showSnack("SMS Gateway Error. Entering TEST MODE (Code: 123456)");
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      _showSnack("Please enter the OTP");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String entered = _otpController.text.trim();

      if (_isDemoMode) {
        // Mock Verification
        if (entered == "123456" || entered == "000000") {
          await _finalizeLogin();
        } else {
          _showSnack("Invalid Test OTP. Use 123456");
        }
      } else {
        // Verify against our Dynamically Generated Code
        if (entered == _manualOTP) {
          await _finalizeLogin();
        } else {
          _showSnack("Invalid Verification Code. Please try again.");
        }
      }
    } catch (e) {
      _showSnack("Verification failed: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _finalizeLogin() async {
    // 1. Save to UserProfile (Local)
    UserProfile.name = _nameController.text;
    UserProfile.phone = _phoneController.text.trim();
    await UserProfile.save();

    // 2. Sync with custom 'mobile_users' table
    try {
      await Supabase.instance.client.from('mobile_users').upsert({
        'phone': UserProfile.phone,
        'name': UserProfile.name,
        'last_login': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Supabase profile sync error: $e");
    }

    widget.onLogin();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF050b14), Color(0xFF0f172a)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield, size: 100, color: Color(0xFF00ff9d)),
                const SizedBox(height: 10),
                const Text(
                  "SENTINEL SOS",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Color(0xFF00ff9d),
                  ),
                ),
                Text(
                  _isDemoMode ? "TESTING INTERFACE" : "SECURE AUTHENTICATION",
                  style: TextStyle(
                      color: _isDemoMode ? Colors.amber : Colors.white54,
                      letterSpacing: 2,
                      fontSize: 12),
                ),
                const SizedBox(height: 50),
                if (!_otpSent) ...[
                  _buildTextField(_nameController, "FULL NAME", Icons.person),
                  const SizedBox(height: 20),
                  _buildTextField(
                      _phoneController, "MOBILE NUMBER", Icons.phone,
                      keyboard: TextInputType.phone),
                ] else ...[
                  Text(
                      _isDemoMode
                          ? "ENTER TEST CODE (123456)"
                          : "ENTER VERIFICATION CODE",
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  _buildTextField(_otpController, "OTP CODE", Icons.lock,
                      keyboard: TextInputType.number),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isDemoMode ? Colors.amber : const Color(0xFF00ff9d),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(_otpSent ? "VERIFY & LOGIN" : "GET OTP",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                if (_otpSent)
                  TextButton(
                    onPressed: () => setState(() {
                      _otpSent = false;
                      _isDemoMode = false;
                    }),
                    child: const Text("CHANGE DETAILS",
                        style: TextStyle(color: Colors.grey)),
                  ),
                const SizedBox(height: 20),
                Text(
                  _isDemoMode
                      ? "SMS Gateway is not active. Using internal validation."
                      : "Verifying your identity ensures rescue ops are accurately assigned to your profile.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon,
            color: _isDemoMode ? Colors.amber : const Color(0xFF00ff9d)),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white12),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: _isDemoMode ? Colors.amber : const Color(0xFF00ff9d)),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05), // Fixed withValues
      ),
    );
  }
}
