import 'dart:convert';
import 'package:crypto/crypto.dart';

class StringUtil {
  static String capitalize(String input) {
    if (input.isEmpty) return input;
    return '${input[0].toUpperCase()}${input.substring(1)}';
  }

  static String snakeToCapitalized(String input) {
    return input.split('_').map((word) => capitalize(word)).join(' ');
  }

  static String hashPassword(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
