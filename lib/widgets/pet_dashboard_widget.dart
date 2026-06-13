import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/pet_files/pet_data.dart';
import 'package:my_nthu_life/services/firestore_services.dart';

class PetDashboardWidget extends StatefulWidget {
  final int currentCredits;
  final String studentID;

  const PetDashboardWidget({
    super.key,
    required this.currentCredits,
    required this.studentID,
  });

  static const purpleMain = Color(0xFF7C3AED);
  static const purpleDark = Color(0xFF6D28D9);

  @override
  State<PetDashboardWidget> createState() => _PetDashboardWidgetState();
}

class _PetDashboardWidgetState extends State<PetDashboardWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  StreakPet? _currentPet;

  String get _todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  final List<Map<String, dynamic>> accessories = [
    {'name': '👓 Cool Glasses', 'price': 20},
    {'name': '🎀 Pink Ribbon', 'price': 25},
    {'name': '🪄 Wizard Hat', 'price': 40},
    {'name': '👑 Golden Crown', 'price': 60},
  ];

  Future<void> _initializeNewPet(String name) async {
    final newPet = StreakPet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      currentLevel: 1,
      growthPoints: 0,
      currentStreak: 1,
      currentStage: 'egg',
      coins: 100,
      ownedAccessories: [],
      equippedAccessory: '',
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentID)
        .set({'pet': newPet.toJson()}, SetOptions(merge: true));

    setState(() => _currentPet = newPet);
  }

  Future<void> _buyAccessory(String itemName, int price) async {
    if (_currentPet == null || _currentPet!.coins < price) return;

    setState(() {
      _currentPet!.coins -= price;
      _currentPet!.ownedAccessories.add(itemName);
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentID)
        .set({'pet': _currentPet!.toJson()}, SetOptions(merge: true));
  }

  Future<void> _equipAccessory(String itemName) async {
    if (_currentPet == null) return;

    setState(() => _currentPet!.equippedAccessory = itemName);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentID)
        .set({'pet': _currentPet!.toJson()}, SetOptions(merge: true));
  }

  void _showAccessoryShop(ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ACCESSORY SHOP",
                style: GoogleFonts.orbitron(
                  color: cs.primaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              ...accessories.map((item) {
                final bool owned = _currentPet!.ownedAccessories.contains(
                  item['name'],
                );
                final bool equipped =
                    _currentPet!.equippedAccessory == item['name'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outlineVariant, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: GoogleFonts.outfit(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on_rounded,
                                  color: Color(0xFFFFB74D),
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${item['price']} coins",
                                  style: GoogleFonts.outfit(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (owned) {
                            _equipAccessory(item['name']);
                          } else {
                            _buyAccessory(item['name'], item['price']);
                          }
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: equipped
                                ? cs.outline.withOpacity(0.2)
                                : cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: owned
                                  ? cs.primaryContainer.withOpacity(0.4)
                                  : cs.outlineVariant,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            equipped ? "EQUIPPED" : (owned ? "EQUIP" : "BUY"),
                            style: GoogleFonts.orbitron(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: equipped
                                  ? cs.outline
                                  : cs.primaryContainer,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showPetHub(ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "PET HUB",
                      style: GoogleFonts.orbitron(
                        color: cs.primaryContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      "LV. ${_currentPet!.currentLevel} • ${_currentPet!.rank}",
                      style: GoogleFonts.orbitron(
                        fontSize: 9,
                        color: cs.outline,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Pet image + name centered
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: cs.surfaceBright,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.primaryContainer.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            _getPetAssetPath(_currentPet!.currentStage),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentPet!.name,
                        style: GoogleFonts.orbitron(
                          color: cs.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: cs.outlineVariant.withOpacity(0.4)),
                const SizedBox(height: 16),

                // Equipped accessory
                Text(
                  "EQUIPPED",
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: cs.outline,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceBright,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outlineVariant, width: 1.2),
                  ),
                  child: Text(
                    _currentPet!.equippedAccessory.isEmpty
                        ? "No accessory equipped"
                        : _currentPet!.equippedAccessory,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: _currentPet!.equippedAccessory.isEmpty
                          ? cs.onSurfaceVariant
                          : cs.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Owned accessories
                Text(
                  "OWNED ACCESSORIES",
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: cs.outline,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceBright,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outlineVariant, width: 1.2),
                  ),
                  child: _currentPet!.ownedAccessories.isEmpty
                      ? Text(
                          "No accessories owned yet",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _currentPet!.ownedAccessories.map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: cs.primaryContainer.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                item,
                                style: GoogleFonts.outfit(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 20),

                // Open shop button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showAccessoryShop(cs);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceBright,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.primaryContainer.withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 15,
                          color: cs.primaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "OPEN ACCESSORY SHOP",
                          style: GoogleFonts.orbitron(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: cs.primaryContainer,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outlineVariant, width: 1.5),
            ),
            child: const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                  color: PetDashboardWidget.purpleMain,
                ),
              ),
            ),
          );
        }

        final userData = snapshot.data?.data() ?? {};

        if (userData['pet'] == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outlineVariant, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "NO COMPANION DETECTED",
                  style: GoogleFonts.orbitron(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: cs.primaryContainer,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Hatch an egg and complete your daily targets to grow your companion.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _initializeNewPet("NTHU Buddy"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceBright,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.primaryContainer.withOpacity(0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      "HATCH FIRST EGG",
                      style: GoogleFonts.orbitron(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: cs.primaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        _currentPet = StreakPet.fromJson(userData['pet']);
        final pet = _currentPet!;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row: label + streak badge ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "COMPANION STATUS",
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: cs.outline,
                      letterSpacing: 2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceBright,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      "🔥 ${pet.currentStreak}d streak",
                      style: GoogleFonts.orbitron(
                        color: Colors.amber.shade400,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Pet identity row ──
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showPetHub(cs),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: cs.surfaceBright,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.primaryContainer.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            _getPetAssetPath(pet.currentStage),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pet.name,
                                style: GoogleFonts.orbitron(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.monetization_on_rounded,
                              color: Color(0xFFFFB74D),
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "${pet.coins}",
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "LV. ${pet.currentLevel} • ${pet.currentStage.toUpperCase()}",
                          style: GoogleFonts.orbitron(
                            fontSize: 9,
                            color: cs.outline,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Image.asset(
                              _getRankBadgeAsset(pet.rank),
                              width: 15,
                              height: 15,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.shield_rounded,
                                size: 14,
                                color: cs.outline,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              pet.rank,
                              style: GoogleFonts.outfit(
                                color: _getRankColor(pet.rank),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                " • ${pet.title}",
                                style: GoogleFonts.outfit(
                                  color: cs.onSurfaceVariant.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Growth bar ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "GROWTH PROGRESS",
                    style: GoogleFonts.orbitron(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: cs.outline,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "${pet.growthPoints} / 100 EXP",
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (pet.growthPoints / 100).clamp(0.0, 1.0),
                  backgroundColor: cs.outlineVariant.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    cs.primaryContainer,
                  ),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 20),

              // ── Divider ──
              Container(height: 1, color: cs.outline.withOpacity(0.4)),
              const SizedBox(height: 16),

              // ── Daily stats label ──
              Text(
                "DAILY STATS",
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: cs.outline,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),

              // ── Stats chips ──
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.studentID)
                    .collection('tasks')
                    .snapshots(),
                builder: (context, taskSnap) {
                  final docs = taskSnap.data?.docs ?? [];
                  final todayCount = docs
                      .where((d) => d.data()['assignedDayString'] == _todayKey)
                      .length;
                  final totalCount = docs.length;
                  final streak = pet.currentStreak;

                  return Row(
                    children: [
                      _buildStatChip(
                        cs: cs,
                        label: 'TODAY',
                        value: '$todayCount',
                        unit: 'quests',
                        color: cs.primaryContainer,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        cs: cs,
                        label: 'PENDING',
                        value: '$totalCount',
                        unit: 'total',
                        color: const Color(0xFF00CEC9),
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        cs: cs,
                        label: 'STREAK',
                        value: '$streak',
                        unit: 'days',
                        color: const Color(0xFFFFD700),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // ── Accessory shop button ──
              GestureDetector(
                onTap: () => _showAccessoryShop(cs),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: cs.outline,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.primaryContainer.withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 15,
                        color: cs.onPrimary,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        "ACCESSORY SHOP",
                        style: GoogleFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip({
    required ColorScheme cs,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: 8,
                color: cs.outline,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: cs.onSurfaceVariant,
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

  String _getRankBadgeAsset(String rank) {
    switch (rank) {
      case 'Bronze':
        return 'assets/badge/bronze_badge.png';
      case 'Silver':
        return 'assets/badge/silver.png';
      case 'Gold':
        return 'assets/badge/gold_badge.png';
      case 'Diamond':
        return 'assets/badge/diamond_badge.png';
      default:
        return 'assets/badge/bronze_badge.png';
    }
  }

  String _getPetAssetPath(String stage) {
    switch (stage) {
      case 'egg':
        return 'assets/pet/Egg.png';
      case 'baby':
        return 'assets/pet/baby.png';
      case 'juvenile':
        return 'assets/pet/juvenile.png';
      case 'adult':
        return 'assets/pet/adult.png';
      default:
        return 'assets/pet/adult.png';
    }
  }
}
