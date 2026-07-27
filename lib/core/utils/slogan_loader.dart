import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class SloganLoader {
  static String _slogan = 'KogutopediA: Pamiętnik z życia drobiu';

  static String get slogan => _slogan;

  static Future<void> load() async {
    try {
      final text = await rootBundle.loadString('assets/slogan.txt');
      _slogan = text.trim();
    } catch (e) {
      debugPrint('SloganLoader.load error: $e');
    }
  }
}
