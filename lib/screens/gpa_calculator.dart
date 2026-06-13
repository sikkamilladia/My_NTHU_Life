import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/data/calcu.dart';

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────

class CourseComponent {
  String name;
  double weight;
  double? score;
  CourseComponent({required this.name, required this.weight, this.score});
}

class Course {
  String name;
  List<CourseComponent> components;
  Course({required this.name, List<CourseComponent>? components})
    : components = components ?? [];
}

// ─────────────────────────────────────────────
//  MAIN PAGE
// ─────────────────────────────────────────────

class GpaCalculatorPage extends StatefulWidget {
  const GpaCalculatorPage({super.key});

  @override
  State<GpaCalculatorPage> createState() => _GpaCalculatorPageState();
}

class _GpaCalculatorPageState extends State<GpaCalculatorPage> {
  final List<Course> _courses = [];
  int _selectedCourseIndex = 0;

  // ─── persistence ───────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final saved = await GpaStorage.loadCourses();
    if (saved.isEmpty) return;
    setState(() {
      _courses.clear();
      for (final c in saved) {
        final components = (c['components'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .map(
              (e) => CourseComponent(
                name: e['name'] as String,
                weight: (e['weight'] as num).toDouble(),
                score: e['score'] != null
                    ? (e['score'] as num).toDouble()
                    : null,
              ),
            )
            .toList();
        _courses.add(Course(name: c['name'] as String, components: components));
      }
      _selectedCourseIndex = 0;
    });
  }

  Future<void> _saveData() async {
    final data = _courses
        .map(
          (c) => courseToJson(
            c.name,
            c.components
                .map((x) => componentToJson(x.name, x.weight, x.score))
                .toList(),
          ),
        )
        .toList();
    await GpaStorage.saveCourses(data);
  }

  // ─── helpers ───────────────────────────────

  Course? get _current =>
      _courses.isEmpty ? null : _courses[_selectedCourseIndex];

  double _totalWeight(Course c) => c.components.fold(0, (s, x) => s + x.weight);

  double _weightedScore(Course c) {
    double total = 0;
    for (final x in c.components) {
      if (x.score != null) total += x.score! * x.weight / 100;
    }
    return total;
  }

  double _filledWeight(Course c) => c.components
      .where((x) => x.score != null)
      .fold(0, (s, x) => s + x.weight);

  double _courseScore(Course c) {
    final fw = _filledWeight(c);
    if (fw == 0) return 0;
    final allFilled =
        c.components.isNotEmpty && c.components.every((x) => x.score != null);
    return allFilled ? _weightedScore(c) : _weightedScore(c) / fw * 100;
  }

  String _scoreToGrade(double score) {
    if (score >= 93) return 'A+';
    if (score >= 90) return 'A';
    if (score >= 87) return 'A-';
    if (score >= 83) return 'B+';
    if (score >= 80) return 'B';
    if (score >= 77) return 'B-';
    if (score >= 73) return 'C+';
    if (score >= 70) return 'C';
    if (score >= 67) return 'C-';
    if (score >= 60) return 'D';
    return 'F';
  }

  double _gradeToGpa(String grade) {
    switch (grade) {
      case 'A+':
        return 4.3;
      case 'A':
        return 4.0;
      case 'A-':
        return 3.7;
      case 'B+':
        return 3.3;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.7;
      case 'C+':
        return 2.3;
      case 'C':
        return 2.0;
      case 'C-':
        return 1.7;
      case 'D':
        return 1.0;
      default:
        return 0.0;
    }
  }

  Color _gradeColor(String grade) {
    if (grade.startsWith('A')) return const Color(0xFF00CEC9);
    if (grade.startsWith('B')) return const Color(0xFF64DFDF);
    if (grade.startsWith('C')) return const Color(0xFFC77DFF);
    if (grade == 'D') return const Color(0xFFE0AAFF);
    return const Color(0xFF9D4EDD);
  }

  double get _overallGpa {
    final active = _courses
        .where(
          (c) =>
              c.components.isNotEmpty &&
              c.components.any((x) => x.score != null),
        )
        .toList();
    if (active.isEmpty) return 0;
    final sum = active.fold<double>(
      0,
      (s, c) => s + _gradeToGpa(_scoreToGrade(_courseScore(c))),
    );
    return sum / active.length;
  }

  // ─── dialogs ───────────────────────────────

  void _showAddCourseDialog({int? editIndex}) {
    final existing = editIndex != null ? _courses[editIndex] : null;
    String name = existing?.name ?? '';
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.surfaceBright, width: 1.5),
        ),
        title: Text(
          editIndex != null ? 'RENAME COURSE' : 'NEW COURSE MODULE',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            color: cs.primaryContainer,
            fontSize: 14,
          ),
        ),
        content: _styledTextField(
          cs,
          labelText: 'Course name',
          hintText: 'e.g. Calculus I',
          initialValue: name,
          onChanged: (v) => name = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              if (name.trim().isEmpty) return;
              setState(() {
                if (editIndex != null) {
                  _courses[editIndex].name = name.trim();
                } else {
                  _courses.add(Course(name: name.trim()));
                  _selectedCourseIndex = _courses.length - 1;
                }
              });
              _saveData();
              Navigator.pop(ctx);
            },
            child: Text(
              editIndex != null ? 'Save' : 'Add',
              style: GoogleFonts.orbitron(
                color: cs.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddComponentDialog({int? editIndex}) {
    final course = _current;
    if (course == null) return;
    final existing = editIndex != null ? course.components[editIndex] : null;
    String name = existing?.name ?? '';
    String weightInput = existing != null
        ? existing.weight.toStringAsFixed(0)
        : '';
    String scoreInput = existing?.score != null
        ? existing!.score!.toStringAsFixed(0)
        : '';
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.surfaceBright, width: 1.5),
        ),
        title: Text(
          editIndex != null ? 'EDIT COMPONENT' : 'ADD COMPONENT',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            color: cs.primaryContainer,
            fontSize: 14,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _styledTextField(
                cs,
                labelText: 'Component name',
                hintText: 'e.g. Midterm',
                initialValue: name,
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 12),
              _styledTextField(
                cs,
                labelText: 'Weight (%)',
                hintText: 'e.g. 30',
                initialValue: weightInput,
                keyboardType: TextInputType.number,
                onChanged: (v) => weightInput = v,
              ),
              const SizedBox(height: 12),
              _styledTextField(
                cs,
                labelText: 'Score (0–100, optional)',
                hintText: 'e.g. 85',
                initialValue: scoreInput,
                keyboardType: TextInputType.number,
                onChanged: (v) => scoreInput = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              final weight = double.tryParse(weightInput);
              if (name.trim().isEmpty || weight == null) return;
              final rawScore = double.tryParse(scoreInput);
              final score = rawScore != null
                  ? rawScore.clamp(0.0, 100.0)
                  : null;
              setState(() {
                final comp = CourseComponent(
                  name: name.trim(),
                  weight: weight,
                  score: score,
                );
                if (editIndex != null) {
                  course.components[editIndex] = comp;
                } else {
                  course.components.add(comp);
                }
              });
              _saveData();
              Navigator.pop(ctx);
            },
            child: Text(
              editIndex != null ? 'Save' : 'Confirm',
              style: GoogleFonts.orbitron(
                color: cs.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _styledTextField(
    ColorScheme cs, {
    required String labelText,
    required String hintText,
    String initialValue = '',
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
  }) {
    return TextField(
      keyboardType: keyboardType,
      controller: TextEditingController(text: initialValue),
      style: TextStyle(color: cs.onSurface),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: cs.primaryContainer),
        hintText: hintText,
        hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.24)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: cs.surfaceBright),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: cs.primaryContainer),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final course = _current;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        // Keep the default back button provided by Navigator
        title: Text(
          'GPA MATRIX',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: cs.primaryContainer),
      ),
      floatingActionButton: course != null
          ? FloatingActionButton.extended(
              backgroundColor: cs.outline,
              label: Text(
                'ADD COMPONENT',
                style: GoogleFonts.orbitron(
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimary,
                  fontSize: 12,
                ),
              ),
              icon: Icon(Icons.add, color: cs.onPrimary),
              onPressed: _showAddComponentDialog,
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGpaBanner(cs),
              const SizedBox(height: 20),
              _buildCourseSelector(cs),
              const SizedBox(height: 20),
              if (course != null) ...[
                _buildCourseResultCard(course, cs),
                const SizedBox(height: 12),
                _buildWeightBar(course, cs),
                const SizedBox(height: 12),
                _buildComponentList(course, cs),
              ] else
                _buildNoCourseState(cs),
            ],
          ),
        ),
      ),
    );
  }

  // ── GPA Banner ────────────────────────────

  Widget _buildGpaBanner(ColorScheme cs) {
    final gpa = _overallGpa;
    final gpaStr = _courses.isEmpty ? '–' : gpa.toStringAsFixed(2);
    final courseCount = _courses.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cumulative GPA index',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: cs.outline,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                gpaStr,
                style: GoogleFonts.orbitron(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/ 4.3',
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    color: cs.inversePrimary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$courseCount course${courseCount != 1 ? 's' : ''}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Course Selector ───────────────────────

  Widget _buildCourseSelector(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'COURSES',
              style: GoogleFonts.orbitron(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: cs.inversePrimary,
                letterSpacing: 1,
              ),
            ),
            GestureDetector(
              onTap: _showAddCourseDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.outline.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: cs.outline.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: cs.primaryContainer, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Add Course',
                      style: GoogleFonts.outfit(
                        color: cs.primaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_courses.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _courses.asMap().entries.map((e) {
                final i = e.key;
                final c = e.value;
                final selected = i == _selectedCourseIndex;
                final hasScore =
                    c.components.isNotEmpty &&
                    c.components.any((x) => x.score != null);
                final gpaStr = hasScore
                    ? _gradeToGpa(
                        _scoreToGrade(_courseScore(c)),
                      ).toStringAsFixed(1)
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCourseIndex = i),
                    onLongPress: () => _showCourseOptions(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.surfaceBright
                            : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? cs.primaryContainer
                              : cs.outlineVariant,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            c.name,
                            style: GoogleFonts.outfit(
                              color: selected
                                  ? cs.onSurface
                                  : cs.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (gpaStr != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                gpaStr,
                                style: GoogleFonts.orbitron(
                                  color: cs.primaryContainer,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              'Long-press a course to rename or delete',
              style: GoogleFonts.outfit(
                color: cs.onSurfaceVariant.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCourseOptions(int index) {
    final course = _courses[index];
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_rounded, color: cs.primaryContainer),
                title: Text(
                  'Rename "${course.name}"',
                  style: GoogleFonts.outfit(color: cs.onSurface),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddCourseDialog(editIndex: index);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFF9D4EDD),
                ),
                title: Text(
                  'Delete "${course.name}"',
                  style: GoogleFonts.outfit(color: const Color(0xFF9D4EDD)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _courses.removeAt(index);
                    if (_selectedCourseIndex >= _courses.length) {
                      _selectedCourseIndex = (_courses.length - 1).clamp(
                        0,
                        999,
                      );
                    }
                  });
                  _saveData();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Course Result Card ────────────────────

  Widget _buildCourseResultCard(Course course, ColorScheme cs) {
    final allFilled =
        course.components.isNotEmpty &&
        course.components.every((x) => x.score != null);
    final score = course.components.isEmpty ? 0.0 : _courseScore(course);
    final grade = course.components.isEmpty ? '–' : _scoreToGrade(score);
    final gpa = course.components.isEmpty
        ? '–'
        : _gradeToGpa(grade).toStringAsFixed(1);
    final fw = _filledWeight(course);
    final gradeCol = course.components.isEmpty
        ? cs.primaryContainer
        : _gradeColor(grade);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    color: cs.inversePrimary,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  allFilled ? 'Final Score' : 'Partial Score',
                  style: GoogleFonts.outfit(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  course.components.isEmpty
                      ? '–'
                      : '${score.toStringAsFixed(1)}%',
                  style: GoogleFonts.orbitron(
                    color: cs.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!allFilled && course.components.isNotEmpty)
                  Text(
                    'Based on ${fw.toStringAsFixed(0)}% weight filled',
                    style: GoogleFonts.outfit(
                      color: cs.onSurfaceVariant.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              _badge(cs, grade, gradeCol, label: 'Grade'),
              const SizedBox(width: 8),
              _badge(cs, gpa, cs.primaryContainer, label: 'GPA'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(
    ColorScheme cs,
    String value,
    Color color, {
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: cs.onSurfaceVariant.withOpacity(0.6),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // ── Weight Bar ────────────────────────────

  Widget _buildWeightBar(Course course, ColorScheme cs) {
    final tw = _totalWeight(course);
    final weightOk = (tw - 100).abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEIGHT ALLOCATED',
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: cs.outline,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${tw.toStringAsFixed(0)} / 100%',
                style: GoogleFonts.outfit(
                  color: weightOk
                      ? const Color(0xFF00CEC9)
                      : cs.primaryContainer,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (tw / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: cs.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                tw > 100 ? const Color(0xFF9D4EDD) : cs.primaryContainer,
              ),
            ),
          ),
          if (course.components.isNotEmpty && !weightOk)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: cs.primaryContainer,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    tw < 100
                        ? "Weights don't add up to 100% yet"
                        : 'Weights exceed 100%!',
                    style: GoogleFonts.outfit(
                      color: cs.primaryContainer,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Component List ────────────────────────

  Widget _buildComponentList(Course course, ColorScheme cs) {
    if (course.components.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No components yet. Tap ADD COMPONENT to begin.',
            style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 10),
          child: Text(
            'COMPONENTS • ${course.name.toUpperCase()}',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cs.inversePrimary,
              letterSpacing: 1,
            ),
          ),
        ),
        ...course.components.asMap().entries.map((entry) {
          final i = entry.key;
          final comp = entry.value;
          final score = comp.score;
          final contribution = score != null ? score * comp.weight / 100 : null;
          final gradeStr = score != null ? _scoreToGrade(score) : '–';
          final gc = score != null
              ? _gradeColor(gradeStr)
              : cs.onSurfaceVariant;

          return Card(
            color: cs.surfaceContainerLow,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
            ),
            child: ListTile(
              onTap: () => _showAddComponentDialog(editIndex: i),
              leading: Container(width: 4, height: 26, color: gc),
              title: Text(
                comp.name,
                style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 15),
              ),
              subtitle: Text(
                'Weight: ${comp.weight.toStringAsFixed(0)}%'
                '${contribution != null ? '  •  +${contribution.toStringAsFixed(1)} pts' : ''}',
                style: GoogleFonts.outfit(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        score != null ? '${score.toStringAsFixed(0)}%' : '–',
                        style: GoogleFonts.orbitron(
                          color: cs.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        gradeStr,
                        style: GoogleFonts.outfit(
                          color: gc,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: cs.onSurfaceVariant.withOpacity(0.5),
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() => course.components.removeAt(i));
                      _saveData();
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── No courses state ──────────────────────

  Widget _buildNoCourseState(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 48,
            color: cs.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 14),
          Text(
            'NO COURSES LOADED',
            style: GoogleFonts.orbitron(
              color: cs.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Course" above to initialize a module',
            style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
