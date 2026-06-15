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

  /// Finds other students who are taking the same courses as the current user
  Future<List<Map<String, dynamic>>> getClassmateRecommendations(
    String uid,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return [];

      final userData = userDoc.data()!;
      final userCourses = Map<String, dynamic>.from(userData['courses'] ?? {});
      final userCourseCodes = userCourses.keys.toSet();
      
      final friends = List<String>.from(userData['friends'] ?? []);
      final sentRequests = List<Map<String, dynamic>>.from(userData['requests_sent'] ?? []);
      final sentUids = sentRequests.map((r) => r['toUid'] as String).toSet();

      if (userCourseCodes.isEmpty) return [];

      final allUsers = await _firestore.collection('users').get();
      List<Map<String, dynamic>> recommendations = [];

      for (var doc in allUsers.docs) {
        if (doc.id == uid) continue;

        final data = doc.data();
        final otherCourses = Map<String, dynamic>.from(data['courses'] ?? {});
        final otherCourseCodes = otherCourses.keys.toSet();

        final shared = userCourseCodes.intersection(otherCourseCodes);
        if (shared.isNotEmpty) {
          recommendations.add({
            'uid': doc.id,
            'sharedCourses': shared.toList(),
            'name': doc.id,
            'isFriend': friends.contains(doc.id),
            'requestSent': sentUids.contains(doc.id),
          });
        }
      }

      return recommendations;
    } catch (e) {
      print("Get Recommendations Error: $e");
      return [];
    }
  }

  Future<void> unfriendUser({
    required String uid,
    required String friendUid,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'friends': FieldValue.arrayRemove([friendUid]),
      });
      await _firestore.collection('users').doc(friendUid).update({
        'friends': FieldValue.arrayRemove([uid]),
      });
    } catch (e) {
      print("Unfriend Error: $e");
    }
  }

  Future<void> sendSocialRequest({
    required String fromUid,
    required String toUid,
    required String type, // 'friend' or 'party'
    String? partyId,
    String? partyName,
  }) async {
    try {
      // 1. Add to recipient's incoming requests
      await _firestore.collection('users').doc(toUid).update({
        'requests': FieldValue.arrayUnion([
          {
            'fromUid': fromUid,
            'type': type,
            'partyId': partyId,
            'partyName': partyName,
            'timestamp': Timestamp.now(),
            'status': 'pending',
          }
        ])
      });
      
      // 2. Add to sender's outgoing requests to prevent duplicates
      await _firestore.collection('users').doc(fromUid).update({
        'requests_sent': FieldValue.arrayUnion([
          {
            'toUid': toUid,
            'type': type,
            'timestamp': Timestamp.now(),
          }
        ])
      });
    } catch (e) {
      // Create fields if they don't exist
      await _firestore.collection('users').doc(toUid).set({
        'requests': [
          {
            'fromUid': fromUid,
            'type': type,
            'partyId': partyId,
            'partyName': partyName,
            'timestamp': Timestamp.now(),
            'status': 'pending',
          }
        ]
      }, SetOptions(merge: true));
      
      await _firestore.collection('users').doc(fromUid).set({
        'requests_sent': [
          {
            'toUid': toUid,
            'type': type,
            'timestamp': Timestamp.now(),
          }
        ]
      }, SetOptions(merge: true));
    }
  }

  Future<void> respondToRequest({
    required String uid,
    required Map<String, dynamic> request,
    required bool accept,
  }) async {
    try {
      // 1. Remove from recipient's requests
      await _firestore.collection('users').doc(uid).update({
        'requests': FieldValue.arrayRemove([request]),
      });
      
      // 2. Remove from sender's requests_sent
      final senderUid = request['fromUid'];
      final senderDoc = await _firestore.collection('users').doc(senderUid).get();
      if (senderDoc.exists) {
        final sent = List<Map<String, dynamic>>.from(senderDoc.data()?['requests_sent'] ?? []);
        final toRemove = sent.where((r) => r['toUid'] == uid && r['type'] == request['type']).toList();
        if (toRemove.isNotEmpty) {
          await _firestore.collection('users').doc(senderUid).update({
            'requests_sent': FieldValue.arrayRemove(toRemove),
          });
        }
      }

      if (accept) {
        if (request['type'] == 'friend') {
          // 1. Add to friends list for both
          await _firestore.collection('users').doc(uid).update({
            'friends': FieldValue.arrayUnion([request['fromUid']]),
            'requests_history': FieldValue.arrayUnion([request]),
          });
          await _firestore.collection('users').doc(request['fromUid']).update({
            'friends': FieldValue.arrayUnion([uid]),
          });

          // AUTO-JOIN PARTY Logic:
          // A. If the request explicitly included a partyId (Friend + Party flow)
          if (request['partyId'] != null) {
            await joinParty(
              studentID: uid,
              explicitPartyId: request['partyId'],
            );
          }

          // B. If the acceptor (current user) has a party, have the sender join it
          final myParty = await getUserParty(uid);
          if (myParty != null) {
            await joinParty(
              studentID: request['fromUid'],
              explicitPartyId: myParty['id'],
            );
          }

          // C. Fallback: If the sender has a party, have the acceptor join it
          final senderParty = await getUserParty(request['fromUid']);
          if (senderParty != null) {
            await joinParty(
              studentID: uid,
              explicitPartyId: senderParty['id'],
            );
          }
        } else if (request['type'] == 'party') {
          // Join the party
          await joinParty(
            inviteCode: '', // Not used for direct invites if we use partyId
            studentID: uid,
            explicitPartyId: request['partyId'],
          );
        }
      }
    } catch (e) {
      print("Respond to Request Error: $e");
    }
  }

  /// Modified joinParty to support explicit party ID
  Future<bool> joinParty({
    String? inviteCode,
    required String studentID,
    String? explicitPartyId,
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

      DocumentSnapshot? doc;

      if (explicitPartyId != null) {
        doc = await _firestore.collection('parties').doc(explicitPartyId).get();
      } else if (inviteCode != null) {
        final query = await _firestore
            .collection('parties')
            .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) doc = query.docs.first;
      }

      if (doc == null || !doc.exists) {
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final members = List<String>.from(data['memberIDs'] ?? []);

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
}
