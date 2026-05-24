import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_nthu_life/pet_files/pet_data.dart'; // Make sure this path points to your pet_data.dart file

class PetDashboardWidget extends StatefulWidget {
  final int currentCredits;
  const PetDashboardWidget({super.key, required this.currentCredits});

  @override
  State<PetDashboardWidget> createState() => _PetDashboardWidgetState();
}

class _PetDashboardWidgetState extends State<PetDashboardWidget> {
  StreakPet? _currentPet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPetData();
  }

  // 1. Loads the pet from SharedPreferences
  Future<void> _loadPetData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final String? petJson = prefs.getString('user_streak_pet');

    if (petJson != null) {
      final loadedPet = StreakPet.fromJson(Map<String, dynamic>.from(jsonDecode(petJson)));

      if (widget.currentCredits > loadedPet.coins) {
        loadedPet.coins = widget.currentCredits;
        await prefs.setString('user_streak_pet', jsonEncode(loadedPet.toJson()));
      }
      
      setState(() {
        _currentPet = loadedPet;
      });
    }
    setState(() => _isLoading = false);
  }

  // 2. Creates a brand new pet locally
  Future<void> _initializeNewPet(String name) async {
    final newPet = StreakPet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      currentLevel: 1,
      growthPoints: 0,
      currentStreak: 7, // sementara ubah ke 7
      currentStage: 'egg',
      coins: 0
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_streak_pet', jsonEncode(newPet.toJson()));

    setState(() {
      _currentPet = newPet;
    });
  }

  // 3. Simulates gaining EXP and handles leveling up/evolution
  Future<void> _simulateEarnEXP() async {
    if (_currentPet == null) return;

    setState(() {
      // use centralized progression system:
      _currentPet!.completeTaskReward(
        expReward: 20,
        coinReward: 5,
      );
      // debug untuk check apakah exp multiplier dan streak sudah benar
      //print(_currentPet!.currentStreak);
      //print(_currentPet!.expMultiplier);
    });
      /*
      _currentPet!.growthPoints += 20;

      if (_currentPet!.growthPoints >= 100) {
        _currentPet!.currentLevel += 1;
        _currentPet!.growthPoints = 0; // Reset EXP

        // Evolution thresholds
        if (_currentPet!.currentLevel == 2) _currentPet!.currentStage = 'baby';
        if (_currentPet!.currentLevel == 3) _currentPet!.currentStage = 'juvenile';
        if (_currentPet!.currentLevel == 4) _currentPet!.currentStage = 'adult';
      }
    });
    */
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_streak_pet', jsonEncode(_currentPet!.toJson()));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // STATE A: User has no pet yet -> Show Adoption Card
    if (_currentPet == null) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "You don't have a streak pet yet!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Hatch an egg and complete your daily targets in NTHYou to grow your companion.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _initializeNewPet("NTHU Buddy"),
                child: const Text("Hatch My First Egg"),
              ),
            ],
          ),
        ),
      );
    }

    // STATE B: Pet exists -> Draw the stats, progress bar, and test button
    final pet = _currentPet!;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        _getPetAssetPath(pet.currentStage),
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Color(0xFFFFB74D),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${pet.coins}",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10), // tambah ini buat spacing antara coin sm level.
                  ],
                ),
                // Name and Streak Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Lv. ${pet.currentLevel} • ${pet.currentStage.toUpperCase()}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Text(
                            pet.rank,
                            style: TextStyle(
                              color: _getRankColor(pet.rank),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),

                          Text(
                            " • ${pet.title}",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Streak Flame Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "冒 ${pet.currentStreak} Day",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Growth Progress Bar Layout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Growth Progress", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Text("${pet.growthPoints} / 100 EXP", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pet.growthPoints / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 16),

            // Mock Testing Button
            ElevatedButton.icon(
              onPressed: _simulateEarnEXP,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text("Simulate Completing a Habit (+20 EXP)"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                backgroundColor: Colors.green.shade50,
                foregroundColor: Colors.green.shade700,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Bronze':
        return const Color(0xFF8C5A2B);

      case 'Silver':
        return const Color(0xFF6E7C91);

      case 'Gold':
        return const Color(0xFFB38B2D);

      case 'Diamond':
        return const Color(0xFF3AA6A0);

      default:
        return Colors.black87;
    }
  }

  // Returns the emoji representation based on evolution status
  String _getPetAssetPath(String stage) {
    switch (stage) {
      case 'egg': 
        return 'assets/pet/Egg.png';
      case 'baby': 
        return 'assets/pet/Jamil_Tsum_Tinier.png';
      case 'juvenile': 
        return 'assets/pet/Jamil_Tsum_Tiny.png';
      case 'adult': 
        return 'assets/pet/Jamil_Tsum.png';
      default: 
        return 'assets/pet/Jamil_Tsum.png';
    }
  }
}