import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _pinKey = 'app_pin';
  static const String _securityQuestionKey = 'security_question';
  static const String _securityAnswerKey = 'security_answer';
  static const String _lastActiveKey = 'last_active_time';
  static const String _isFirstTimeKey = 'is_first_time';
  static const String _defaultPin = '1234';

  static const Duration _sessionTimeout = Duration(minutes: 5);

  // Check if this is first time launching the app
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_isFirstTimeKey) ||
        prefs.getBool(_isFirstTimeKey) == true;
  }

  // Mark first time setup as complete
  static Future<void> completeFirstTimeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstTimeKey, false);
  }

  // Set PIN for the first time
  static Future<bool> setPin(String pin) async {
    if (pin.length < 4 || pin.length > 6) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinKey, _encodePin(pin));
      await completeFirstTimeSetup();
      return true;
    } catch (e) {
      debugPrint('Error setting PIN: $e');
      return false;
    }
  }

  // Change existing PIN
  static Future<bool> changePin(String oldPin, String newPin) async {
    if (newPin.length < 4 || newPin.length > 6) return false;

    try {
      final isValidOldPin = await validatePin(oldPin);
      if (!isValidOldPin) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinKey, _encodePin(newPin));
      return true;
    } catch (e) {
      debugPrint('Error changing PIN: $e');
      return false;
    }
  }

  // Validate PIN
  static Future<bool> validatePin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedEncodedPin = prefs.getString(_pinKey);

      if (storedEncodedPin == null) {
        // First time, use default PIN
        return pin == _defaultPin;
      }

      final String decodedPin = _decodePin(storedEncodedPin);
      return pin == decodedPin;
    } catch (e) {
      debugPrint('Error validating PIN: $e');
      return false;
    }
  }

  // Check if session is still valid
  static Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? lastActive = prefs.getInt(_lastActiveKey);

      // For first-time use, consider session valid
      if (lastActive == null) return false;

      final DateTime lastActiveTime =
          DateTime.fromMillisecondsSinceEpoch(lastActive);
      final DateTime now = DateTime.now();

      return now.difference(lastActiveTime) < _sessionTimeout;
    } catch (e) {
      debugPrint('Error checking session validity: $e');
      return false;
    }
  }

  // Update last active time
  static Future<void> updateLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating last active time: $e');
    }
  }

  // Clear session (force logout)
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastActiveKey);
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }

  // Set security question and answer
  static Future<bool> setSecurityQuestion(
      String question, String answer) async {
    if (question.isEmpty || answer.isEmpty) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_securityQuestionKey, question);
      await prefs.setString(_securityAnswerKey, _encodeAnswer(answer));
      return true;
    } catch (e) {
      debugPrint('Error setting security question: $e');
      return false;
    }
  }

  // Get security question
  static Future<String?> getSecurityQuestion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_securityQuestionKey);
    } catch (e) {
      debugPrint('Error getting security question: $e');
      return null;
    }
  }

  // Validate security answer
  static Future<bool> validateSecurityAnswer(String answer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedEncodedAnswer = prefs.getString(_securityAnswerKey);

      if (storedEncodedAnswer == null) return false;

      final String decodedAnswer = _decodeAnswer(storedEncodedAnswer);
      return answer.toLowerCase().trim() == decodedAnswer.toLowerCase().trim();
    } catch (e) {
      debugPrint('Error validating security answer: $e');
      return false;
    }
  }

  // Reset PIN using security question
  static Future<bool> resetPin(String newPin) async {
    if (newPin.length < 4 || newPin.length > 6) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinKey, _encodePin(newPin));
      await clearSession(); // Force re-login with new PIN
      return true;
    } catch (e) {
      debugPrint('Error resetting PIN: $e');
      return false;
    }
  }

  // Simple encoding for PIN (basic obfuscation)
  static String _encodePin(String pin) {
    final bytes = utf8.encode(pin);
    final encoded = base64.encode(bytes);
    return encoded.split('').reversed.join('');
  }

  // Decode PIN
  static String _decodePin(String encodedPin) {
    final reversed = encodedPin.split('').reversed.join('');
    final bytes = base64.decode(reversed);
    return utf8.decode(bytes);
  }

  // Simple encoding for security answer
  static String _encodeAnswer(String answer) {
    final bytes = utf8.encode(answer.toLowerCase().trim());
    final encoded = base64.encode(bytes);
    return encoded.split('').reversed.join('');
  }

  // Decode security answer
  static String _decodeAnswer(String encodedAnswer) {
    final reversed = encodedAnswer.split('').reversed.join('');
    final bytes = base64.decode(reversed);
    return utf8.decode(bytes);
  }

  // Check if PIN is set (for first-time setup detection)
  static Future<bool> isPinSet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_pinKey);
    } catch (e) {
      debugPrint('Error checking if PIN is set: $e');
      return false;
    }
  }

  // Get available security questions
  static List<String> getSecurityQuestions() {
    return [
      'What was your childhood nickname?',
      'What is the name of your first pet?',
      'What elementary school did you attend?',
      'What is your mother\'s maiden name?',
      'What city were you born in?',
      'What is your favorite food?',
    ];
  }
}
