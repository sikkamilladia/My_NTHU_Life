import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

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

  Future<void> createParty({
    required String partyId,
    required String name,
    required String tag,
    required String creatorID,
    required String description,
  }) async {
    try {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();

      final inviteCode = List.generate(
        6,
        (_) => chars[random.nextInt(chars.length)],
      ).join();

      print("Creating party document...");

      await _firestore.collection('parties').doc(partyId).set({
        'name': name,
        'tag': tag,
        'creatorID': creatorID,
        'memberIDs': [creatorID],
        'description': description,

        // TAMBAHAN BARU
        'inviteCode': inviteCode,
        'totalWeeklyXP': 0,

        'createdAt': FieldValue.serverTimestamp(),
      });

      print("Party created successfully!");
      print("Invite Code: $inviteCode");
    } catch (e) {
      print("Create Party Error: $e");
    }
  }

  Future<Map<String, dynamic>?> getUserParty(String studentID) async {
    try {
      final query = await _firestore
          .collection('parties')
          .where('memberIDs', arrayContains: studentID)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        data['id'] = query.docs.first.id;
        return data;
      }

      return null;
    } catch (e) {
      print("Get Party Error: $e");
      return null;
    }
  }

  Future<bool> joinParty({
    required String inviteCode,
    required String studentID,
  }) async {
    try {
      final existingParty = await _firestore
          .collection('parties')
          .where('memberIDs', arrayContains: studentID)
          .limit(1)
          .get();

      if (existingParty.docs.isNotEmpty) {
        return false;
      }
      final query = await _firestore
          .collection('parties')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return false;
      }

      final doc = query.docs.first;

      final members = List<String>.from(
        doc.data()['memberIDs'] ?? [],
      );

      if (members.contains(studentID)) {
        return true;
      }

      if (members.length >= 6) {
        return false;
      }

      members.add(studentID);

      await doc.reference.update({
        'memberIDs': members,
      });

      return true;
    } catch (e) {
      print("Join Party Error: $e");
      return false;
    }
  }

  Future<void> leaveParty({
    required String studentID,
  }) async {
    try {
      final query = await _firestore
          .collection('parties')
          .where('memberIDs', arrayContains: studentID)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return;

      final doc = query.docs.first;

      final members = List<String>.from(
        doc.data()['memberIDs'] ?? [],
      );

      final creatorID = doc.data()['creatorID'];

      members.remove(studentID);

      if (members.isEmpty) {
        await doc.reference.delete();
      } else {
        if (studentID == creatorID) {
          await doc.reference.update({
            'memberIDs': members,
            'creatorID': members.first,
          });
        } else {
          await doc.reference.update({
            'memberIDs': members,
          });
        }
      }
    } catch (e) {
      print("Leave Party Error: $e");
    }
  }
  
  Future<void> saveAIConfig({
    required String uid,
    required Map<String, dynamic> config,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'ai_config': config,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Firebase Save AI Config Error: $e");
    }
  }

  Future<Map<String, dynamic>?> getAIConfig(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['ai_config'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print("Firebase Get AI Config Error: $e");
    }
    return null;
  }
}
