import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_nthu_life/data/semester.dart';
import 'dart:convert';

class CreditPage extends StatefulWidget {
  final String studentID;

  const CreditPage({super.key, required this.studentID});

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  final int graduationCredits = 128;

  List<Semester> semesters = [
    Semester(semesterName: "Semester 1", courses: [])
  ];

  int currentSemesterIndex = 0;

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  // ===== STORAGE =====
  Future<void> saveCourses() async {
    final prefs = await SharedPreferences.getInstance();

    String encoded =
        jsonEncode(semesters.map((e) => e.toJson()).toList());

    await prefs.setString("Semesters_${widget.studentID}", encoded);
  }

  Future<void> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    String? encoded = prefs.getString("Semesters_${widget.studentID}");

    if (encoded != null) {
      final List<dynamic> decodedData = jsonDecode(encoded);

      setState(() {
        semesters = decodedData
            .map((item) => Semester.fromJson(item))
            .toList();
      });
    }
  }

  // ===== CALCULATION =====
  int get totalCredits {
    int sum = 0;
    for (var sem in semesters) {
      for (var course in sem.courses) {
        sum += (course['credits'] as num).toInt();
      }
    }
    return sum;
  }

  int get remainingCredits {
    int remaining = graduationCredits - totalCredits;
    return remaining < 0 ? 0 : remaining;
  }

  // ===== UTIL =====
  String capitalizeWords(String text) {
    return text
        .split(" ")
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() +
                word.substring(1).toLowerCase()
            : "")
        .join(" ");
  }

  // ===== CRUD =====
  void addCourse(String name, int credits) {
    setState(() {
      semesters[currentSemesterIndex]
          .courses
          .add({'name': name, 'credits': credits});
    });

    saveCourses();
  }

  void showAddCourseDialog() {
    String name = "";
    String creditInput = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Course"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration:
                    const InputDecoration(labelText: "Course Name"),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration:
                    const InputDecoration(labelText: "Credits"),
                keyboardType: TextInputType.number,
                onChanged: (value) => creditInput = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                int? credits = int.tryParse(creditInput);

                if (name.isNotEmpty && credits != null) {
                  addCourse(name, credits);
                }

                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: FloatingActionButton(
          onPressed: showAddCourseDialog,
          child: const Icon(Icons.add),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 140),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // TOTAL CREDITS
                Text(
                  "Total Credits: $totalCredits",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.onSurface,
                  ),
                ),

                const SizedBox(height: 10),

                LinearProgressIndicator(
                  value:
                      (totalCredits / graduationCredits).clamp(0.0, 1.0),
                ),

                const SizedBox(height: 8),

                Text(
                  "$totalCredits / $graduationCredits credits",
                  style: TextStyle(color: theme.onSurfaceVariant),
                ),
                Text(
                  "Remaining: $remainingCredits credits",
                  style: TextStyle(color: theme.onSurfaceVariant),
                ),

                const SizedBox(height: 20),

                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      semesters.add(Semester(
                          semesterName:
                              "Semester ${semesters.length + 1}",
                          courses: []));
                      currentSemesterIndex =
                          semesters.length - 1;
                    });
                    saveCourses();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("New Semester"),
                ),

                const SizedBox(height: 20),

                // SEMESTERS
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: semesters.length,
                  itemBuilder: (context, index) {
                    final semester = semesters[index];

                    return Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              semester.semesterName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.onSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  currentSemesterIndex =
                                      index;
                                });
                                showAddCourseDialog();
                              },
                              child: const Text("+ Add course"),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        ...semester.courses
                            .asMap()
                            .entries
                            .map((entry) {
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            color: theme.surfaceContainer,
                            child: ListTile(
                              title: Text(
                                capitalizeWords(
                                    entry.value['name']),
                                style: TextStyle(
                                  color: theme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                "${entry.value['credits']} credits",
                                style: TextStyle(
                                  color:
                                      theme.onSurfaceVariant,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color:
                                      theme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  setState(() {
                                    semesters[index]
                                        .courses
                                        .removeAt(
                                            entry.key);
                                  });
                                  saveCourses();
                                },
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}