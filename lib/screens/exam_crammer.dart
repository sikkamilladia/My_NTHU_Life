import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:my_nthu_life/services/ai_service.dart';
import 'package:my_nthu_life/pet_files/pet_provider.dart';
import 'package:my_nthu_life/screens/study.dart'; // To reuse YoutubePlayerScreen

class AdaptiveExamCrammerScreen extends StatefulWidget {
  final String studentID;
  const AdaptiveExamCrammerScreen({super.key, required this.studentID});

  @override
  State<AdaptiveExamCrammerScreen> createState() => _AdaptiveExamCrammerScreenState();
}

class _AdaptiveExamCrammerScreenState extends State<AdaptiveExamCrammerScreen> {
  final TextEditingController _syllabusController = TextEditingController();
  final TextEditingController _slidesController = TextEditingController();
  
  String? _selectedCourse;
  List<String> _availableCourses = [];
  bool _isLoadingAvailableCourses = true;

  // Study schedule state
  List<dynamic> _schedule = [];
  bool _isGeneratingSchedule = false;
  int _selectedDayIndex = 0;
  List<String> _terminalLogs = [];
  bool _isRescuingActive = false;

  // Form autocomplete state
  bool _isAutoGeneratingMaterial = false;

  // Active quiz state
  int? _activeQuizDayIndex;
  int _currentQuestionIndex = 0;
  List<String?> _selectedQuizAnswers = [];
  bool _showQuizResults = false;
  int _quizScore = 0;

  // Recalibration state
  bool _isRecalibrating = false;
  String _recalibrationStatusText = "Connecting with Gemini intelligence...";

  @override
  void initState() {
    super.initState();
    _fetchAvailableCourses();
  }

  @override
  void dispose() {
    _syllabusController.dispose();
    _slidesController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableCourses() async {
    setState(() => _isLoadingAvailableCourses = true);
    try {
      // Fetching classes from the user's task history as done in study.dart
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .collection('tasks')
          .where('category', isEqualTo: 'Class')
          .get();

      final courses = snapshot.docs
          .map((doc) => doc.data()['course'] as String? ?? 'General')
          .toSet()
          .toList();

      // Filter out empty or duplicate generic ones
      courses.removeWhere((c) => c.trim().isEmpty);

      // Default high-fidelity academic classes for fallbacks
      final List<String> defaultCourses = [
        "Data Structures & Algorithms",
        "Operating Systems",
        "Introduction to Artificial Intelligence",
        "Computer Networks",
        "Software Engineering",
      ];

      for (var d in defaultCourses) {
        if (!courses.contains(d)) {
          courses.add(d);
        }
      }

      setState(() {
        _availableCourses = courses;
        _selectedCourse = _availableCourses.first;
        _isLoadingAvailableCourses = false;
      });

      // Try loading any pre-existing crammer session from Firestore to resume
      _loadExistingCrammerSession();
    } catch (e) {
      print("Error fetching courses: $e");
      setState(() => _isLoadingAvailableCourses = false);
    }
  }

  Future<void> _loadExistingCrammerSession() async {
    if (_selectedCourse == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .collection('exam_crammers')
          .doc(_selectedCourse)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _schedule = data['schedule'] ?? [];
          _selectedDayIndex = data['selectedDayIndex'] ?? 0;
        });
      }
    } catch (e) {
      print("Error loading crammer session: $e");
    }
  }

  Future<void> _saveCrammerSession() async {
    if (_selectedCourse == null || _schedule.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .collection('exam_crammers')
          .doc(_selectedCourse)
          .set({
            'courseName': _selectedCourse,
            'schedule': _schedule,
            'selectedDayIndex': _selectedDayIndex,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving crammer session: $e");
    }
  }

  Future<void> _autoGenerateSyllabusAndSlides() async {
    if (_selectedCourse == null) return;
    setState(() {
      _isAutoGeneratingMaterial = true;
    });

    try {
      final res = await AIService.generateCrammerSyllabusAndSlides(
        courseName: _selectedCourse!,
      );

      if (res.isNotEmpty) {
        setState(() {
          _syllabusController.text = res['syllabus'] ?? "";
          _slidesController.text = res['slides'] ?? "";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✨ Mock Syllabus & Slide Outline Decoded for $_selectedCourse!"),
            backgroundColor: Colors.purpleAccent,
          ),
        );
      }
    } catch (e) {
      print("Error auto generating syllabus/slides: $e");
    } finally {
      setState(() {
        _isAutoGeneratingMaterial = false;
      });
    }
  }

  Future<void> _generateCrammerRoute() async {
    if (_selectedCourse == null) return;
    if (_syllabusController.text.trim().isEmpty || _slidesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please provide both Syllabus and Slide materials first!"),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingSchedule = true;
      _isRescuingActive = true;
      _terminalLogs = [
        "🤖 [CRAMMER AGENT] Booting Rescue System...",
        "🔍 [SCANNER] Analyzing syllabus & slide outline for vague/hidden concepts...",
      ];
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      final obscureTerms = await AIService.scanForObscureTerms(
        courseName: _selectedCourse!,
        syllabusText: _syllabusController.text.trim(),
        slidesText: _slidesController.text.trim(),
      );

      final List<Map<String, dynamic>> rescuedResults = [];

      if (obscureTerms.isNotEmpty) {
        setState(() {
          _terminalLogs.add("⚠️ [GAP DETECTED] Found ${obscureTerms.length} obscure term(s) lacking description!");
          for (var t in obscureTerms) {
            _terminalLogs.add("  👉 \"${t['term']}\" (Reason: ${t['reason'] ?? "No reason specified"})");
          }
          _terminalLogs.add("🛑 [PAUSE] Halting curriculum generation temporarily to prevent hallucinations.");
          _terminalLogs.add("🌐 [WEB SEARCH] Activating Grounding Search Tool...");
        });

        for (var t in obscureTerms) {
          final String termName = t['term'] ?? "Unknown Concept";
          final String query = t['search_query'] ?? termName;
          
          await Future.delayed(const Duration(milliseconds: 1000));
          setState(() {
            _terminalLogs.add("🔍 [SEARCHING] Querying: \"$query\"");
          });

          final rescuedData = await AIService.rescueConceptWithSearch(
            term: termName,
            searchQuery: query,
          );

          rescuedResults.add(rescuedData);

          setState(() {
            _terminalLogs.addAll([
              "✅ [RESCUED] Grounded facts retrieved for \"$termName\"",
              "   └─ Source: ${rescuedData['source'] ?? "Google Search Grounding"}",
            ]);
          });
        }
      } else {
        setState(() {
          _terminalLogs.add("✅ [SCANNER] No obscure concepts found! All terms are self-explanatory.");
        });
      }

      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _terminalLogs.addAll([
          "⚙️ [BUILD] Injecting rescued context back into NTHU CS curriculum compiler...",
          "📅 [BUILD] Designing customized 5-day study modules & daily quizzes...",
        ]);
      });

      final res = await AIService.generateAdaptiveCrammerSchedule(
        courseName: _selectedCourse!,
        syllabusText: _syllabusController.text.trim(),
        slidesText: _slidesController.text.trim(),
        rescuedContexts: rescuedResults,
      );

      if (res.containsKey('schedule') && res['schedule'] is List) {
        final List<dynamic> rawSchedule = res['schedule'];
        final List<Map<String, dynamic>> processedSchedule = [];

        for (int i = 0; i < rawSchedule.length; i++) {
          final dayData = Map<String, dynamic>.from(rawSchedule[i]);
          dayData['status'] = i == 0 ? 'current' : 'locked';
          processedSchedule.add(dayData);
        }

        setState(() {
          _terminalLogs.add("🎉 [SUCCESS] 5-Day Crammer Schedule successfully compiled with grounded rescue modules!");
        });
        
        await Future.delayed(const Duration(milliseconds: 1200));

        setState(() {
          _schedule = processedSchedule;
          _selectedDayIndex = 0;
          _isRescuingActive = false;
          _isGeneratingSchedule = false;
        });

        await _saveCrammerSession();
      } else {
        setState(() {
          _terminalLogs.add("❌ [ERROR] Failed to compile schedule JSON structure.");
          _isRescuingActive = false;
          _isGeneratingSchedule = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to parse schedule JSON. Please try again!"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print("Error generating crammer route: $e");
      setState(() {
        _terminalLogs.add("❌ [ERROR] Concept rescue or compiler crashed: $e");
        _isRescuingActive = false;
        _isGeneratingSchedule = false;
      });
    }
  }

  void _startDailyQuiz(int dayIndex) {
    final quiz = _schedule[dayIndex]['quiz'] as List<dynamic>? ?? [];
    if (quiz.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No quiz available for this day."),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() {
      _activeQuizDayIndex = dayIndex;
      _currentQuestionIndex = 0;
      _selectedQuizAnswers = List<String?>.filled(quiz.length, null);
      _showQuizResults = false;
      _quizScore = 0;
    });
  }

  void _submitQuiz() {
    final quiz = _schedule[_activeQuizDayIndex!]['quiz'] as List<dynamic>;
    int score = 0;
    for (int i = 0; i < quiz.length; i++) {
      final correctAnswer = quiz[i]['answer'].toString().trim().toLowerCase();
      final userAnswer = (_selectedQuizAnswers[i] ?? "").toString().trim().toLowerCase();
      if (userAnswer == correctAnswer) {
        score++;
      }
    }

    setState(() {
      _quizScore = score;
      _showQuizResults = true;
    });
  }

  Future<void> _completeQuizFlow() async {
    final dayIndex = _activeQuizDayIndex!;
    final totalQuestions = (_schedule[dayIndex]['quiz'] as List<dynamic>).length;
    final bool passed = _quizScore >= (totalQuestions / 2).round(); // standard pass criteria (e.g., 3/5)

    if (passed) {
      // Award Gamified growth points to pet & user
      Provider.of<PetProvider>(context, listen: false)
          .awardGrowthPoints(studentID: widget.studentID, exp: 25, coins: 10);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .set({
            'weeklyXP': FieldValue.increment(25),
          }, SetOptions(merge: true));

      setState(() {
        _schedule[dayIndex]['status'] = 'completed';
        
        // Unlock next day if locked
        if (dayIndex + 1 < _schedule.length) {
          if (_schedule[dayIndex + 1]['status'] == 'locked') {
            _schedule[dayIndex + 1]['status'] = 'current';
          }
        }
        _activeQuizDayIndex = null;
      });

      await _saveCrammerSession();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🏆 DAY MASTERED! +25 XP and +10 Coins awarded!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // FAIL TRIGGER - Putar Otak / Recalibration Agentic Loop
      setState(() {
        _activeQuizDayIndex = null;
        _isRecalibrating = true;
        _recalibrationStatusText = "Evaluating performance & mistakes...";
      });

      // Find failed and mastered topics from the quiz questions
      final quiz = _schedule[dayIndex]['quiz'] as List<dynamic>;
      final List<String> failedTopics = [];
      final List<String> masteredTopics = [];

      for (int i = 0; i < quiz.length; i++) {
        final qTopic = quiz[i]['question'].toString();
        // Just extract basic key terms or the question's focus
        final qTerms = qTopic.split(' ').take(4).join(' ');
        final isCorrect = (_selectedQuizAnswers[i] ?? "").toString().trim().toLowerCase() == 
                          quiz[i]['answer'].toString().trim().toLowerCase();
        
        if (isCorrect) {
          masteredTopics.add(qTerms);
        } else {
          failedTopics.add(qTerms);
        }
      }

      if (failedTopics.isEmpty) failedTopics.add("Core concept evaluation");
      if (masteredTopics.isEmpty) masteredTopics.add("Introductory concepts");

      // Animated steps for agent "thinking"
      _runRecalibrationAnimation(dayIndex, failedTopics, masteredTopics);
    }
  }

  void _runRecalibrationAnimation(int dayIndex, List<String> failed, List<String> mastered) async {
    const statuses = [
      "Analyzing quiz failure telemetry...",
      "Isolating exact conceptual weak points...",
      "Formulating customized deep-dive remedial module...",
      "Trimming redundant syllabus topics to conserve time...",
      "Compiling tailored explanation summaries...",
      "Syncing supplementary video resources from YouTube...",
      "Formulating an optimized 5-day war path..."
    ];

    for (var status in statuses) {
      if (!mounted) return;
      setState(() {
        _recalibrationStatusText = status;
      });
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    try {
      final res = await AIService.recalibrateCrammerSchedule(
        courseName: _selectedCourse!,
        currentSchedule: _schedule,
        failedDay: dayIndex + 1, // 1-based index
        failedTopics: failed,
        masteredTopics: mastered,
      );

      if (res.containsKey('schedule') && res['schedule'] is List) {
        final List<dynamic> updatedSchedule = res['schedule'];

        // Make sure we keep the completed state of previous days, but update statuses appropriately
        for (int i = 0; i < updatedSchedule.length; i++) {
          if (i < dayIndex) {
            updatedSchedule[i]['status'] = 'completed';
          } else if (i == dayIndex) {
            // Mark the failed day as adapted/re-routed so the user can re-study
            updatedSchedule[i]['status'] = 'adapted';
          } else if (i == dayIndex + 1) {
            updatedSchedule[i]['status'] = 'current'; // next day unlocked
          } else {
            updatedSchedule[i]['status'] = 'locked';
          }
        }

        setState(() {
          _schedule = updatedSchedule;
          _selectedDayIndex = dayIndex; // Keep focus on this day to let them study
          _isRecalibrating = false;
        });

        await _saveCrammerSession();

        _showRecalibrationCompletionDialog(failed.first);
      } else {
        setState(() => _isRecalibrating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error parsing calibrated plan. Retrying normal state."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print("Recalibration error: $e");
      setState(() => _isRecalibrating = false);
    }
  }

  void _showRecalibrationCompletionDialog(String weakness) {
    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.amber.withOpacity(0.5), width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.alt_route_rounded, color: Colors.amber),
              const SizedBox(width: 10),
              Text(
                "PATH RECALIBRATED",
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          content: Text(
            "Gemini identified a critical bottleneck in your understanding of the '$weakness' area. The agent has trimmed mastered topics and restructured your remaining study modules to focus heavily on this weakness.",
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: cs.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "ENTER DEEP-DIVE",
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: cs.primaryContainer,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetCrammer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: Text(
          "RESET PLAN",
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        content: const Text("Are you sure you want to completely erase this 5-day plan and start fresh?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text("RESET"),
          ),
        ],
      ),
    );

    if (confirm == true && _selectedCourse != null) {
      setState(() {
        _schedule = [];
        _selectedDayIndex = 0;
        _syllabusController.clear();
        _slidesController.clear();
      });

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.studentID)
            .collection('exam_crammers')
            .doc(_selectedCourse)
            .delete();
      } catch (e) {
        print("Error resetting Firestore session: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isGeneratingSchedule) {
      return _buildGeneratingOverlay(cs);
    }

    if (_isRecalibrating) {
      return _buildRecalibratingOverlay(cs);
    }

    if (_activeQuizDayIndex != null) {
      return _buildQuizInterface(cs);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "CRAMMER WAR ROOM",
          style: GoogleFonts.orbitron(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_schedule.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent),
              tooltip: "Reset current plan",
              onPressed: _resetCrammer,
            ),
        ],
      ),
      body: SafeArea(
        child: _schedule.isEmpty ? _buildIngestionForm(cs) : _buildCrammerTimelineBoard(cs),
      ),
    );
  }

  Widget _buildGeneratingOverlay(ColorScheme cs) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0B16), // Cyber dark background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.purpleAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent,
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "AGENT CONSOLE: ACTIVE_RESCUE_PROT",
                    style: GoogleFonts.orbitron(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.purpleAccent,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Console Output Terminal
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05030A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                  ),
                  child: ListView.builder(
                    reverse: false,
                    itemCount: _terminalLogs.length,
                    itemBuilder: (context, index) {
                      final log = _terminalLogs[index];
                      Color logColor = Colors.greenAccent;
                      if (log.startsWith("⚠️") || log.startsWith("🛑")) {
                        logColor = Colors.amberAccent;
                      } else if (log.startsWith("🤖") || log.startsWith("⚙️") || log.startsWith("📅")) {
                        logColor = Colors.purpleAccent;
                      } else if (log.startsWith("❌")) {
                        logColor = Colors.redAccent;
                      } else if (log.startsWith("🎉")) {
                        logColor = Colors.greenAccent;
                      } else if (log.startsWith("  👉") || log.startsWith("   └─")) {
                        logColor = Colors.white70;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          log,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 11,
                            color: logColor,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "AGENT IS RESCUING ACADEMIC CONTEXT...",
                    style: GoogleFonts.orbitron(
                      fontSize: 9,
                      color: Colors.purpleAccent.withOpacity(0.7),
                      letterSpacing: 1,
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

  Widget _buildRecalibratingOverlay(ColorScheme cs) {
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withOpacity(0.1),
                  border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  color: Colors.amber,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "AGENT RE-ROUTING SCHEDULE",
                style: GoogleFonts.orbitron(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "PUTAR OTAK PROTOCOL IN PROGRESS",
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              LinearProgressIndicator(
                color: Colors.amber,
                backgroundColor: cs.surfaceContainerLowest,
              ),
              const SizedBox(height: 16),
              Text(
                _recalibrationStatusText,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: cs.onSurface,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngestionForm(ColorScheme cs) {
    if (_isLoadingAvailableCourses) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer.withOpacity(0.12), cs.surfaceContainerLow],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primaryContainer.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: cs.primaryContainer, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ADAPTIVE EXAM CRAMMER",
                        style: GoogleFonts.orbitron(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: cs.primaryContainer,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Upload details once, get a modular 5-day curriculum. The AI instantly rewires upcoming days based on daily quiz diagnostics.",
                        style: GoogleFonts.outfit(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "SELECT TARGET SUBJECT",
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cs.primaryContainer,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCourse,
                isExpanded: true,
                dropdownColor: cs.surfaceContainerHigh,
                items: _availableCourses.map((course) {
                  return DropdownMenuItem<String>(
                    value: course,
                    child: Text(
                      course,
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCourse = val;
                  });
                  _loadExistingCrammerSession();
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SYLLABUS DETAILS",
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: cs.primaryContainer,
                  letterSpacing: 1,
                ),
              ),
              _isAutoGeneratingMaterial
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.primaryContainer),
                    )
                  : InkWell(
                      onTap: _autoGenerateSyllabusAndSlides,
                      child: Row(
                        children: [
                          Icon(Icons.auto_fix_high_rounded, size: 14, color: cs.primaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            "AUTO-GENERATE",
                            style: GoogleFonts.orbitron(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: cs.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _syllabusController,
            maxLines: 5,
            style: GoogleFonts.outfit(fontSize: 12),
            decoration: InputDecoration(
              hintText: "Paste exam blueprint, topics, syllabus, or grading weights...",
              hintStyle: GoogleFonts.outfit(color: cs.onSurfaceVariant.withOpacity(0.5), fontSize: 12),
              filled: true,
              fillColor: cs.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "LECTURE SLIDES OUTLINE",
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cs.primaryContainer,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _slidesController,
            maxLines: 5,
            style: GoogleFonts.outfit(fontSize: 12),
            decoration: InputDecoration(
              hintText: "Paste lecture notes, slide bullet points, or chapter summaries...",
              hintStyle: GoogleFonts.outfit(color: cs.onSurfaceVariant.withOpacity(0.5), fontSize: 12),
              filled: true,
              fillColor: cs.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              onPressed: _generateCrammerRoute,
              child: Text(
                "GENERATE 5-DAY CRASH PATH",
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrammerTimelineBoard(ColorScheme cs) {
    final currentDayData = _schedule[_selectedDayIndex];
    final String dayTitle = currentDayData['title'] ?? "Study Block";
    final List<dynamic> topics = currentDayData['topics'] ?? [];
    final String summary = currentDayData['summary'] ?? "No summary available.";
    final List<dynamic> videos = currentDayData['videos'] ?? [];
    final String status = currentDayData['status'] ?? 'locked';

    return Column(
      children: [
        // Horizontal Days timeline
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final dayNum = index + 1;
              final dayStatus = _schedule[index]['status'] ?? 'locked';
              final isSelected = index == _selectedDayIndex;

              Color circleBg = cs.surfaceContainerHighest;
              Color borderCol = Colors.transparent;
              Widget icon = Text(
                "$dayNum",
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurfaceVariant,
                ),
              );

              if (dayStatus == 'completed') {
                circleBg = Colors.green.withOpacity(0.15);
                borderCol = Colors.green.withOpacity(0.5);
                icon = const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18);
              } else if (dayStatus == 'adapted') {
                circleBg = Colors.amber.withOpacity(0.15);
                borderCol = Colors.amber;
                icon = const Icon(Icons.alt_route_rounded, color: Colors.amber, size: 16);
              } else if (dayStatus == 'current') {
                circleBg = cs.primaryContainer.withOpacity(0.12);
                borderCol = cs.primaryContainer;
              }

              if (isSelected) {
                borderCol = cs.primaryContainer;
              }

              return GestureDetector(
                onTap: () {
                  // Do not let users look at locked content to enforce real sequencing, but allow reading completed/adapted/current
                  if (dayStatus == 'locked' && !isSelected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("🔒 Complete current modules to unlock subsequent days!"),
                        backgroundColor: Colors.amber,
                        duration: Duration(seconds: 1),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _selectedDayIndex = index;
                  });
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: circleBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: borderCol,
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: cs.primaryContainer.withOpacity(0.25),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: Center(child: icon),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "DAY $dayNum",
                      style: GoogleFonts.orbitron(
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? cs.primaryContainer : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),

        // Selected Day Details
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Badge & Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'adapted'
                            ? Colors.amber.withOpacity(0.15)
                            : status == 'completed'
                                ? Colors.green.withOpacity(0.15)
                                : cs.primaryContainer.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: status == 'adapted'
                              ? Colors.amber
                              : status == 'completed'
                                  ? Colors.green
                                  : cs.primaryContainer,
                        ),
                      ),
                      child: Text(
                        status == 'adapted'
                            ? "REROUTED"
                            : status == 'completed'
                                ? "MASTERED"
                                : "ACTIVE STUDY",
                        style: GoogleFonts.orbitron(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: status == 'adapted'
                              ? Colors.amber
                              : status == 'completed'
                                  ? Colors.green
                                  : cs.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dayTitle,
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // Topics bullet points
                if (topics.isNotEmpty) ...[
                  Text(
                    "CONCEPTS FOR EVALUATION",
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: cs.primaryContainer,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: topics.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Text(
                          t.toString(),
                          style: GoogleFonts.outfit(fontSize: 11, color: cs.onSurface),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Markdown Summary
                Text(
                  "CONCEPTUAL SYNOPSIS",
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: cs.primaryContainer,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Text(
                    summary,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: cs.onSurface,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Rescued Concepts panel
                if (currentDayData.containsKey('rescued_concepts') && (currentDayData['rescued_concepts'] as List).isNotEmpty) ...[
                  Text(
                    "🛟 RESCUED CONCEPTS (GROUNDED)",
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.purpleAccent,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...(currentDayData['rescued_concepts'] as List).map((rc) {
                    final concept = Map<String, dynamic>.from(rc);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.explore_rounded, color: Colors.purpleAccent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                concept['term'] ?? "Verified Concept",
                                style: GoogleFonts.orbitron(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purpleAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            concept['context'] ?? concept['rescued_context'] ?? "",
                            style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Source: ${concept['source'] ?? "Google Search Grounding"}",
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: cs.onSurfaceVariant.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                ],

                // Video recommendations
                if (videos.isNotEmpty) ...[
                  Text(
                    "INTELLIGENT STUDY FEEDS",
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: cs.primaryContainer,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...videos.map((video) {
                    final v = Map<String, dynamic>.from(video);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: ListTile(
                        onTap: () {
                          final String url = v['url'] ?? "";
                          if (url.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => YoutubePlayerScreen(url: url)),
                            );
                          }
                        },
                        leading: Container(
                          width: 80,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            image: v['thumbnail'] != null
                                ? DecorationImage(
                                    image: NetworkImage(v['thumbnail']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Colors.black26,
                          ),
                          child: const Center(
                            child: Icon(Icons.play_circle_fill_rounded, color: Colors.redAccent, size: 24),
                          ),
                        ),
                        title: Text(
                          v['title'] ?? "Video Tutorial",
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          v['explanation'] ?? v['channel'] ?? "Concept tutorial",
                          style: GoogleFonts.outfit(fontSize: 11, color: cs.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],

                // Action Evaluation Button
                if (status != 'completed') ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status == 'adapted' ? Colors.amber : cs.primaryContainer,
                        foregroundColor: status == 'adapted' ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      onPressed: () => _startDailyQuiz(_selectedDayIndex),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(status == 'adapted' ? Icons.alt_route_rounded : Icons.offline_bolt_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            status == 'adapted'
                                ? "INITIATE RE-EVALUATION QUIZ"
                                : "INITIATE COGNITIVE EVALUATION",
                            style: GoogleFonts.orbitron(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "DAY EVALUATION COMPLETE",
                          style: GoogleFonts.orbitron(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizInterface(ColorScheme cs) {
    final quiz = _schedule[_activeQuizDayIndex!]['quiz'] as List<dynamic>;
    
    if (_showQuizResults) {
      final total = quiz.length;
      final bool passed = _quizScore >= (total / 2).round();

      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            "EVALUATION TELEMETRY",
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: passed ? Colors.green.withOpacity(0.12) : Colors.redAccent.withOpacity(0.12),
                    border: Border.all(
                      color: passed ? Colors.green : Colors.redAccent,
                      width: 2.5,
                    ),
                  ),
                  child: Icon(
                    passed ? Icons.emoji_events_rounded : Icons.report_problem_rounded,
                    color: passed ? Colors.green : Colors.redAccent,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  passed ? "COGNITIVE SYNC MASTERED" : "CRITICAL KNOWLEDGE DEVIATION",
                  style: GoogleFonts.orbitron(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: passed ? Colors.green : Colors.redAccent,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  passed
                      ? "Excellent work! You answered $_quizScore out of $total questions correctly and achieved complete cognitive sync."
                      : "We've detected a significant knowledge gap. You answered $_quizScore out of $total questions correctly. Recalibration of the plan is necessary to optimize your preparation.",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Text(
                  "SCORE: $_quizScore / $total",
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: passed ? Colors.green : Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _completeQuizFlow,
                    child: Text(
                      passed ? "FINALIZE BLOCK & EARN XP" : "TRIGGER PUTAR OTAK REROUTING",
                      style: GoogleFonts.orbitron(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = Map<String, dynamic>.from(quiz[_currentQuestionIndex]);
    final String qText = currentQuestion['question'] ?? "Question Text";
    final List<dynamic> options = currentQuestion['options'] ?? [];
    final String? currentSelected = _selectedQuizAnswers[_currentQuestionIndex];

    // Check if this is a rescued concept question
    final currentDayData = _schedule[_activeQuizDayIndex!];
    final rescuedConcepts = currentDayData['rescued_concepts'] as List<dynamic>? ?? [];
    bool isRescuedQuestion = false;
    for (var rc in rescuedConcepts) {
      final term = (rc['term'] ?? "").toString().toLowerCase();
      if (term.isNotEmpty && (qText.toLowerCase().contains(term) || currentQuestion['explanation'].toString().toLowerCase().contains(term))) {
        isRescuedQuestion = true;
        break;
      }
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurface),
          onPressed: () {
            setState(() {
              _activeQuizDayIndex = null;
            });
          },
        ),
        title: Text(
          "QUESTION ${_currentQuestionIndex + 1} OF ${quiz.length}",
          style: GoogleFonts.orbitron(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: cs.primaryContainer,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / quiz.length,
                color: cs.primaryContainer,
                backgroundColor: cs.surfaceContainerLowest,
              ),
              const SizedBox(height: 30),
              if (isRescuedQuestion) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.explore_rounded, color: Colors.purpleAccent, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        "RESCUED CONTEXT QUESTION (100% GROUNDED)",
                        style: GoogleFonts.orbitron(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Text(
                  qText,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, idx) {
                    final opt = options[idx].toString();
                    final isSelected = currentSelected == opt;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedQuizAnswers[_currentQuestionIndex] = opt;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primaryContainer.withOpacity(0.12)
                              : cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? cs.primaryContainer : cs.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? cs.primaryContainer : cs.onSurfaceVariant,
                                  width: 2,
                                ),
                                color: isSelected ? cs.primaryContainer : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                opt,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentQuestionIndex > 0)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.surfaceContainerHigh,
                        foregroundColor: cs.onSurface,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex--;
                        });
                      },
                      child: const Text("PREV"),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primaryContainer,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: currentSelected == null
                        ? null
                        : () {
                            if (_currentQuestionIndex < quiz.length - 1) {
                              setState(() {
                                _currentQuestionIndex++;
                              });
                            } else {
                              _submitQuiz();
                            }
                          },
                    child: Text(_currentQuestionIndex < quiz.length - 1 ? "NEXT" : "SUBMIT"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
