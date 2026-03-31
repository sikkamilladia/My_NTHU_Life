import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreditPage extends StatefulWidget {
  // identitas halaman
  final String studentID;

  const CreditPage({super.key, required this.studentID});

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  // ====== STATE VARIABLES ======
  List<Map<String, dynamic>> courses = [];
  final int graduationCredits = 128;

  // ====== STORAGE ======
  Future<void> saveCourses() async {
    final prefs = await SharedPreferences.getInstance();

    String encoded = jsonEncode(courses);

    await prefs.setString("courses_${widget.studentID}", encoded);
  }

  Future<void> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    String? encoded = prefs.getString("courses_${widget.studentID}");

    if (encoded != null) {
      setState(() {
        courses = List<Map<String, dynamic>>.from(jsonDecode(encoded));
      });
    }
  }

  // ====== CALCULATIONS ======
  int get totalCredits {
    int sum = 0;

    for (var course in courses) {
      sum += course['credits'] as int;
    }

    return sum;
  }

  int get remainingCredits {
    int remaining = graduationCredits - totalCredits;
    return remaining < 0 ? 0 : remaining;
  }

  // ====== UTIL ======
  String capitalizeWords(String text) {
    return text
        .split(" ")
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : "",
        )
        .join(" ");
  }

  // ====== CRUD ======
  void addCourse(String name, int credits) {
    setState(() {
      courses.add({'name': name, 'credits': credits});
    });

    saveCourses();
  }

  void deleteCourse(int index) {
    setState(() {
      courses.removeAt(index);
    });

    saveCourses();
  }

  // ====== UI HELPERS ======
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
                decoration: const InputDecoration(labelText: "Course Name"),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Credits"),
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

  // ====== BUILD UI ======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          onPressed: showAddCourseDialog,
          child: const Icon(Icons.add),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   "Hello ${widget.studentID}",
            //   style: const TextStyle(fontSize: 20),
            // ),
            // const SizedBox(height: 20),
            Text(
              "Total Credits: $totalCredits",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 10),

            LinearProgressIndicator(
              value: (totalCredits / graduationCredits).clamp(0.0, 1.0),
            ),

            const SizedBox(height: 8),

            Text(
              "$totalCredits / $graduationCredits credits",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              "Remaining: $remainingCredits credits",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Your Courses",
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: courses.isEmpty
                  ? const Center(child: Text("No courses added yet"))
                  : ListView.builder(
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        var course = courses[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: ListTile(
                              title: Text(capitalizeWords(course['name'])),
                              subtitle: Text('${course['credits']} credits'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  deleteCourse(index);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
