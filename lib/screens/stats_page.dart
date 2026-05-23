import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_nthu_life/main.dart';
import 'package:my_nthu_life/pet_files/pet_data.dart';

class StatsPage extends StatefulWidget {
  final String studentID;

  const StatsPage({super.key, required this.studentID});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  StreakPet? _pet;
  bool _isLoading = true;

  // Local state for purchased items
  String _equippedBorder = "None";
  List<String> _unlockedBorders = ["None"];

  // Shop Catalog
  final List<Map<String, dynamic>> _shopItems = [
    {"name": "None", "cost": 0, "previewColor": Colors.transparent},
    {"name": "Purple Haze", "cost": 15, "previewColor": Colors.purple},
    {"name": "Gold Scholar", "cost": 35, "previewColor": Colors.amber},
    {
      "name": "NTHU Violet",
      "cost": 50,
      "previewColor": Colors.deepPurpleAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStatsAndShop();
  }

  Future<void> _loadStatsAndShop() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Pet Data
    final String? petJson = prefs.getString('user_streak_pet');
    if (petJson != null) {
      _pet = StreakPet.fromJson(Map<String, dynamic>.from(jsonDecode(petJson)));
    }

    // 2. Load Shop / Customization data
    _equippedBorder =
        prefs.getString('equipped_border_${widget.studentID}') ?? "None";
    _unlockedBorders =
        prefs.getStringList('unlocked_borders_${widget.studentID}') ?? ["None"];

    // Reward Free Border implicitly if pet level milestones are met
    if (_pet != null &&
        _pet!.currentLevel >= 5 &&
        !_unlockedBorders.contains("Gold Scholar")) {
      _unlockedBorders.add("Gold Scholar");
      await prefs.setStringList(
        'unlocked_borders_${widget.studentID}',
        _unlockedBorders,
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleShopAction(Map<String, dynamic> item) async {
    if (_pet == null) return;
    final prefs = await SharedPreferences.getInstance();
    final name = item['name'] as String;
    final cost = item['cost'] as int;

    // Equip condition if already owned
    if (_unlockedBorders.contains(name)) {
      setState(() => _equippedBorder = name);
      await prefs.setString('equipped_border_${widget.studentID}', name);
      return;
    }

    // Purchase condition
    if (_pet!.coins >= cost) {
      setState(() {
        _pet!.coins -= cost;
        _unlockedBorders.add(name);
        _equippedBorder = name;
      });

      // Persist values
      await prefs.setString('user_streak_pet', jsonEncode(_pet!.toJson()));
      await prefs.setStringList(
        'unlocked_borders_${widget.studentID}',
        _unlockedBorders,
      );
      await prefs.setString('equipped_border_${widget.studentID}', name);

      // Sync UI components across app pages
      totalCreditsNotifier.value = totalCreditsNotifier.value;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Successfully customized with $name!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough academic coins! 🪙")),
      );
    }
  }

  Color _getBorderColor(String borderName) {
    switch (borderName) {
      case "Purple Haze":
        return Colors.purpleAccent;
      case "Gold Scholar":
        return Colors.amber;
      case "NTHU Violet":
        return const Color(0xFF7C3AED);
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentBorderColor = _getBorderColor(_equippedBorder);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Academic Identity",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          children: [
            // ================= BRANDED PROFILE PROFILE HEADER =================
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentBorderColor,
                        width: _equippedBorder != "None" ? 4.0 : 0.0,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(
                        Icons.school_rounded,
                        size: 40,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.studentID,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _pet?.currentStage ?? "Novice Learner",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ================= STREAK & LEVEL STATS GRID =================
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: "Current Streak",
                    value: "${_pet?.currentStreak ?? 0} Days",
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: "Wallet Balance",
                    value: "${_pet?.coins ?? 0} 🪙",
                    icon: Icons.monetization_on_rounded,
                    iconColor: Colors.amber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Matrix Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Level ${_pet?.currentLevel ?? 1}",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${_pet?.growthPoints ?? 0}/100 EXP",
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_pet?.growthPoints ?? 0) / 100,
                        minHeight: 10,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ================= AVATAR SHOP / ACHIEVEMENT SECTION =================
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Avatar Border Customization",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "💡 Tip: Reach Lv. 5 to automatically earn the Gold Scholar style!",
                style: TextStyle(
                  fontSize: 12,
                  color: cs.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _shopItems.length,
              itemBuilder: (context, index) {
                final item = _shopItems[index];
                final String name = item['name'];
                final int cost = item['cost'];

                final bool isOwned = _unlockedBorders.contains(name);
                final bool isEquipped = _equippedBorder == name;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: item['previewColor'],
                      child: isOwned
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    title: Text(
                      name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(isOwned ? "Unlocked" : "Cost: $cost 🪙"),
                    trailing: ElevatedButton(
                      onPressed: isEquipped
                          ? null
                          : () => _handleShopAction(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEquipped
                            ? cs.surfaceContainer
                            : (isOwned ? cs.secondaryContainer : cs.primary),
                        foregroundColor: isEquipped
                            ? cs.onSurfaceVariant
                            : (isOwned
                                  ? cs.onSecondaryContainer
                                  : cs.onPrimary),
                        elevation: 0,
                      ),
                      child: Text(
                        isEquipped ? "Equipped" : (isOwned ? "Equip" : "Buy"),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ================= MANAGE SETTINGS / TRANSCRIPT LINK =================
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Academic Settings",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.analytics_rounded, color: cs.primary),
                    title: Text(
                      "Adjust Curriculum & Credits",
                      style: GoogleFonts.outfit(fontSize: 15),
                    ),
                    subtitle: const Text(
                      "Modify structural semesters or initial course lists",
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      // Navigate back to credit layout interface (Index 1 on floating structure)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Use the Credit navigation tab to update your transcripts!",
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: iconColor, size: 22),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
