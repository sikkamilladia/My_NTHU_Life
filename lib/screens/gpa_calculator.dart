import 'package:flutter/material.dart';
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
  // ── Accent palette ──
  static const purpleMain = Color(0xFF7C3AED);
  static const purpleDark = Color(0xFF6D28D9);
  static const purpleLight = Color(0xFFA78BFA);

  final List<Course> _courses = [];
  int _selectedCourseIndex = 0; // which course is active

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
    if (grade.startsWith('A')) return Colors.green.shade400;
    if (grade.startsWith('B')) return Colors.blue.shade300;
    if (grade.startsWith('C')) return Colors.orange.shade300;
    if (grade == 'D') return Colors.orange.shade600;
    return Colors.red.shade400;
  }

  /// Overall GPA = average of each course's GPA (only courses with ≥1 scored component)
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

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editIndex != null ? 'Rename Course' : 'Add Course',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _buildTextField(
                ctx,
                'Course name (e.g. Calculus I)',
                initial: name,
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      ctx,
                      label: editIndex != null ? 'Save' : 'Add',
                      primary: true,
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionButton(
                      ctx,
                      label: 'Cancel',
                      primary: false,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editIndex != null ? 'Edit Component' : 'Add Component',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _buildTextField(
                ctx,
                'Component name (e.g. Midterm)',
                initial: name,
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                ctx,
                'Weight (%)',
                keyboardType: TextInputType.number,
                initial: weightInput,
                onChanged: (v) => weightInput = v,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                ctx,
                'Score (0–100, optional)',
                keyboardType: TextInputType.number,
                initial: scoreInput,
                onChanged: (v) => scoreInput = v,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      ctx,
                      label: editIndex != null ? 'Save' : 'Add',
                      primary: true,
                      onPressed: () {
                        final weight = double.tryParse(weightInput);
                        if (name.trim().isEmpty || weight == null) return;
                        final rawScore = double.tryParse(scoreInput);
                        // clamp score to 0–100
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionButton(
                      ctx,
                      label: 'Cancel',
                      primary: false,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── shared widget helpers ──────────────────

  Widget _buildTextField(
    BuildContext ctx,
    String hint, {
    String initial = '',
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
  }) {
    final cs = Theme.of(ctx).colorScheme;
    return TextField(
      keyboardType: keyboardType,
      controller: TextEditingController(text: initial),
      style: TextStyle(color: cs.onSurface),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        filled: true,
        fillColor: cs.surfaceContainerHigh,
        border: _border(cs.outlineVariant),
        enabledBorder: _border(cs.outlineVariant),
        focusedBorder: _border(purpleMain),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color),
  );

  Widget _actionButton(
    BuildContext ctx, {
    required String label,
    required bool primary,
    required VoidCallback onPressed,
  }) {
    final cs = Theme.of(ctx).colorScheme;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary ? purpleMain : cs.surfaceContainerHighest,
        foregroundColor: primary ? Colors.white : cs.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(label),
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
      floatingActionButton: course != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: FloatingActionButton(
                onPressed: _showAddComponentDialog,
                backgroundColor: purpleMain,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(cs),
            const SizedBox(height: 14),
            _buildOverallGpaBanner(),
            const SizedBox(height: 14),
            _buildCourseSelector(cs),
            const SizedBox(height: 14),
            if (course != null) ...[
              _buildCourseResultCard(course),
              const SizedBox(height: 12),
              _buildWeightBar(course, cs),
              const SizedBox(height: 12),
              _buildComponentList(course, cs),
            ] else
              _buildNoCourseState(cs),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────

  Widget _buildHeader(ColorScheme cs) {
    return Row(
      children: [
        Icon(Icons.school_rounded, color: purpleLight, size: 22),
        const SizedBox(width: 8),
        Text(
          'GPA Calculator',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: cs.onSurfaceVariant,
            size: 20,
          ),
          onPressed: () {
            // pop if pushed, otherwise let the parent Home handle tab switching
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  // ── Overall GPA banner ────────────────────

  Widget _buildOverallGpaBanner() {
    final gpa = _overallGpa;
    final gpaStr = _courses.isEmpty ? '–' : gpa.toStringAsFixed(2);
    final courseCount = _courses.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [purpleMain, purpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: purpleMain.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cumulative GPA',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gpaStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '$courseCount course${courseCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
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

  Widget _gpaScalePill(String gpa, String grade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$grade = $gpa',
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
    );
  }

  // ── Course selector row ───────────────────

  Widget _buildCourseSelector(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Courses',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _showAddCourseDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: purpleMain.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: purpleMain.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add, color: purpleLight, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Add Course',
                      style: TextStyle(
                        color: purpleLight,
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
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? purpleMain
                            : cs.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? purpleMain
                              : cs.onSurface.withOpacity(0.10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            c.name,
                            style: TextStyle(
                              color: selected ? Colors.white : cs.onSurface,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
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
                                color: selected
                                    ? Colors.white.withOpacity(0.2)
                                    : purpleMain.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                gpaStr,
                                style: TextStyle(
                                  color: selected ? Colors.white : purpleLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
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
              'Tip: long-press a course to rename or delete it',
              style: TextStyle(
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: purpleLight),
                title: Text('Rename "${course.name}"'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddCourseDialog(editIndex: index);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade400,
                ),
                title: Text(
                  'Delete "${course.name}"',
                  style: TextStyle(color: Colors.red.shade400),
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

  // ── Course result card ────────────────────

  Widget _buildCourseResultCard(Course course) {
    final allFilled =
        course.components.isNotEmpty &&
        course.components.every((x) => x.score != null);
    final score = course.components.isEmpty ? 0.0 : _courseScore(course);
    final grade = course.components.isEmpty ? '–' : _scoreToGrade(score);
    final gpa = course.components.isEmpty
        ? '–'
        : _gradeToGpa(grade).toStringAsFixed(1);
    final fw = _filledWeight(course);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  allFilled ? 'Final Score' : 'Current Score (partial)',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  course.components.isEmpty
                      ? '–'
                      : '${score.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!allFilled && course.components.isNotEmpty)
                  Text(
                    'Based on ${fw.toStringAsFixed(0)}% weight filled',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          // Grade + GPA badges
          Row(
            children: [
              _badge(
                grade,
                course.components.isEmpty ? purpleLight : _gradeColor(grade),
                label: 'Grade',
              ),
              const SizedBox(width: 8),
              _badge(gpa, purpleLight, label: 'GPA'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String value, Color color, {required String label}) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.6),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // ── Weight progress bar ───────────────────

  Widget _buildWeightBar(Course course, ColorScheme cs) {
    final tw = _totalWeight(course);
    final weightOk = (tw - 100).abs() < 0.01;
    final containerBg = cs.onSurface.withOpacity(0.05);
    final containerBorder = cs.onSurface.withOpacity(0.10);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: containerBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weight Allocated',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
              Text(
                '${tw.toStringAsFixed(0)} / 100%',
                style: TextStyle(
                  color: weightOk ? Colors.green.shade400 : purpleLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (tw / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: containerBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                tw > 100 ? Colors.red.shade400 : purpleMain,
              ),
            ),
          ),
          if (course.components.isNotEmpty && !weightOk)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: Colors.amber.shade600,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    tw < 100
                        ? "Weights don't add up to 100% yet"
                        : 'Weights exceed 100%!',
                    style: TextStyle(
                      color: Colors.amber.shade600,
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

  // ── Component list ────────────────────────

  Widget _buildComponentList(Course course, ColorScheme cs) {
    final containerBg = cs.onSurface.withOpacity(0.05);
    final containerBorder = cs.onSurface.withOpacity(0.10);
    final purpleOverlay = purpleMain.withOpacity(0.20);

    if (course.components.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 40,
                color: cs.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap + to add components (e.g. Midterm, Final)',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: course.components.asMap().entries.map((entry) {
        final i = entry.key;
        final comp = entry.value;
        final score = comp.score;
        final contribution = score != null ? score * comp.weight / 100 : null;
        final gradeStr = score != null ? _scoreToGrade(score) : '–';
        final gc = score != null ? _gradeColor(gradeStr) : cs.onSurfaceVariant;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _showAddComponentDialog(editIndex: i),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: containerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: containerBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: purpleOverlay,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.assignment_rounded,
                      color: purpleLight,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comp.name,
                          style: TextStyle(color: cs.onSurface, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Weight: ${comp.weight.toStringAsFixed(0)}%'
                          '${contribution != null ? '  ·  +${contribution.toStringAsFixed(1)} pts' : ''}',
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withOpacity(0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        score != null ? '${score.toStringAsFixed(0)}%' : '–',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        gradeStr,
                        style: TextStyle(
                          color: gc,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
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
          ),
        );
      }).toList(),
    );
  }

  // ── Empty / no courses ────────────────────

  Widget _buildNoCourseState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 48,
              color: cs.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 14),
            Text(
              'No courses yet',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "Add Course" above to get started',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
