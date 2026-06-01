import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/pet_files/pet_data.dart';
import 'package:my_nthu_life/services/firestore_services.dart';

class PetDashboardWidget extends StatelessWidget {
  final int currentCredits;
  final String studentID; // Scoped to student ID to prevent multi-account data leakage

  PetDashboardWidget({
    super.key,
    required this.currentCredits,
    required this.studentID,
  });

  // ===== COLOR SCHEME CONFIGURATION =====
  static const purpleMain = Color(0xFF7C3AED);
  static const purpleDark = Color(0xFF6D28D9);

  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _initializeNewPet(String name) async {
    final newPet = StreakPet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      currentLevel: 1,
      growthPoints: 0,
      currentStreak: 1,
      currentStage: 'egg',
      coins: currentCredits, // Seed with their existing accrued credits!
    );

    await _firestoreService.savePetData(uid: studentID, petJsonMap: newPet.toJson());
  }

  Future<void> _simulateEarnEXP(StreakPet activePet) async {
    activePet.completeTaskReward(
      expReward: 20,
      coinReward: 5,
    );
    await _firestoreService.savePetData(uid: studentID, petJsonMap: activePet.toJson());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(studentID).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(color: purpleMain))),
          );
        }

        final userData = snapshot.data?.data() ?? {};
        
        // Return hatching placeholder option card if profile dataset doesn't have a pet map entry
        if (userData['pet'] == null) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "You don't have a streak pet yet!",
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Hatch an egg and complete your daily targets in NTHYou to grow your companion.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purpleMain,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _initializeNewPet("NTHU Buddy"),
                    child: Text("Hatch My First Egg", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        }

        // Reconstruct from nested cloud Firestore payload map instance
        final StreakPet pet = StreakPet.fromJson(Map<String, dynamic>.from(userData['pet']));

        // Auto-sync protection: Adjust rewards balance map seamlessly if credits outpace local coins field
        if (currentCredits > pet.coins) {
          pet.coins = currentCredits;
          _firestoreService.savePetData(uid: studentID, petJsonMap: pet.toJson());
        }

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
                        color: purpleMain.withOpacity(0.12),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pet.name,
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB74D), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                "${pet.coins}",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Lv. ${pet.currentLevel} • ${pet.currentStage.toUpperCase()}",
                            style: GoogleFonts.outfit(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7), fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                _getRankBadgeAsset(pet.rank),
                                width: 18,
                                height: 18,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.shield_rounded, size: 16, color: Colors.grey);
                                },
                              ),
                              const SizedBox(width: 5),
                              Text(
                                pet.rank,
                                style: GoogleFonts.outfit(
                                  color: _getRankColor(pet.rank),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  " • ${pet.title}",
                                  style: GoogleFonts.outfit(
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "🔥 ${pet.currentStreak} Day",
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Growth Progress", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500)),
                    Text("${pet.growthPoints} / 100 EXP", style: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: pet.growthPoints / 100,
                    backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _simulateEarnEXP(pet),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text("Simulate Completing a Habit (+20 EXP)"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green.shade700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Bronze': return const Color(0xFF8C5A2B);
      case 'Silver': return const Color(0xFF6E7C91);
      case 'Gold': return const Color(0xFFB38B2D);
      case 'Diamond': return const Color(0xFF3AA6A0);
      default: return Colors.black87;
    }
  }

  String _getRankBadgeAsset(String rank) {
    switch (rank) {
      case 'Bronze': return 'assets/badge/bronze_badge.png';
      case 'Silver': return 'assets/badge/silver.png';
      case 'Gold': return 'assets/badge/gold_badge.png';
      case 'Diamond': return 'assets/badge/diamond_badge.png';
      default: return 'assets/badge/bronze_badge.png';
    }
  }

  String _getPetAssetPath(String stage) {
    switch (stage) {
      case 'egg': return 'assets/pet/Egg.png';
      case 'baby': return 'assets/pet/baby.png';
      case 'juvenile': return 'assets/pet/juvenile.png';
      case 'adult': return 'assets/pet/adult.png';
      default: return 'assets/pet/adult.png';
    }
  }
}