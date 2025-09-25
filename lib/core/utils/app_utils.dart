import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// app utils basically use for regular expression

class AppUtils {

  static String formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm').format(dateTime);
    } else {
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    }
  }

  static void showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String getChatRoomId(String userId1, String userId2) {
    List<String> users = [userId1, userId2];
    users.sort();
    return '${users[0]}_${users[1]}';
  }

  /// --------------------
  /// Regex utilities
  /// --------------------

  /// Validate email
  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  /// Validate password (at least 6 chars)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Validate username (only letters, numbers, underscore, 3–16 chars)
  static bool isValidUsername(String username) {
    final regex = RegExp(r'^[a-zA-Z0-9_]{3,16}$');
    return regex.hasMatch(username);
  }

  /// Validate phone number (basic, 10–15 digits)
  static bool isValidPhone(String phone) {
    final regex = RegExp(r'^\+?[0-9]{10,15}$');
    return regex.hasMatch(phone);
  }
}
