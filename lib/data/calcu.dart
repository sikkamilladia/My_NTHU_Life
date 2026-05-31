import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ─────────────────────────────────────────────
//  GPA STORAGE  (persists courses + components)
// ─────────────────────────────────────────────

class GpaStorage {
  static const _key = 'gpa_calculator_courses';

  /// Save the full course list to SharedPreferences.
  static Future<void> saveCourses(List<Map<String, dynamic>> courses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(courses));
  }

  /// Load the course list from SharedPreferences.
  /// Returns an empty list if nothing is saved yet.
  static Future<List<Map<String, dynamic>>> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Clear all saved GPA data.
  static Future<void> clearCourses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ─────────────────────────────────────────────
//  SERIALISATION HELPERS
//  (call these from gpa_calculator.dart)
// ─────────────────────────────────────────────

/// Convert a CourseComponent to a plain Map for storage.
Map<String, dynamic> componentToJson(
  String name,
  double weight,
  double? score,
) {
  return {'name': name, 'weight': weight, if (score != null) 'score': score};
}

/// Convert a Course (name + component list) to a plain Map for storage.
Map<String, dynamic> courseToJson(
  String name,
  List<Map<String, dynamic>> components,
) {
  return {'name': name, 'components': components};
}
