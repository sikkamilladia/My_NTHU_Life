import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/pet_files/pet_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_nthu_life/main.dart';
import 'package:my_nthu_life/data/semester.dart';

class TaskListPage extends StatefulWidget {
  final String studentID;

  const TaskListPage({super.key, required this.studentID});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List<String> _courseNames = [];
  Map<String, List<dynamic>> _tasksByCourse = {};
  bool _isLoading = true;

  final List<String> _categories = ['Homework', 'Quiz', 'Midterm', 'Final', 'Project', 'Other'];
  
  // State management for tracking the calendar matrix state
  late DateTime _focusedMonth;
  int? _selectedDay; 

  final List<String> _weekLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  final List<String> _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _selectedDay = DateTime.now().day;
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    String? semestersEncoded = prefs.getString("Semesters_${widget.studentID}");
    List<String> extractedCourses = [];

    if (semestersEncoded != null) {
      final List<dynamic> decodedSemesters = jsonDecode(semestersEncoded);
      final List<Semester> semesters = decodedSemesters
          .map((item) => Semester.fromJson(item))
          .toList();

      for (var sem in semesters) {
        for (var course in sem.courses) {
          String name = course['name'] ?? 'Unknown Course';
          if (!extractedCourses.contains(name)) {
            extractedCourses.add(name);
          }
        }
      }
    }

    String? tasksEncoded = prefs.getString("CourseTasks_${widget.studentID}");
    Map<String, List<dynamic>> loadedTasks = {};
    if (tasksEncoded != null) {
      Map<String, dynamic> rawMap = jsonDecode(tasksEncoded);
      rawMap.forEach((key, value) {
        loadedTasks[key] = List<dynamic>.from(value);
      });
    }

    setState(() {
      _courseNames = extractedCourses;
      _tasksByCourse = loadedTasks;
      _isLoading = false;
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(_tasksByCourse);
    await prefs.setString("CourseTasks_${widget.studentID}", encoded);
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Homework': return const Color(0xFF9D4EDD); // Medium Purple
      case 'Quiz': return const Color(0xFFC77DFF);     // Vibrant Light Purple
      case 'Midterm': return const Color(0xFFE0AAFF);  // Pale Lavender
      case 'Final': return const Color(0xFF5A189A);    // Intense Dark Purple
      case 'Project': return const Color(0xFF00CEC9);  // Tech Cyan contrast
      default: return const Color(0xFF7B2CBF);
    }
  }

  bool _dayHasActiveTasks(int day) {
    bool hasTasks = false;
    _tasksByCourse.forEach((course, tasks) {
      for (var task in tasks) {
        if (task['assignedDayString'] == _getDayStringKey(day) && task['isDone'] == false) {
          hasTasks = true;
        }
      }
    });
    return hasTasks;
  }

  String _getDayStringKey(int day) {
    return "${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
  }

  // Google Calendar style Month shifting mechanics
  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      _selectedDay = 1; // Default selector reset anchor point
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
      _selectedDay = 1;
    });
  }

  void _showAddTaskDialog() {
    if (_selectedDay == null) return;
    String taskTitle = "";
    String selectedCategory = _categories.first;
    
    // Initialize with a default value or blank text depending on if courses exist
    String selectedCourse = _courseNames.isNotEmpty ? _courseNames.first : "";
    TextEditingController customCourseController = TextEditingController(text: selectedCourse);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16121E), // Deep Dark Purple Card Background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF3C096C), width: 1.5),
              ),
              title: Text(
                "Assign Matrix Quest", 
                style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: const Color(0xFFE0AAFF), fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dynamic Course Input Selector Block
                    _courseNames.isNotEmpty
                        ? DropdownButtonFormField<String>(
                            dropdownColor: const Color(0xFF16121E),
                            value: selectedCourse,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: "Target Course", 
                              labelStyle: TextStyle(color: Color(0xFFC77DFF)),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3C096C))),
                            ),
                            items: _courseNames.map((name) => DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) { 
                              if (val != null) {
                                setDialogState(() {
                                  selectedCourse = val;
                                  customCourseController.text = val;
                                });
                              }
                            },
                          )
                        : TextField(
                            controller: customCourseController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: "Target Course Name", 
                              labelStyle: TextStyle(color: Color(0xFFC77DFF)),
                              hintText: "e.g. Calculus I",
                              hintStyle: TextStyle(color: Colors.white24),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3C096C))),
                            ),
                          ),
                    const SizedBox(height: 12),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Quest Title", 
                        labelStyle: TextStyle(color: Color(0xFFC77DFF)),
                        hintText: "e.g. Complete Lab Report analysis",
                        hintStyle: TextStyle(color: Colors.white24),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3C096C))),
                      ),
                      onChanged: (value) => taskTitle = value,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF16121E),
                      value: selectedCategory,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Category",
                        labelStyle: TextStyle(color: Color(0xFFC77DFF)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3C096C))),
                      ),
                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) { if (val != null) setDialogState(() => selectedCategory = val); },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    String finalCourseName = customCourseController.text.trim();
                    if (finalCourseName.isEmpty) {
                      finalCourseName = "General Task";
                    }

                    if (taskTitle.trim().isNotEmpty) {
                      setState(() {
                        if (_tasksByCourse[finalCourseName] == null) {
                          _tasksByCourse[finalCourseName] = [];
                        }
                        _tasksByCourse[finalCourseName]!.add({
                          'id': DateTime.now().millisecondsSinceEpoch.toString(),
                          'title': taskTitle.trim(),
                          'category': selectedCategory,
                          'isDone': false,
                          'assignedDayString': _getDayStringKey(_selectedDay!),
                          'exp': 20,
                          'coins': 5,
                        });
                      });
                      _saveTasks();
                    }
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Confirm", 
                    style: GoogleFonts.orbitron(color: const Color(0xFFC77DFF), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgBlack = Color(0xFF0B090A);        // True abyss background
    const Color cardDarkPurple = Color(0xFF16121E); // deep space dark container purple
    const Color neonLightPurple = Color(0xFFC77DFF);

    if (_isLoading) {
      return const Scaffold(backgroundColor: bgBlack, body: Center(child: CircularProgressIndicator(color: neonLightPurple)));
    }

    // Grid calculations
    int daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    int firstWeekdayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday; 
    int prefixEmptyCells = firstWeekdayOfMonth - 1; 
    int totalGridCells = prefixEmptyCells + daysInMonth;

    // Filter list context matching selection index configurations
    List<Map<String, dynamic>> activeDayQuests = [];
    if (_selectedDay != null) {
      String targetKey = _getDayStringKey(_selectedDay!);
      _tasksByCourse.forEach((courseName, tasks) {
        for (var task in tasks) {
          if (task['assignedDayString'] == targetKey) {
            activeDayQuests.add({
              'course': courseName,
              'taskData': task,
            });
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: bgBlack,
        elevation: 0,
        title: Text(
          "TIMELINE ARCHIVE", 
          style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Main Dark Aesthetic Calendar Frame Box
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardDarkPurple, 
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF240046), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Select structural nodes to allocate tasks",
                            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7B2CBF), fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 8),
                          
                          // Google Calendar Style Paging Header Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _monthLabels[_focusedMonth.month - 1],
                                    style: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${_focusedMonth.year}",
                                    style: GoogleFonts.orbitron(fontSize: 14, color: const Color(0xFF9D4EDD)),
                                  ),
                                ],
                              ),
                              // Navigation controls
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left, color: neonLightPurple),
                                    onPressed: _previousMonth,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right, color: neonLightPurple),
                                    onPressed: _nextMonth,
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Days of week header strip
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _weekLabels.map((day) => Expanded(
                              child: Center(
                                child: Text(
                                  day, 
                                  style: GoogleFonts.orbitron(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF5A189A))
                                ),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 12),

                          // Dynamic Month Grid Matrix
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: totalGridCells,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                              childAspectRatio: 1,
								),
                            itemBuilder: (context, index) {
                              if (index < prefixEmptyCells) {
                                return const SizedBox.shrink();
                              }

                              int dayNumber = index - prefixEmptyCells + 1;
                              bool isSelected = dayNumber == _selectedDay;
                              bool hasTask = _dayHasActiveTasks(dayNumber);
                              bool isToday = dayNumber == DateTime.now().day && 
                                             _focusedMonth.month == DateTime.now().month && 
                                             _focusedMonth.year == DateTime.now().year;

                              return GestureDetector(
                                onTap: () => setState(() => _selectedDay = dayNumber),
                                child: Stack(
                                  children: [
                                    // Individual day element tile
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? const Color(0xFF3C096C) 
                                            : (isToday ? const Color(0xFF240046) : Colors.transparent),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? neonLightPurple : (isToday ? const Color(0xFF7B2CBF) : Colors.white10),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          dayNumber.toString().padLeft(2, '0'),
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w400,
                                            color: isSelected ? Colors.white : (isToday ? neonLightPurple : Colors.grey.shade400),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Crown indicator mapping presence overlay
                                    if (hasTask)
                                      const Positioned(
                                        top: 2,
                                        right: 2,
                                        child: Text(
                                          "👑", 
                                          style: TextStyle(fontSize: 8),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Daily Schedule Cards Under the Calendar Frame
                    if (_selectedDay != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 10),
                          child: Text(
                            "SCHEDULED TASKS • ${_monthLabels[_focusedMonth.month - 1].toUpperCase()} $_selectedDay",
                            style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF9D4EDD), letterSpacing: 1),
                          ),
                        ),
                      ),
                      activeDayQuests.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: cardDarkPurple, 
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF16121E))
                              ),
                              child: Center(
                                child: Text(
                                  "No tasks assigned to this timeline node.", 
                                  style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activeDayQuests.length,
                              itemBuilder: (context, index) {
                                final questItem = activeDayQuests[index];
                                final String courseName = questItem['course'];
                                final Map<String, dynamic> task = questItem['taskData'];
                                final String category = task['category'] ?? 'Other';
                                final Color catColor = _getCategoryColor(category);

                                return Card(
                                  color: cardDarkPurple,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: const Color(0xFF240046).withOpacity(0.5))
                                  ),
                                  child: ListTile(
                                    leading: Container(width: 4, height: 26, color: catColor),
                                    title: Text(
                                      task['title'], 
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 15,
                                        decoration: task['isDone'] ? TextDecoration.lineThrough : null,
                                        decorationColor: Colors.grey
                                      )
                                    ),
                                    subtitle: Text(
                                      "${courseName.toUpperCase()} • $category", 
                                      style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 11)
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        task['isDone'] ? Icons.check_circle : Icons.radio_button_off, 
                                        color: task['isDone'] ? Colors.greenAccent : neonLightPurple
                                      ),
                                      onPressed: task['isDone'] ? null : () {
                                        setState(() {
                                          task['isDone'] = true;
                                        });
                                        _saveTasks();
                                        Provider.of<PetProvider>(context, listen: false).awardGrowthPoints(
                                          studentID: widget.studentID, exp: task['exp'], coins: task['coins']
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7B2CBF),
        label: Text("ADD QUEST", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: _showAddTaskDialog,
      ),
    );
  }
}