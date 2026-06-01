import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Uploads or updates a course map entry inside the user's document
  Future<void> saveOrUpdateCourse({
    required String uid,
    required String semesterName,
    required String courseCode,
    required String courseName,
    required String grade,
    required int credits,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'courses': {
          courseCode: {
            'courseName': courseName,
            'semester': semesterName,
            'grade': grade,
            'credits': credits,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));
    } catch (e) {
      print("Firebase Save Error: $e");
    }
  }

  /// Removes a course dynamically from the map using FieldValue.delete()
  Future<void> deleteCourse({required String uid, required String courseCode}) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'courses.$courseCode': FieldValue.delete(),
      });
    } catch (e) {
      print("Firebase Delete Error: $e");
    }
  }

  Future<void> savePetData({
    required String uid,
    required Map<String, dynamic> petJsonMap,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'pet': petJsonMap,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Firebase Save Pet Error: $e");
    }
  }
}
