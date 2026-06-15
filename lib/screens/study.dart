import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/services/ai_service.dart';
import 'package:my_nthu_life/services/firestore_services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AIStudyMaterialWidget extends StatefulWidget {
  final String studentID;
  const AIStudyMaterialWidget({super.key, required this.studentID});

  @override
  State<AIStudyMaterialWidget> createState() => _AIStudyMaterialWidgetState();
}

class _AIStudyMaterialWidgetState extends State<AIStudyMaterialWidget> {
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> videos = [];
  List<Map<String, dynamic>> recommendedVideos = [];
  bool isLoading = false;
  bool isRecommendedLoading = false;
  String? summaryResult;
  bool isSummarizing = false;
  bool hasSearched = false;
  bool isGeneratingQuiz = false;
  Map<String, dynamic>? quizResult;
  bool isExplaining = false;
  String? explanationResult;

  String? selectedCourse;
  List<String> availableCourses = [];

  // --- Pomodoro State Variables ---
  bool _showTimerSetup = true;
  int _selectedMinutes = 25;
  int _remainingSeconds = 1500;
  bool _isTimerRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchRecommendedVideos();
    _fetchAvailableCourses();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isTimerRunning = false;
        });
        _showCompletionDialog();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _stopAndGoToSetup() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _showTimerSetup = true;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF13101B), // dark background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.greenAccent, width: 2),
          ),
          title: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.forest_rounded,
                  color: Colors.greenAccent,
                  size: 60,
                ),
                const SizedBox(height: 12),
                Text(
                  "SESSION COMPLETE!",
                  style: GoogleFonts.orbitron(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Incredible work! You successfully focused for $_selectedMinutes minutes and grew a gorgeous cyber-tree in your mental forest. 🌲✨",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "+10 Focus Points Earned",
                      style: GoogleFonts.orbitron(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: SizedBox(
                width: 160,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _showTimerSetup = true;
                      _remainingSeconds = _selectedMinutes * 60;
                    });
                  },
                  child: Text(
                    "CULTIVATE MORE",
                    style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchAvailableCourses() async {
    try {
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

      setState(() {
        availableCourses = courses;
        if (availableCourses.isNotEmpty && selectedCourse == null) {
          selectedCourse = availableCourses.first;
        }
      });
    } catch (e) {
      print("Error fetching courses: $e");
    }
  }

  Future<void> _fetchRecommendedVideos() async {
    try {
      setState(() => isRecommendedLoading = true);
      final now = DateTime.now();
      final todayKey =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final planDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .collection('ai_daily_plans')
          .doc(todayKey)
          .get();

      if (planDoc.exists) {
        final quests = planDoc.data()?['ai_quests'] as List? ?? [];
        if (quests.isNotEmpty) {
          final query = quests.map((q) => q['youtube_query']).join(" ");

          final result = await AIService.generateRoadmap(query);

          setState(() {
            recommendedVideos = List<Map<String, dynamic>>.from(
              result["videos"] ?? [],
            );
          });
        }
      }
      setState(() => isRecommendedLoading = false);
    } catch (e) {
      setState(() => isRecommendedLoading = false);
    }
  }

  String? getThumbnailUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) return null;
    return "https://i.ytimg.com/vi/$videoId/maxresdefault.jpg";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_showTimerSetup) {
      return _buildTimerSetupView(cs);
    }

    return Scaffold(
      backgroundColor: cs.surface, // #0B090A bgBlack
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(
          "STUDY HQ",
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopPomodoroCard(cs),
              // --- 0. RECOMMENDED FOR YOU (AGENTIC) ---
              if (isRecommendedLoading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cs.primaryContainer.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: cs.primaryContainer,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "AI is preparing your tactical materials...",
                          style: GoogleFonts.orbitron(
                            fontSize: 10,
                            color: cs.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (recommendedVideos.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primaryContainer.withOpacity(0.15),
                        cs.surfaceContainerLow,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cs.primaryContainer.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: cs.primaryContainer,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "RECOMMENDED FOR YOUR PLAN",
                            style: GoogleFonts.orbitron(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: cs.primaryContainer,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...recommendedVideos
                          .take(2)
                          .map((v) => _buildVideoItem(cs, v))
                          .toList(),
                    ],
                  ),
                ),

              // --- 1. CLASS SELECTION ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outlineVariant, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: cs.primaryContainer,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "CHOOSE YOUR TARGET CLASS",
                            style: GoogleFonts.orbitron(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: cs.primaryContainer,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (availableCourses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "No active classes found in your calendar.",
                          style: GoogleFonts.outfit(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: availableCourses.length,
                          itemBuilder: (context, index) {
                            final course = availableCourses[index];
                            final isSelected = selectedCourse == course;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCourse = course;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cs.primaryContainer
                                      : cs.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? cs.primaryContainer
                                        : cs.outlineVariant,
                                    width: 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: cs.primaryContainer
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  course,
                                  style: GoogleFonts.outfit(
                                    color: isSelected
                                        ? Colors.white
                                        : cs.onSurface,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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

              // --- 2. AI COMPANION CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow, // #16121E cardDark
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outlineVariant, width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.smart_toy_outlined,
                            color: cs.primaryContainer,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "MISSION PARAMETERS",
                                style: GoogleFonts.orbitron(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primaryContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Define the topic for ${selectedCourse ?? 'your class'}.",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      style: GoogleFonts.outfit(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText:
                            "e.g. Core concepts of ${selectedCourse ?? 'this class'}",
                        hintStyle: GoogleFonts.outfit(
                          color: cs.onSurfaceVariant.withOpacity(0.6),
                          fontSize: 13,
                        ),
                        fillColor:
                            cs.surfaceContainerHigh, // #241E2E input fill
                        filled: true,
                        suffixIcon: IconButton(
                          onPressed: _searchVideos,
                          icon: Container(
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.movie_creation_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: cs.primaryContainer,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action chips — gamified labels
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      // child: Row(
                      //   children: [
                      //     _buildActionChip(
                      //       cs,
                      //       Icons.menu_book_outlined,
                      //       "Decode Topic",
                      //       onTap: _explainTopic,
                      //     ),
                      //     _buildActionChip(
                      //       cs,
                      //       Icons.description_outlined,
                      //       "Summarize",
                      //       onTap: _summarizeNotes,
                      //     ),
                      //     _buildActionChip(
                      //       cs,
                      //       Icons.play_circle_outline_rounded,
                      //       "Generate Video",
                      //       onTap: _searchVideos,
                      //     ),
                      //     _buildActionChip(
                      //       cs,
                      //       Icons.quiz_outlined,
                      //       "Run Trial",
                      //       onTap: _generateQuiz,
                      //     ),
                      //     _buildActionChip(cs, Icons.more_horiz, "More"),
                      //   ],
                      // ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 3. SUMMARY RESULT ---
              if (summaryResult != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outlineVariant, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notes, color: cs.primaryContainer),
                          const SizedBox(width: 8),
                          Text(
                            "LORE COMPRESSION LOG",
                            style: GoogleFonts.orbitron(
                              color: cs.primaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        summaryResult ?? "",
                        style: GoogleFonts.outfit(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // --- 4. VIDEO RECON SECTION ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outlineVariant, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_filled_rounded,
                          color: Color(0xFFFF0000),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "GENERATED VIDEO RECON",
                          style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "AI-curated transmissions based on your topic",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          color: cs.primaryContainer,
                        ),
                      )
                    else if (!hasSearched)
                      Text(
                        "Input a topic and class to generate video intelligence.",
                        style: GoogleFonts.outfit(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      )
                    else if (videos.isEmpty)
                      Text(
                        "No signals detected. Try another query.",
                        style: GoogleFonts.outfit(color: cs.onSurfaceVariant),
                      )
                    else
                      Column(
                        children: videos
                            .map((v) => _buildVideoItem(cs, v, showSave: true))
                            .toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 5. SAVED VIDEOS SECTION ---
              StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getSavedVideos(
                  widget.studentID,
                  selectedCourse,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Error loading videos: ${snapshot.error}",
                        style: TextStyle(color: cs.error),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.outlineVariant,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bookmark_border_rounded,
                                color: cs.primaryContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "SAVED VIDEOS (${selectedCourse ?? 'NONE'})",
                                style: GoogleFonts.orbitron(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No transmissions saved for this sector yet.",
                            style: GoogleFonts.outfit(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final savedVideos = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    data['docId'] = doc.id;
                    return data;
                  }).toList();

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cs.primaryContainer.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bookmark_rounded,
                              color: cs.primaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "SAVED INTELLIGENCE (${selectedCourse ?? 'GENERAL'})",
                                style: GoogleFonts.orbitron(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                  letterSpacing: 1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...savedVideos
                            .map(
                              (v) => _buildVideoItem(
                                cs,
                                v,
                                isSaved: true,
                                docId: v['docId'],
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  );
                },
              ),

              // --- 6. INTEL BANNER ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceBright.withOpacity(
                    0.25,
                  ), // faint selected purple
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: cs.primaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TACTICAL INTEL",
                            style: GoogleFonts.orbitron(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: cs.primaryContainer,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Save key transmissions to build your permanent knowledge matrix.",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.personal_video_rounded,
                      size: 40,
                      color: cs.outline.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildActionChip(
    ColorScheme cs,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh, // #241E2E
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: cs.primaryContainer),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: cs.primaryContainer,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoItem(
    ColorScheme cs,
    Map<String, dynamic> video, {
    bool showSave = false,
    bool isSaved = false,
    String? docId,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      onTap: () {
        final url = video["url"]?.toString();
        final fallbackQuery = video["youtubeKeywords"]?.isNotEmpty == true
            ? video["youtubeKeywords"].first
            : (video["title"] ?? "");
        final finalUrl = (url != null && url.isNotEmpty)
            ? url
            : "https://www.youtube.com/results?search_query=${Uri.encodeComponent(fallbackQuery)}";

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => YoutubePlayerScreen(url: finalUrl)),
        );
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              getThumbnailUrl(video["url"]) ??
                  "https://via.placeholder.com/120x70",
              width: 110,
              height: 66,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 110,
                height: 66,
                color: cs.surfaceContainerHigh,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(5),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
      title: Text(
        video["title"] ?? "No title",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        video["channel"] ?? "Unknown channel",
        style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 11),
      ),
      trailing: isSaved
          ? IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
              onPressed: () =>
                  _firestoreService.deleteSavedVideo(widget.studentID, docId!),
            )
          : showSave
          ? IconButton(
              icon: Icon(
                Icons.bookmark_border,
                color: cs.primaryContainer,
                size: 20,
              ),
              onPressed: () {
                _firestoreService.saveStudyVideo(
                  widget.studentID,
                  video,
                  selectedCourse ?? 'General',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Transmission saved to ${selectedCourse ?? 'General'} matrix.",
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  // ── Logic ──────────────────────────────────────────────────────────────────

  Future<void> _searchVideos() async {
    try {
      final topic = _controller.text.trim();
      if (topic.isEmpty && selectedCourse == null) return;

      setState(() {
        isLoading = true;
        hasSearched = true;
      });

      final query = "${selectedCourse ?? ''} $topic".trim();
      final result = await AIService.generateRoadmap(query);

      setState(() {
        videos = List<Map<String, dynamic>>.from(result["videos"] ?? []);
        isLoading = false;
      });
    } catch (e) {
      print("ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _openYouTubeSearch() async {
    final topic = _controller.text.trim();
    if (topic.isEmpty) return;
    final url = Uri.parse(
      "https://www.youtube.com/results?search_query=$topic",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw "Could not open YouTube";
    }
  }

  Future<void> _summarizeNotes() async {
    try {
      final text = _controller.text.trim();
      if (text.isEmpty || isSummarizing) return;
      setState(() => isSummarizing = true);
      final result = await AIService.summarizeNotes(text);
      final summary = result["summary"]?.toString() ?? "";
      if (summary.isEmpty) {
        setState(() => isSummarizing = false);
        return;
      }
      setState(() {
        summaryResult = summary;
        isSummarizing = false;
      });
      if (!mounted) return;
      _showSummaryBottomSheet();
    } catch (e) {
      setState(() => isSummarizing = false);
    }
  }

  void _showSummaryBottomSheet() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "LORE COMPRESSION LOG",
                style: GoogleFonts.orbitron(
                  color: cs.primaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                summaryResult ?? "",
                style: GoogleFonts.outfit(
                  color: cs.onSurface,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateQuiz() async {
    try {
      final topic = _controller.text.trim();
      if (topic.isEmpty || isGeneratingQuiz) return;
      setState(() => isGeneratingQuiz = true);
      final result = await AIService.generateQuiz(topic);
      setState(() {
        quizResult = result;
        isGeneratingQuiz = false;
      });
      if (!mounted) return;
      _showQuizBottomSheet();
    } catch (e) {
      setState(() => isGeneratingQuiz = false);
    }
  }

  void _showQuizBottomSheet() {
    final cs = Theme.of(context).colorScheme;
    final quiz = quizResult?["quiz"] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TRIAL SEQUENCE INITIATED",
                style: GoogleFonts.orbitron(
                  color: cs.primaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: quiz.length,
                  itemBuilder: (context, index) {
                    final q = quiz[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Q${index + 1}. ${q["question"]}",
                            style: GoogleFonts.outfit(
                              color: cs.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(
                            (q["options"] as List).length,
                            (i) => Text(
                              "${String.fromCharCode(65 + i)}. ${q["options"][i]}",
                              style: GoogleFonts.outfit(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "✓ CORRECT: ${q["answer"]}",
                            style: GoogleFonts.orbitron(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            q["explanation"] ?? "",
                            style: GoogleFonts.outfit(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _explainTopic() async {
    try {
      final topic = _controller.text.trim();
      if (topic.isEmpty) return;
      if (isExplaining) return;

      setState(() {
        isExplaining = true;
      });

      final result = await AIService.explainTopic(topic);

      final explanation = result["explanation"]?.toString() ?? "";

      setState(() {
        explanationResult = explanation;
        isExplaining = false;
      });

      if (!mounted) return;
      _showExplanationBottomSheet();
    } catch (e) {
      print("EXPLAIN ERROR: $e");
      setState(() {
        isExplaining = false;
      });
    }
  }

  void _showExplanationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F1B24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              explanationResult ?? "",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Pomodoro Timer UI Builders ──────────────────────────────────────────────

  Widget _buildTimerSetupView(ColorScheme cs) {
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Header
              Text(
                "FOREST FOCUS COGNITION",
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Set focus session to cultivate a cyber-tree and harvest intellectual assets.",
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Custom dial
              Center(
                child: Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.02),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _CircularTimerDial(
                    initialMinutes: _selectedMinutes,
                    onChanged: (mins) {
                      setState(() {
                        _selectedMinutes = mins;
                        _remainingSeconds = mins * 60;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 54),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showTimerSetup = false;
                    });
                    _startTimer();
                  },
                  icon: const Icon(Icons.forest_rounded, size: 20),
                  label: Text(
                    "START FOCUS TIMER",
                    style: GoogleFonts.orbitron(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.greenAccent.withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showTimerSetup = false;
                      _remainingSeconds = _selectedMinutes * 60;
                    });
                  },
                  icon: const Icon(Icons.smart_toy_outlined, size: 18),
                  label: Text(
                    "SKIP TO AI COMPANION",
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.primaryContainer,
                    side: BorderSide(color: cs.primaryContainer.withOpacity(0.5), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopPomodoroCard(ColorScheme cs) {
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    final totalSecs = _selectedMinutes * 60;
    final percent = totalSecs > 0 ? _remainingSeconds / totalSecs : 0.0;

    // Tree icon based on remaining or original selected minutes
    IconData treeIcon = Icons.eco_rounded;
    if (_selectedMinutes >= 15 && _selectedMinutes < 30) {
      treeIcon = Icons.spa_rounded;
    } else if (_selectedMinutes >= 30 && _selectedMinutes < 45) {
      treeIcon = Icons.park_rounded;
    } else if (_selectedMinutes >= 45) {
      treeIcon = Icons.forest_rounded;
    }

    String statusText = "SEED READY TO SOW";
    Color statusColor = cs.onSurfaceVariant;
    if (_isTimerRunning) {
      statusText = "CULTIVATING FOCUS TREE...";
      statusColor = Colors.greenAccent;
    } else if (_remainingSeconds < totalSecs) {
      statusText = "FOCUS PAUSED";
      statusColor = Colors.amber;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF13101B), // dark background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isTimerRunning ? Colors.greenAccent.withOpacity(0.5) : cs.outlineVariant.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: _isTimerRunning
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          // Left: Small circular radial indicator
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 5,
                  backgroundColor: cs.outlineVariant.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isTimerRunning ? Colors.greenAccent : cs.primaryContainer,
                  ),
                ),
                Icon(
                  treeIcon,
                  color: _isTimerRunning ? Colors.greenAccent : cs.primaryContainer.withOpacity(0.6),
                  size: 26,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Middle: Clock text and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}",
                  style: GoogleFonts.orbitron(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Right: Control buttons
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_isTimerRunning) {
                    _pauseTimer();
                  } else {
                    _startTimer();
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _isTimerRunning ? Colors.amber.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _isTimerRunning ? Colors.amber : Colors.greenAccent,
                    size: 20,
                  ),
                ),
              ),
              IconButton(
                onPressed: _stopAndGoToSetup,
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stop_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Circular Timer Dial Widget ───────────────────────────────────────────────

class _CircularTimerDial extends StatefulWidget {
  final int initialMinutes;
  final ValueChanged<int> onChanged;

  const _CircularTimerDial({
    required this.initialMinutes,
    required this.onChanged,
  });

  @override
  State<_CircularTimerDial> createState() => _CircularTimerDialState();
}

class _CircularTimerDialState extends State<_CircularTimerDial> {
  late double _angle;

  @override
  void initState() {
    super.initState();
    _angle = (widget.initialMinutes / 60.0) * 2 * math.pi;
  }

  @override
  void didUpdateWidget(covariant _CircularTimerDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    _angle = (widget.initialMinutes / 60.0) * 2 * math.pi;
  }

  void _handlePan(Offset localPosition, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final dx = localPosition.dx - centerX;
    final dy = localPosition.dy - centerY;

    double angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    int minutes = (angle / (2 * math.pi) * 60).round();
    minutes = minutes.clamp(1, 60);

    setState(() {
      _angle = (minutes / 60.0) * 2 * math.pi;
    });
    widget.onChanged(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final minutes = (widget.initialMinutes).clamp(1, 60);

    IconData treeIcon = Icons.eco_rounded;
    String treeLabel = "Sprout";
    if (minutes >= 15 && minutes < 30) {
      treeIcon = Icons.spa_rounded;
      treeLabel = "Seedling";
    } else if (minutes >= 30 && minutes < 45) {
      treeIcon = Icons.park_rounded;
      treeLabel = "Sapling";
    } else if (minutes >= 45) {
      treeIcon = Icons.forest_rounded;
      treeLabel = "Forest";
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(240, 240);
        return GestureDetector(
          onPanStart: (details) => _handlePan(details.localPosition, size),
          onPanUpdate: (details) => _handlePan(details.localPosition, size),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: size,
                painter: _TimerDialPainter(
                  angle: _angle,
                  trackColor: cs.outlineVariant.withOpacity(0.2),
                  activeColor: Colors.tealAccent,
                  activeGradientColors: [
                    Colors.teal,
                    Colors.greenAccent,
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    treeIcon,
                    size: 56,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${minutes.toString().padLeft(2, '0')}:00",
                    style: GoogleFonts.orbitron(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    treeLabel.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimerDialPainter extends CustomPainter {
  final double angle;
  final Color trackColor;
  final Color activeColor;
  final List<Color> activeGradientColors;

  _TimerDialPainter({
    required this.angle,
    required this.trackColor,
    required this.activeColor,
    required this.activeGradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);
    final radius = (size.width / 2) - 16;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (angle > 0.0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      if (activeGradientColors.length >= 2) {
        activePaint.shader = SweepGradient(
          colors: activeGradientColors,
          startAngle: -math.pi / 2,
          endAngle: angle - math.pi / 2,
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect);
      } else {
        activePaint.color = activeColor;
      }

      canvas.drawArc(rect, -math.pi / 2, angle, false, activePaint);
    }

    final thumbAngle = angle - math.pi / 2;
    final thumbX = centerX + radius * math.cos(thumbAngle);
    final thumbY = centerY + radius * math.sin(thumbAngle);
    final thumbCenter = Offset(thumbX, thumbY);

    final shadowPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(thumbCenter, 14, shadowPaint);

    final thumbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(thumbCenter, 8, thumbPaint);

    final thumbCorePaint = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.fill;
    canvas.drawCircle(thumbCenter, 4, thumbCorePaint);
  }

  @override
  bool shouldRepaint(covariant _TimerDialPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.activeColor != activeColor;
  }
}

// ── YouTube Player Screen ──────────────────────────────────────────────────────

class YoutubePlayerScreen extends StatefulWidget {
  final String url;
  const YoutubePlayerScreen({super.key, required this.url});

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.url);
    if (videoId == null) return;
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Invalid transmission link",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: YoutubePlayer(
          controller: _controller!,
          showVideoProgressIndicator: true,
        ),
      ),
    );
  }
}
