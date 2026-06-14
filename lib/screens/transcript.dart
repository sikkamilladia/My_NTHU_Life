import 'package:flutter/material.dart';
import 'package:my_nthu_life/data/transcript_dummy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/screens/gpa_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_nthu_life/data/semester.dart';
import 'package:my_nthu_life/main.dart';
import 'package:my_nthu_life/services/firestore_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class CreditPage extends StatefulWidget {
  final String studentID;
  const CreditPage({super.key, required this.studentID});

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  // Fixed semantic purples kept for gradient & focus border
  static const purpleMain = Color(0xFF7B2CBF);
  static const purpleDark = Color(0xFF5A189A);
  static const purpleLight = Color(0xFFC77DFF);

  final int graduationCredits = 128;
  final FirestoreService _firestoreService = FirestoreService();

  List<Semester> semesters = [
    Semester(semesterName: "Semester 1", courses: []),
  ];
  int currentSemesterIndex = 0;

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  // ── Storage ────────────────────────────────────────────────────────────────

  Future<void> saveCourses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "Semesters_${widget.studentID}",
      jsonEncode(semesters.map((e) => e.toJson()).toList()),
    );
    totalCreditsNotifier.value = totalCredits;
  }

  // Future<void> loadCourses() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   String? encoded = prefs.getString("Semesters_${widget.studentID}");
  //   if (encoded != null) {
  //     final List<dynamic> decodedData = jsonDecode(encoded);
  //     setState(() {
  //       semesters = decodedData.map((item) => Semester.fromJson(item)).toList();
  //     });
  //     totalCreditsNotifier.value = totalCredits;
  //   }

  //   try {
  //     final docSnapshot = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(widget.studentID)
  //         .get();

  //     if (docSnapshot.exists && docSnapshot.data() != null) {
  //       final data = docSnapshot.data()!;
  //       if (data['courses'] != null) {
  //         final Map<String, dynamic> cloudCourses = data['courses'];
  //         List<Semester> freshSemesters = [
  //           Semester(semesterName: "Semester 1", courses: []),
  //         ];

  //         cloudCourses.forEach((courseCode, courseData) {
  //           final String targetSemesterName =
  //               courseData['semester'] ?? 'Semester 1';
  //           int semIndex = freshSemesters.indexWhere(
  //             (s) => s.semesterName == targetSemesterName,
  //           );
  //           if (semIndex == -1) {
  //             freshSemesters.add(
  //               Semester(semesterName: targetSemesterName, courses: []),
  //             );
  //             semIndex = freshSemesters.length - 1;
  //           }
  //           freshSemesters[semIndex].courses.add({
  //             'code': courseCode,
  //             'name': courseData['courseName'] ?? '',
  //             'credits': courseData['credits'] ?? 0,
  //             'grade': courseData['grade'] ?? '–',
  //           });
  //         });

  //         freshSemesters.sort(
  //           (a, b) => a.semesterName.compareTo(b.semesterName),
  //         );

  //         setState(() {
  //           semesters = freshSemesters;
  //           if (currentSemesterIndex >= semesters.length) {
  //             currentSemesterIndex = semesters.length - 1;
  //           }
  //         });
  //         await saveCourses();
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint("Error pulling data from Firebase: $e");
  //   }
  // }

  Future<void> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    String? encoded = prefs.getString("Semesters_${widget.studentID}");

    // 1. Load from SharedPreferences if exists
    if (encoded != null) {
      final List<dynamic> decodedData = jsonDecode(encoded);
      setState(() {
        semesters = decodedData.map((item) => Semester.fromJson(item)).toList();
      });
      totalCreditsNotifier.value = totalCredits;
    }

    // 2. Try Firebase
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .get();

      final hasFirebaseData =
          docSnapshot.exists &&
          docSnapshot.data() != null &&
          docSnapshot.data()!['courses'] != null &&
          (docSnapshot.data()!['courses'] as Map).isNotEmpty;

      if (hasFirebaseData) {
        // Same parsing logic you already have
        final Map<String, dynamic> cloudCourses = docSnapshot
            .data()!['courses'];
        List<Semester> freshSemesters = [];

        cloudCourses.forEach((courseCode, courseData) {
          final String targetSemesterName =
              courseData['semester'] ?? 'Semester 1';
          int semIndex = freshSemesters.indexWhere(
            (s) => s.semesterName == targetSemesterName,
          );
          if (semIndex == -1) {
            freshSemesters.add(
              Semester(semesterName: targetSemesterName, courses: []),
            );
            semIndex = freshSemesters.length - 1;
          }
          freshSemesters[semIndex].courses.add({
            'code': courseCode,
            'name': courseData['courseName'] ?? '',
            'credits': courseData['credits'] ?? 0,
            'grade': courseData['grade'] ?? '–',
          });
        });

        freshSemesters.sort((a, b) => a.semesterName.compareTo(b.semesterName));

        setState(() {
          semesters = freshSemesters;
          if (currentSemesterIndex >= semesters.length) {
            currentSemesterIndex = semesters.length - 1;
          }
        });
        await saveCourses();
      } else if (encoded == null || semesters.every((s) => s.courses.isEmpty)) {
        // 3. No data anywhere → seed defaults
        setState(() => semesters = getDefaultSemesters());
        await saveCourses(); // save to SharedPreferences
        await _saveAllToFirebase(); // save to Firebase
        totalCreditsNotifier.value = totalCredits;
      }
    } catch (e) {
      debugPrint("Error pulling data from Firebase: $e");
    }
  }

  /// Writes every semester/course from [semesters] to Firebase at once.
  Future<void> _saveAllToFirebase() async {
    for (final sem in semesters) {
      for (final course in sem.courses) {
        final String code = (course['code'] as String).isNotEmpty
            ? course['code']
            : (course['name'] as String).replaceAll(' ', '_');

        await _firestoreService.saveOrUpdateCourse(
          uid: widget.studentID,
          semesterName: sem.semesterName,
          courseCode: code,
          courseName: course['name'],
          grade: course['grade'],
          credits: course['credits'],
        );
      }
    }
  }

  // ── Calculations ───────────────────────────────────────────────────────────

  int get totalCredits {
    int sum = 0;
    for (var sem in semesters) {
      for (var course in sem.courses) {
        sum += (course['credits'] as num).toInt();
      }
    }
    return sum;
  }

  Semester get currentSemester => semesters[currentSemesterIndex];

  int get semesterCredits {
    int sum = 0;
    for (var course in currentSemester.courses) {
      sum += (course['credits'] as num).toInt();
    }
    return sum;
  }

  double get semesterGPA {
    if (currentSemester.courses.isEmpty) return 0;
    const gradeMapping = {
      'A+': 4.3,
      'A': 4.0,
      'A-': 3.7,
      'B+': 3.3,
      'B': 3.0,
      'B-': 2.7,
      'C+': 2.3,
      'C': 2.0,
      'C-': 1.7,
      'D': 1.0,
      'F': 0.0,
    };
    double totalPoints = 0;
    int totalCreds = 0;
    for (var course in currentSemester.courses) {
      final grade = course['grade'] ?? 'F';
      final credits = (course['credits'] as num).toInt();
      totalPoints += (gradeMapping[grade] ?? 0) * credits;
      totalCreds += credits;
    }
    return totalCreds > 0 ? totalPoints / totalCreds : 0;
  }

  String getLetterGrade(double gpa) {
    if (gpa >= 4.3) return 'A+';
    if (gpa >= 4.0) return 'A';
    if (gpa >= 3.7) return 'A-';
    if (gpa >= 3.3) return 'B+';
    if (gpa >= 3.0) return 'B';
    if (gpa >= 2.7) return 'B-';
    if (gpa >= 2.3) return 'C+';
    if (gpa >= 2.0) return 'C';
    if (gpa >= 1.7) return 'C-';
    if (gpa >= 1.0) return 'D';
    return 'F';
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  void addCourse(String name, String code, int credits, String grade) {
    setState(() {
      semesters[currentSemesterIndex].courses.add({
        'name': name,
        'code': code,
        'credits': credits,
        'grade': grade,
      });
    });
    saveCourses();

    final String cleanCode = code.trim().isNotEmpty
        ? code.trim()
        : name.trim().replaceAll(' ', '_');

    _firestoreService.saveOrUpdateCourse(
      uid: widget.studentID,
      semesterName: currentSemester.semesterName,
      courseCode: cleanCode,
      courseName: name,
      grade: grade,
      credits: credits,
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void showAddCourseDialog() {
    String name = "", creditInput = "";
    String selectedGrade = "A+";
    const grades = [
      'A+',
      'A',
      'A-',
      'B+',
      'B',
      'B-',
      'C+',
      'C',
      'C-',
      'D',
      'F',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            backgroundColor: cs.surfaceContainerLow, // #16121E
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: cs.surfaceBright, width: 1.5), // #3C096C
            ),
            title: Text(
              "ADD A COURSE",
              style: GoogleFonts.orbitron(
                color: cs.primaryContainer, // #C77DFF
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogTextField(
                    context,
                    "Course Name",
                    onChanged: (v) => name = v,
                  ),
                  // const SizedBox(height: 12),
                  // _dialogTextField(
                  //   context,
                  //   "Course Code",
                  //   onChanged: (v) => code = v,
                  // ),
                  const SizedBox(height: 12),
                  _dialogTextField(
                    context,
                    "Credits",
                    keyboardType: TextInputType.number,
                    onChanged: (v) => creditInput = v,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedGrade,
                        isExpanded: true,
                        dropdownColor: cs.surfaceContainerHigh,
                        style: GoogleFonts.outfit(color: cs.onSurface),
                        items: grades
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedGrade = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () {
                  final credits = int.tryParse(creditInput);
                  if (name.isNotEmpty && credits != null) {
                    addCourse(name, '', credits, selectedGrade);
                  }
                  Navigator.pop(context);
                },
                child: Text(
                  "Add",
                  style: GoogleFonts.orbitron(
                    color: cs.primaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dialogTextField(
    BuildContext context,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(color: cs.onSurface),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.outfit(color: cs.onSurfaceVariant),
        filled: true,
        fillColor: cs.surfaceContainerHigh,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: purpleLight, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gpa = semesterGPA;
    final progress = (totalCredits / graduationCredits).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: cs.surface, // #0B090A
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(
          "RECORD LOG",
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GpaCalculatorPage()),
        ),
        backgroundColor: cs.outline, // #7B2CBF
        foregroundColor: cs.onPrimary,
        tooltip: "GPA Calculator",
        child: const Icon(Icons.calculate_rounded),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. HEADER ROW ─────────────────────────────────────────────
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Row(
            //       children: [
            //         Icon(Icons.menu_book, color: cs.primaryContainer, size: 22),
            //         const SizedBox(width: 8),
            //         Text(
            //           "Academic Archive",
            //           style: GoogleFonts.outfit(
            //             color: cs.onSurface,
            //             fontSize: 16,
            //             fontWeight: FontWeight.w600,
            //           ),
            //         ),
            //       ],
            //     ),
            //     Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 12,
            //         vertical: 4,
            //       ),
            //       decoration: BoxDecoration(
            //         color: cs.surfaceBright.withOpacity(0.4), // #3C096C faint
            //         borderRadius: BorderRadius.circular(999),
            //         border: Border.all(color: cs.outline.withOpacity(0.4)),
            //       ),
            //       child: Row(
            //         children: [
            //           Icon(
            //             Icons.emoji_events,
            //             color: Colors.amber.shade400,
            //             size: 14,
            //           ),
            //           const SizedBox(width: 4),
            //           Text(
            //             "${semesters.fold(0, (sum, s) => sum + s.courses.length)} modules",
            //             style: GoogleFonts.outfit(
            //               color: Colors.amber.shade500,
            //               fontSize: 12,
            //               fontWeight: FontWeight.w600,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 16),

            // ── 2. GRADUATION PROGRESS BAR ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow, // #16121E
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "GRADUATION PROGRESS",
                        style: GoogleFonts.orbitron(
                          color: cs.inversePrimary, // #9D4EDD
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        "$totalCredits / $graduationCredits CR",
                        style: GoogleFonts.orbitron(
                          color: cs.primaryContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: cs.outlineVariant.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        cs.primaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${(progress * 100).toStringAsFixed(1)}% complete",
                    style: GoogleFonts.outfit(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 3. SEMESTER NAVIGATOR ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    if (currentSemesterIndex > 0) {
                      setState(() => currentSemesterIndex--);
                    }
                  },
                  icon: Icon(Icons.chevron_left, color: cs.primaryContainer),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.surfaceBright.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline.withOpacity(0.4)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      currentSemester.semesterName.toUpperCase(),
                      style: GoogleFonts.orbitron(
                        color: cs.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (currentSemesterIndex < semesters.length - 1) {
                      setState(() => currentSemesterIndex++);
                    } else {
                      setState(() {
                        semesters.add(
                          Semester(
                            semesterName: "Semester ${semesters.length + 1}",
                            courses: [],
                          ),
                        );
                        currentSemesterIndex = semesters.length - 1;
                      });
                      saveCourses();
                    }
                  },
                  icon: Icon(Icons.chevron_right, color: cs.primaryContainer),
                ),
                const SizedBox(width: 4),
                // ADD button
                GestureDetector(
                  onTap: showAddCourseDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cs.outline, // #7B2CBF
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "ADD COURSE",
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── 4. STAT CARDS ─────────────────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3.2,
              children: [
                _statCard(
                  context,
                  icon: Icons.menu_book,
                  iconColor: cs.primaryContainer,
                  iconBg: cs.surfaceBright.withOpacity(0.4),
                  label: "Credits",
                  value: "$semesterCredits",
                ),
                _statCard(
                  context,
                  icon: Icons.trending_up,
                  iconColor: Colors.greenAccent.shade400,
                  iconBg: Colors.green.withOpacity(0.15),
                  label: "GPA",
                  value: currentSemester.courses.isEmpty
                      ? "0.00"
                      : "${gpa.toStringAsFixed(2)} (${getLetterGrade(gpa)})",
                ),
                _statCard(
                  context,
                  icon: Icons.school,
                  iconColor: Colors.lightBlueAccent,
                  iconBg: Colors.blue.withOpacity(0.12),
                  label: "T-Score",
                  value: "–",
                ),
                _statCard(
                  context,
                  icon: Icons.emoji_events,
                  iconColor: Colors.amber.shade400,
                  iconBg: Colors.amber.withOpacity(0.12),
                  label: "Class Rank",
                  value: "–",
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 5. COURSE LIST ────────────────────────────────────────────
            if (currentSemester.courses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant, width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 40,
                      color: cs.onSurfaceVariant.withOpacity(0.4),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "No courses enrolled this semester.",
                      style: GoogleFonts.outfit(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  "ENROLLED MODULES",
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cs.inversePrimary, // #9D4EDD
                    letterSpacing: 1,
                  ),
                ),
              ),
              ...currentSemester.courses.asMap().entries.map((entry) {
                final course = entry.value;
                final grade = course['grade'] ?? '–';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Category color bar (left accent)
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Course icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cs.surfaceBright.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.menu_book,
                            color: cs.primaryContainer,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Course name + code
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course['name'] ?? '',
                                style: GoogleFonts.outfit(
                                  color: cs.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                course['code'] ?? 'No Code',
                                style: GoogleFonts.outfit(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Credits
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "CR",
                              style: GoogleFonts.orbitron(
                                color: cs.onSurfaceVariant,
                                fontSize: 8,
                              ),
                            ),
                            Text(
                              "${course['credits']}",
                              style: GoogleFonts.orbitron(
                                color: cs.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),

                        // Grade badge
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [purpleMain, purpleDark],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: purpleLight.withOpacity(0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            grade,
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Delete
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: cs.onSurfaceVariant.withOpacity(0.5),
                            size: 18,
                          ),
                          onPressed: () {
                            final removed = currentSemester.courses[entry.key];
                            final String targetCode =
                                (removed['code'] != null &&
                                    removed['code'].toString().isNotEmpty)
                                ? removed['code']
                                : removed['name'].toString().replaceAll(
                                    ' ',
                                    '_',
                                  );

                            setState(
                              () => currentSemester.courses.removeAt(entry.key),
                            );
                            saveCourses();
                            _firestoreService.deleteCourse(
                              uid: widget.studentID,
                              courseCode: targetCode,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Stat Card ──────────────────────────────────────────────────────────────

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.orbitron(
                    color: cs.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
