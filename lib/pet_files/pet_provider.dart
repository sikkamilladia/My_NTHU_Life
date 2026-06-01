import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_nthu_life/pet_files/pet_data.dart';
import 'package:my_nthu_life/date_utils.dart'; // Make sure calculateDaysDifference lives here

class PetProvider with ChangeNotifier {
  StreakPet? _currentPet;
  bool _isLoading = true;

  StreakPet? get currentPet => _currentPet;
  bool get isLoading => _isLoading;

  /// Loads pet data directly from Cloud Firestore document
  Future<void> loadPet(String studentID) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(studentID).get();
      
      if (doc.exists && doc.data() != null && doc.data()!['pet'] != null) {
        final Map<String, dynamic> petMap = Map<String, dynamic>.from(doc.data()!['pet']);
        _currentPet = StreakPet.fromJson(petMap);
        
        // Handle consecutive daily streak check matching the system timestamp
        if (doc.data()!['lastLoginDate'] != null) {
          final DateTime lastLogin = (doc.data()!['lastLoginDate'] as Timestamp).toDate();
          _checkAndUpdateStreak(lastLogin, studentID);
        }
      } else {
        _currentPet = null; // Forces "Choose your Egg" state if empty
      }
    } catch (e) {
      print("Error loading pet from Firebase: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _checkAndUpdateStreak(DateTime lastLoginDate, String studentID) {
    if (_currentPet == null) return;

    final today = DateTime.now();
    final daysDifference = calculateDaysDifference(lastLoginDate, today);

    if (daysDifference == 1) {
      _currentPet!.currentStreak += 1;
      savePet(studentID);
    } else if (daysDifference > 1) {
      _currentPet!.currentStreak = 0;
      _currentPet!.currentStage = 'sad_egg';
      savePet(studentID);
    }
  }

  void awardGrowthPoints({required String studentID, required int exp, required int coins}) {
    if (_currentPet == null) return;
    _currentPet!.completeTaskReward(expReward: exp, coinReward: coins);
    savePet(studentID);
  }

  Future<void> savePet(String studentID) async {
    if (_currentPet == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(studentID).set({
        'pet': _currentPet!.toJson(),
        'lastLoginDate': FieldValue.serverTimestamp(), // Firestore safe timestamping mapping
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving pet data to Firestore: $e");
    }
    notifyListeners();
  }
}