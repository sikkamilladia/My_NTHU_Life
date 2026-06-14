import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/pet_files/pet_provider.dart';
import 'package:provider/provider.dart';

class TaskListPage extends StatefulWidget {
  final String studentID;

  const TaskListPage({super.key, required this.studentID});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List<String> _courseNames = [];
  bool _isLoadingCourses = true;

  final List<String> _categories = [
    'Class',
    'Homework',
    'Quiz',
    'Lab',
    'Midterm',
    'Final',
    'Project',
    'Other',
  ];

  late DateTime _focusedMonth;
  int? _selectedDay;

  final List<String> _weekLabels = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];
  final List<String> _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _selectedDay = DateTime.now().day;
    _fetchCourseList();
  }

  Future<void> _fetchCourseList() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .collection('courses')
          .get();

      final courses = snapshot.docs
          .map((doc) => doc.data()['name'] as String? ?? 'Unknown Course')
          .toSet()
          .toList();

      setState(() {
        _courseNames = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() => _isLoadingCourses = false);
    }
  }

  int _calculateExpForCategory(String category) {
    switch (category) {
      case 'Class':
        return 3;
      case 'Homework':
        return 5;
      case 'Quiz':
      case 'Lab':
        return 10;
      case 'Midterm':
      case 'Final':
        return 20;
      default:
        return 10;
    }
  }

  int _calculateCoinsForCategory(String category) {
    return (_calculateExpForCategory(category) / 2).floor().clamp(1, 10);
  }

  String _getDayStringKey(int day) {
    return "${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      _selectedDay = 1;
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
      _selectedDay = 1;
    });
  }

  Color _getCategoryColor(String category) {
    // Category colors are semantic/fixed — kept as explicit constants
    switch (category) {
      case 'Class':
        return const Color(0xFFA594F9);
      case 'Homework':
        return const Color(0xFF9D4EDD);
      case 'Quiz':
        return const Color(0xFFC77DFF);
      case 'Lab':
        return const Color(0xFF00CEC9);
      case 'Midterm':
        return const Color(0xFFE0AAFF);
      case 'Final':
        return const Color(0xFF5A189A);
      case 'Project':
        return const Color(0xFF64DFDF);
      default:
        return const Color(0xFF7B2CBF);
    }
  }

  void _showAddTaskDialog(ColorScheme cs) {
    if (_selectedDay == null) return;
    String taskTitle = "";
    String selectedCategory = _categories.first;
    String selectedCourse = _courseNames.isNotEmpty
        ? _courseNames.first
        : "General Task";
    TextEditingController customCourseController = TextEditingController(
      text: selectedCourse,
    );

    // New recurrence variables
    String selectedRepeat = "None"; // None, Daily, Weekly
    List<int> selectedWeekdays = []; // 1=Mon, ..., 7=Sun

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: cs.surfaceBright, width: 1.5),
              ),
              title: Text(
                "Assign Matrix Quest",
                style: GoogleFonts.orbitron(
                  fontWeight: FontWeight.bold,
                  color: cs.primaryContainer,
                  fontSize: 16,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _courseNames.isNotEmpty
                        ? DropdownButtonFormField<String>(
                            dropdownColor: cs.surfaceContainerLow,
                            value: selectedCourse,
                            style: GoogleFonts.outfit(color: cs.onSurface),
                            decoration: InputDecoration(
                              labelText: "Target Course",
                              labelStyle: TextStyle(color: cs.primaryContainer),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: cs.surfaceBright),
                              ),
                            ),
                            items: _courseNames
                                .map(
                                  (name) => DropdownMenuItem(
                                    value: name,
                                    child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
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
                            style: TextStyle(color: cs.onSurface),
                            decoration: InputDecoration(
                              labelText: "Target Course Name",
                              labelStyle: TextStyle(color: cs.primaryContainer),
                              hintText: "e.g. Operating Systems",
                              hintStyle: TextStyle(
                                color: cs.onSurface.withOpacity(0.24),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: cs.surfaceBright),
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    TextField(
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText: "Quest Title",
                        labelStyle: TextStyle(color: cs.primaryContainer),
                        hintText: "e.g. Complete Lab Report analysis",
                        hintStyle: TextStyle(
                          color: cs.onSurface.withOpacity(0.24),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: cs.surfaceBright),
                        ),
                      ),
                      onChanged: (value) => taskTitle = value,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: cs.surfaceContainerLow,
                      value: selectedCategory,
                      style: GoogleFonts.outfit(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText: "Category",
                        labelStyle: TextStyle(color: cs.primaryContainer),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: cs.surfaceBright),
                        ),
                      ),
                      items: _categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setDialogState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: cs.surfaceContainerLow,
                      value: selectedRepeat,
                      style: GoogleFonts.outfit(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText: "Repeat",
                        labelStyle: TextStyle(color: cs.primaryContainer),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: cs.surfaceBright),
                        ),
                      ),
                      items: ["None", "Daily", "Weekly"]
                          .map(
                            (rep) =>
                                DropdownMenuItem(value: rep, child: Text(rep)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setDialogState(() => selectedRepeat = val);
                      },
                    ),
                    if (selectedRepeat == "Weekly") ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Repeat on",
                          style: GoogleFonts.outfit(
                            color: cs.primaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          int weekday = index + 1;
                          bool isSelected = selectedWeekdays.contains(weekday);
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                if (isSelected) {
                                  selectedWeekdays.remove(weekday);
                                } else {
                                  selectedWeekdays.add(weekday);
                                }
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? cs.primaryContainer
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? cs.primaryContainer
                                      : cs.outline,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _weekLabels[index].substring(0, 1),
                                  style: GoogleFonts.orbitron(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? cs.onPrimaryContainer
                                        : cs.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
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
                  onPressed: () async {
                    String finalCourseName = customCourseController.text.trim();
                    if (finalCourseName.isEmpty)
                      finalCourseName = "General Task";

                    if (taskTitle.trim().isNotEmpty) {
                      final computedExp = _calculateExpForCategory(
                        selectedCategory,
                      );
                      final computedCoins = _calculateCoinsForCategory(
                        selectedCategory,
                      );

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.studentID)
                          .collection('tasks')
                          .add({
                            'title': taskTitle.trim(),
                            'course': finalCourseName,
                            'category': selectedCategory,
                            'assignedDayString': _getDayStringKey(
                              _selectedDay!,
                            ),
                            'repeatType': selectedRepeat,
                            'repeatDays': selectedWeekdays,
                            'exp': computedExp,
                            'coins': computedCoins,
                            'isDone': false,
                            'completedDates':
                                [], // Track completion for recurring tasks
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text(
                    "Confirm",
                    style: GoogleFonts.orbitron(
                      color: cs.primaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
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
    final cs = Theme.of(context).colorScheme;

    if (_isLoadingCourses) {
      return Scaffold(
        // surface = bgBlack (#0B090A)
        backgroundColor: cs.surface,
        body: Center(
          child: CircularProgressIndicator(color: cs.primaryContainer),
        ),
      );
    }

    int daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    int firstWeekdayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    ).weekday;
    int prefixEmptyCells = firstWeekdayOfMonth - 1;
    int totalGridCells = prefixEmptyCells + daysInMonth;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .collection('tasks')
          .snapshots(),
      builder: (context, snapshot) {
        final Map<String, List<DocumentSnapshot>> tasksByDay = {};

        if (snapshot.hasData) {
          // Get all days in the current focused month to populate tasksByDay
          int daysInMonth = DateUtils.getDaysInMonth(
            _focusedMonth.year,
            _focusedMonth.month,
          );

          for (int d = 1; d <= daysInMonth; d++) {
            String dayKey = _getDayStringKey(d);
            DateTime date = DateTime(
              _focusedMonth.year,
              _focusedMonth.month,
              d,
            );
            int weekday = date.weekday; // 1=Mon, ..., 7=Sun

            for (var doc in snapshot.data!.docs) {
              final data = doc.data();
              final assignedDayStr = data['assignedDayString'] as String? ?? '';
              final repeatType = data['repeatType'] as String? ?? 'None';
              final repeatDays = List<int>.from(data['repeatDays'] ?? []);

              bool applies = false;
              if (repeatType == 'None') {
                if (assignedDayStr == dayKey) applies = true;
              } else {
                // For recurring tasks, they must start on or after assignedDayString
                if (dayKey.compareTo(assignedDayStr) >= 0) {
                  if (repeatType == 'Daily') {
                    applies = true;
                  } else if (repeatType == 'Weekly') {
                    if (repeatDays.contains(weekday)) applies = true;
                  }
                }
              }

              if (applies) {
                tasksByDay.putIfAbsent(dayKey, () => []).add(doc);
              }
            }
          }
        }

        final selectedTargetKey = _selectedDay != null
            ? _getDayStringKey(_selectedDay!)
            : '';
        final activeDayDocs = tasksByDay[selectedTargetKey] ?? [];

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface,
            elevation: 0,
            title: Text(
              "TIMELINE ARCHIVE",
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
                letterSpacing: 1.5,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(24),
                            // outlineVariant = subtle card border (#240046)
                            border: Border.all(
                              color: cs.outlineVariant,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Select structural nodes to allocate tasks",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  // outline = active purple (#7B2CBF)
                                  color: cs.outline,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _monthLabels[_focusedMonth.month - 1],
                                        style: GoogleFonts.orbitron(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${_focusedMonth.year}",
                                        style: GoogleFonts.orbitron(
                                          fontSize: 14,
                                          // inversePrimary = section label purple (#9D4EDD)
                                          color: cs.inversePrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.chevron_left,
                                          color: cs.primaryContainer,
                                        ),
                                        onPressed: _previousMonth,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.chevron_right,
                                          color: cs.primaryContainer,
                                        ),
                                        onPressed: _nextMonth,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: _weekLabels
                                    .map(
                                      (day) => Expanded(
                                        child: Center(
                                          child: Text(
                                            day,
                                            style: GoogleFonts.orbitron(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              // surfaceBright doubles as deep purple accent (#3C096C → too dark)
                                              // use outline for week labels for legibility
                                              color: cs.outline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: totalGridCells,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,
                                      mainAxisSpacing: 6,
                                      crossAxisSpacing: 6,
                                      childAspectRatio: 1,
                                    ),
                                itemBuilder: (context, index) {
                                  if (index < prefixEmptyCells)
                                    return const SizedBox.shrink();

                                  int dayNumber = index - prefixEmptyCells + 1;
                                  bool isSelected = dayNumber == _selectedDay;
                                  String loopDayKey = _getDayStringKey(
                                    dayNumber,
                                  );
                                  bool hasTask =
                                      tasksByDay.containsKey(loopDayKey) &&
                                      tasksByDay[loopDayKey]!.isNotEmpty;
                                  bool isToday =
                                      dayNumber == DateTime.now().day &&
                                      _focusedMonth.month ==
                                          DateTime.now().month &&
                                      _focusedMonth.year == DateTime.now().year;

                                  return GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedDay = dayNumber,
                                    ),
                                    child: Stack(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? cs
                                                      .surfaceBright // #3C096C selected
                                                : (isToday
                                                      ? cs
                                                            .outlineVariant // #240046 today
                                                      : Colors.transparent),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? cs
                                                        .primaryContainer // #C77DFF selected border
                                                  : (isToday
                                                        ? cs
                                                              .outline // #7B2CBF today border
                                                        : Colors.white10),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              dayNumber.toString().padLeft(
                                                2,
                                                '0',
                                              ),
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                fontWeight:
                                                    isSelected || isToday
                                                    ? FontWeight.bold
                                                    : FontWeight.w400,
                                                color: isSelected
                                                    ? cs
                                                          .onSurface // white
                                                    : (isToday
                                                          ? cs
                                                                .primaryContainer // #C77DFF
                                                          : cs.onSurfaceVariant), // grey
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (hasTask)
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: cs.surfaceContainerLow
                                                    .withOpacity(0.8),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFFFD700,
                                                  ).withOpacity(0.3),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: const Text(
                                                "👑",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  shadows: [
                                                    Shadow(
                                                      color: Color(0xFFFFD700),
                                                      blurRadius: 6,
                                                    ),
                                                  ],
                                                ),
                                              ),
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
                        if (_selectedDay != null) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 4.0,
                                bottom: 10,
                              ),
                              child: Text(
                                "SCHEDULED TASKS • ${_monthLabels[_focusedMonth.month - 1].toUpperCase()} $_selectedDay",
                                style: GoogleFonts.orbitron(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cs.inversePrimary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          activeDayDocs.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "No tasks assigned to this timeline node.",
                                      style: GoogleFonts.outfit(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: activeDayDocs.length,
                                  itemBuilder: (context, index) {
                                    final doc = activeDayDocs[index];
                                    final task =
                                        doc.data() as Map<String, dynamic>;

                                    final String courseName =
                                        task['course'] ?? 'General';
                                    final String category =
                                        task['category'] ?? 'Other';
                                    final Color catColor = _getCategoryColor(
                                      category,
                                    );

                                    final repeatType =
                                        task['repeatType'] as String? ?? 'None';
                                    final completedDates = List<String>.from(
                                      task['completedDates'] ?? [],
                                    );
                                    final isDone = repeatType == 'None'
                                        ? (task['isDone'] ?? false)
                                        : completedDates.contains(
                                            selectedTargetKey,
                                          );

                                    return Dismissible(
                                      key: Key(doc.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade800,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 20,
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                        ),
                                      ),
                                      confirmDismiss: (_) async {
                                        return await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor:
                                                    cs.surfaceContainerLow,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  side: BorderSide(
                                                    color: cs.surfaceBright,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                title: Text(
                                                  'DELETE QUEST?',
                                                  style: GoogleFonts.orbitron(
                                                    color: cs.error,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                content: Text(
                                                  'This quest will be permanently removed.',
                                                  style: GoogleFonts.outfit(
                                                    color: cs.onSurfaceVariant,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                    child: Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                        color:
                                                            cs.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
                                                    child: Text(
                                                      'Delete',
                                                      style:
                                                          GoogleFonts.orbitron(
                                                            color: cs.error,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ) ??
                                            false;
                                      },
                                      onDismissed: (_) async {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(widget.studentID)
                                            .collection('tasks')
                                            .doc(doc.id)
                                            .delete();
                                      },
                                      child: Card(
                                        color: cs.surfaceContainerLow,
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          side: BorderSide(
                                            color: cs.outlineVariant
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: Container(
                                            width: 4,
                                            height: 26,
                                            color: catColor,
                                          ),
                                          title: Text(
                                            task['title'] ?? '',
                                            style: GoogleFonts.outfit(
                                              color: cs.onSurface,
                                              fontSize: 15,
                                              decoration: isDone
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              decorationColor: Colors.grey,
                                            ),
                                          ),
                                          subtitle: Text(
                                            "${courseName.toUpperCase()} • $category${repeatType != 'None' ? ' ($repeatType)' : ''}",
                                            style: GoogleFonts.outfit(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(
                                              isDone
                                                  ? Icons.check_circle
                                                  : Icons.radio_button_off,
                                              color: isDone
                                                  ? Colors.greenAccent
                                                  : cs.primary,
                                            ),
                                            onPressed: () async {
                                              final int expGained = task['exp'] ?? 0;

                                              if (repeatType == 'None') {
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(widget.studentID)
                                                    .collection('tasks')
                                                    .doc(doc.id)
                                                    .update({
                                                  'isDone': !isDone,
                                                });

                                                if (!isDone) {
                                                  await FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(widget.studentID)
                                                      .set({
                                                    'weeklyXP': FieldValue.increment(expGained),
                                                  }, SetOptions(merge: true));

                                                  final partyQuery = await FirebaseFirestore.instance
                                                      .collection('parties')
                                                      .where(
                                                        'memberIDs',
                                                        arrayContains: widget.studentID,
                                                      )
                                                      .limit(1)
                                                      .get();

                                                  if (partyQuery.docs.isNotEmpty) {
                                                    await partyQuery.docs.first.reference.update({
                                                      'totalWeeklyXP':
                                                          FieldValue.increment(expGained),
                                                    });
                                                  }
                                                }
                                              } else {
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(widget.studentID)
                                                    .collection('tasks')
                                                    .doc(doc.id)
                                                    .update({
                                                  'completedDates': isDone
                                                      ? FieldValue.arrayRemove([
                                                          selectedTargetKey,
                                                        ])
                                                      : FieldValue.arrayUnion([
                                                          selectedTargetKey,
                                                        ]),
                                                });
                                              }
                                            },
                                          ),
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
            // outline = FAB purple (#7B2CBF)
            backgroundColor: cs.outline,
            label: Text(
              "ADD QUEST",
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.bold,
                color: cs.onPrimary,
                fontSize: 12,
              ),
            ),
            icon: Icon(Icons.add, color: cs.onPrimary),
            onPressed: () => _showAddTaskDialog(cs),
          ),
        );
      },
    );
  }
}
