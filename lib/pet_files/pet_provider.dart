import 'package:my_nthu_life/pet_files/pet_data.dart';
import 'dart:convert'; // Required for jsonEncode and jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_nthu_life/date_utils.dart'; // We will define this helper next

class PetProvider with ChangeNotifier {
  StreakPet? _currentPet;
  bool _isLoading = true;

  StreakPet? get currentPet => _currentPet;
  bool get isLoading => _isLoading;

  // 1. Load the pet data as soon as the app/feature starts
  Future<void> loadPet(String studentID) async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    //Scope keys to the unique student ID
    final String petKey = 'user_streak_pet$studentID';
    final String loginKey = 'last_app_login_date_$studentID';
    
    // bug: loadpet masih pakae old key, jd ku ganti
    final String? petJson = prefs.getString(petKey); // final String? petJson = prefs.getString('user_streak_pet');
    final String? lastLoginStr = prefs.getString(loginKey); // final String? lastLoginStr = prefs.getString('last_app_login_date');

    if (petJson == null) {// "Choose your Egg" screen
      _currentPet = null;
    } else {
      // A pet exists, decode it
      _currentPet = StreakPet.fromJson(Map<String, dynamic>.from(jsonDecode(petJson)));
      
      // 2. Check and update the streak based on the last login time
      if (lastLoginStr != null) {
        _checkAndUpdateStreak(DateTime.parse(lastLoginStr), studentID);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // 2. The core logic: checking the daily streak
  void _checkAndUpdateStreak(DateTime lastLoginDate, String studentID) {
    if (_currentPet == null) return;

    final today = DateTime.now();
    final daysDifference = calculateDaysDifference(lastLoginDate, today);

    /*if (daysDifference == 1) { //Kalo difference day cmn 1, itu berarti consecutive days cmn beda sehari
    } else if (daysDifference > 1) {
      _currentPet!.currentStreak = 0;
      _currentPet!.currentStage = 'sad_egg';
      savePet(studentID);
    }*/
    if (daysDifference == 1) {

      // consecutive login
      _currentPet!.currentStreak += 1;

      savePet(studentID);

    } else if (daysDifference > 1) {

      // streak broken
      _currentPet!.currentStreak = 0;
      _currentPet!.currentStage = 'sad_egg';

      savePet(studentID);
    }
  }

  // 3. Award experience/growth points when they complete an action in NTHYou
  void awardGrowthPoints({required String studentID, required int exp, required int coins}) {
    // bug: ini td ada duplikat, jd aku hapus salah satu
    if (_currentPet == null) return;

    // Main reward logic
    _currentPet!.completeTaskReward(
      expReward: exp,
      coinReward: coins,
    );

    savePet(studentID);
  }

  // 4. Save the pet state to local storage
  Future<void> savePet(String studentID) async {
    if (_currentPet == null) return;

    final prefs = await SharedPreferences.getInstance();
    final petJson = jsonEncode(_currentPet!.toJson());
    
    // bug: savepet masih pakai old key, jd ku ganti
    final String petKey = 'user_streak_pet$studentID';
    final String loginKey = 'last_app_login_date_$studentID';
    
    await prefs.setString(petKey, petJson);
    await prefs.setString(loginKey, DateTime.now().toIso8601String());
    
    notifyListeners(); // Tell the UI to redraw with the new data
  }
}