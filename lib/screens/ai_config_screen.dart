import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_nthu_life/services/firestore_services.dart';

class AIConfigScreen extends StatefulWidget {
  final String studentID;
  const AIConfigScreen({super.key, required this.studentID});

  @override
  State<AIConfigScreen> createState() => _AIConfigScreenState();
}

class _AIConfigScreenState extends State<AIConfigScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _goalController = TextEditingController();

  String _intensity = 'Balanced';
  String _studyStyle = 'Practical';
  Map<String, String> _coursePriorities = {};
  bool _isLoading = true;

  final List<String> _intensities = ['Chill', 'Balanced', 'Hardcore'];
  final List<String> _studyStyles = [
    'Visual',
    'Practical',
    'Theoretical',
    'Quick Summary',
  ];
  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _firestoreService.getAIConfig(widget.studentID);
    if (config != null) {
      setState(() {
        _intensity = config['intensity'] ?? 'Balanced';
        _studyStyle = config['studyStyle'] ?? 'Practical';
        _goalController.text = config['generalGoal'] ?? '';
        _coursePriorities = Map<String, String>.from(
          config['coursePriorities'] ?? {},
        );
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveConfig() async {
    await _firestoreService.saveAIConfig(
      uid: widget.studentID,
      config: {
        'intensity': _intensity,
        'studyStyle': _studyStyle,
        'generalGoal': _goalController.text.trim(),
        'coursePriorities': _coursePriorities,
      },
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI Configuration Saved!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: cs.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "AI SETTINGS",
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primaryContainer))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(cs, "STUDY INTENSITY"),
                  const SizedBox(height: 10),
                  _buildIntensitySelector(cs),
                  const SizedBox(height: 20),

                  _sectionLabel(cs, "STUDY STYLE"),
                  const SizedBox(height: 10),
                  _buildStyleSelector(cs),
                  const SizedBox(height: 20),

                  _sectionLabel(cs, "GENERAL STUDY GOAL"),
                  const SizedBox(height: 10),
                  _themedTextField(
                    cs,
                    controller: _goalController,
                    label: "e.g. Focus on coding, prepare for finals",
                  ),
                  const SizedBox(height: 20),

                  _sectionLabel(cs, "COURSE PRIORITIES"),
                  const SizedBox(height: 10),
                  _buildCoursePriorityList(cs),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.outline,
                        foregroundColor: cs.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "SAVE CONFIGURATION",
                        style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(ColorScheme cs, String text) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: cs.inversePrimary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildIntensitySelector(ColorScheme cs) {
    return Row(
      children: _intensities.map((intensity) {
        bool isSelected = _intensity == intensity;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _intensity = intensity),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? cs.outline : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? cs.outline : cs.outlineVariant,
                ),
              ),
              child: Center(
                child: Text(
                  intensity,
                  style: GoogleFonts.outfit(
                    color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStyleSelector(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _studyStyle,
          isExpanded: true,
          dropdownColor: cs.surfaceContainerHigh,
          style: GoogleFonts.outfit(color: cs.onSurface),
          items: _studyStyles
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _studyStyle = v!),
        ),
      ),
    );
  }

  Widget _themedTextField(
    ColorScheme cs, {
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 12),
        filled: true,
        fillColor: cs.surfaceContainerLow,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCoursePriorityList(ColorScheme cs) {
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .collection('tasks')
          .where('category', isEqualTo: 'Class')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));

        final docs = snapshot.data!.docs;
        // Filter for tasks starting from today and get unique course names
        final uniqueCourses = docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((data) {
              final assignedDay = data['assignedDayString'] as String? ?? '';
              return assignedDay.compareTo(todayStr) >= 0;
            })
            .map((data) => data['course'] as String? ?? 'General Task')
            .toSet()
            .toList();

        if (uniqueCourses.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "No active classes found starting from today. Add them in Timeline Archive with category 'Class'.",
              style: GoogleFonts.outfit(
                color: cs.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          );
        }

        return Column(
          children: uniqueCourses.map((name) {
            String currentPriority = _coursePriorities[name] ?? 'Medium';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: currentPriority,
                    dropdownColor: cs.surfaceContainerHigh,
                    style: GoogleFonts.outfit(
                      color: cs.onSurface,
                      fontSize: 12,
                    ),
                    items: _priorities
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _coursePriorities[name] = v!;
                      });
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
