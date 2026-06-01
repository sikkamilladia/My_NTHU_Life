import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GPAPredictor extends StatefulWidget {
  final String studentID;

  const GPAPredictor({super.key, required this.studentID});

  @override
  State<GPAPredictor> createState() => _GPAPredictorState();
}

class _GPAPredictorState extends State<GPAPredictor> {
  // ===== ACCENT DESIGN PALETTE =====
  static const purpleMain = Color(0xFF7C3AED);
  static const purpleDark = Color(0xFF6D28D9);

  final Map<String, double> _gradePoints = {
    'A+': 4.3, 'A': 4.0, 'A-': 3.7,
    'B+': 3.3, 'B': 3.0, 'B-': 2.7,
    'C+': 2.3, 'C': 2.0, 'C-': 1.7,
    'D': 1.0,  'F': 0.0,
  };

  // Real-time remote cloud transactional write
  Future<void> _updateCourseGradeInCloud(String courseCode, String? newGrade) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .update({
        'courses.$courseCode.grade': newGrade ?? '–',
      });
    } catch (e) {
      debugPrint("Firebase Grade Prediction Sync Error: $e");
    }
  }

  // Pure state calculation layer handling raw map snapshots
  double _calculateStreamGPA(Map<String, dynamic> coursesMap) {
    double totalPoints = 0;
    int totalGradedCredits = 0;

    coursesMap.forEach((_, data) {
      if (data is Map) {
        final String? grade = data['grade'];
        final int credits = (data['credits'] ?? 0 as num).toInt();

        if (grade != null && grade != '–' && _gradePoints.containsKey(grade)) {
          totalPoints += (_gradePoints[grade]! * credits);
          totalGradedCredits += credits;
        }
      }
    });

    return totalGradedCredits == 0 ? 0.0 : totalPoints / totalGradedCredits;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'GPA Predictor Matrix',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.studentID)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: purpleMain),
            );
          }

          final userData = snapshot.data?.data() ?? {};
          final Map<String, dynamic> coursesMap = userData['courses'] != null 
              ? Map<String, dynamic>.from(userData['courses']) 
              : {};

          final calculatedGpa = _calculateStreamGPA(coursesMap);

          // Convert nested map keys into indexable listings for list builder
          final List<String> courseKeys = coursesMap.keys.toList();

          return Column(
            children: [
              // ===== ESTIMATED REAL-TIME GPA HEADER CONTAINER =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [purpleMain, purpleDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: purpleMain.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'ESTIMATED CUMULATIVE GPA',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      calculatedGpa.toStringAsFixed(2),
                      style: GoogleFonts.outfit(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // ===== INTERACTIVE DYNAMIC TARGET CORES MATRIX =====
              Expanded(
                child: courseKeys.isEmpty
                    ? Center(
                        child: Text(
                          "No active courses synced to predict 😢",
                          style: GoogleFonts.outfit(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        itemCount: courseKeys.length,
                        itemBuilder: (context, index) {
                          final String courseCode = courseKeys[index];
                          final Map<String, dynamic> courseData = Map<String, dynamic>.from(coursesMap[courseCode]);

                          final String name = courseData['courseName'] ?? 'Unknown Course';
                          final int credits = (courseData['credits'] ?? 0 as num).toInt();
                          String? activeGrade = courseData['grade'];

                          // Match fallback indicators safely
                          if (activeGrade == '–' || activeGrade == '-') {
                            activeGrade = null;
                          }

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                              ),
                            ),
                            color: theme.colorScheme.surfaceContainerLow,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    courseCode,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Divider(height: 1, thickness: 0.5),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.stars_rounded,
                                            size: 16,
                                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "$credits Academic Credits",
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      // ===== REAL-TIME INTERACTIVE CLOUD DROPDOWN =====
                                      SizedBox(
                                        width: 90,
                                        height: 40,
                                        child: DropdownButtonFormField<String>(
                                          value: activeGrade,
                                          dropdownColor: theme.colorScheme.surfaceContainerHigh,
                                          style: GoogleFonts.outfit(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: theme.colorScheme.outlineVariant,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: purpleMain, width: 1.5),
                                            ),
                                          ),
                                          hint: Text('-', style: TextStyle(color: theme.colorScheme.outline)),
                                          items: _gradePoints.keys.map((String targetGradeStr) {
                                            return DropdownMenuItem<String>(
                                              value: targetGradeStr,
                                              child: Text(targetGradeStr),
                                            );
                                          }).toList(),
                                          onChanged: (String? newlySelectedGrade) {
                                            _updateCourseGradeInCloud(courseCode, newlySelectedGrade);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}