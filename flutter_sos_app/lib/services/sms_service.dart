import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SmsService {
<<<<<<< HEAD
  // TWILIO CREDENTIALS - Should be provided via environment variables or a secure backend
  // For Flutter, consider using --dart-define or the flutter_dotenv package.
  static const String _accountSid = String.fromEnvironment('TWILIO_ACCOUNT_SID', defaultValue: '');
  static const String _authToken = String.fromEnvironment('TWILIO_AUTH_TOKEN', defaultValue: '');
  static const String _twilioNumber = String.fromEnvironment('TWILIO_PHONE_NUMBER', defaultValue: '');
=======
  // TWILIO CREDENTIALS
  static const String _accountSid = 'ACa7209437c9427fdbce3c43808c22eb43';
  static const String _authToken = 'b0a8a2a1dce1b1b8da5b41b5fb0709f9';
  static const String _twilioNumber = '+16168670252';
>>>>>>> parent of a73e8c8 (Revert "feat: Implement core application UI with home screen, dashboard, bottom navigation, and danger detection system.")

  /// Sends an SMS via Twilio REST API
  /// [phone] should be in E.164 format (e.g., +919361488694)
  static Future<bool> sendSms(String phone, String message) async {
    // Ensure phone is in E.164 format
    String targetPhone = phone.startsWith('+') ? phone : '+$phone';

    final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$_accountSid/Messages.json');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$_accountSid:$_authToken'))}',
        },
        body: {
          'From': _twilioNumber,
          'To': targetPhone,
          'Body': message,
        },
      );

      debugPrint(
          "Twilio HTTP Response: ${response.statusCode} - ${response.body}");
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Twilio API Connection Error: $e");
      return false;
    }
  }

  /// Sends a verification OTP
  static Future<bool> sendOtp(String phone, String code) async {
    final message = 'Your SENTINEL SOS verification code is: $code';
    return sendSms(phone, message);
  }

  /// Sends an emergency SOS alert
  static Future<bool> sendSosAlert({
    required String name,
    required String phone,
    required String description,
    required double latitude,
    required double longitude,
    String? emergencyContact,
  }) async {
    final message = '🆘 EMERGENCY SOS: $name ($phone) needs help!\n'
        'Location: https://www.google.com/maps?q=$latitude,$longitude\n'
        'Description: $description';
    
    // If no emergency contact provided, notify a central number or the user themselves (for testing)
    // In a real app, this would be an admin or a local authority number.
    final target = emergencyContact ?? phone; 
    return sendSms(target, message);
  }
}
