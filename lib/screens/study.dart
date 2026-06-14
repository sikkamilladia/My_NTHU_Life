import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/services/ai_service.dart';
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
  List<Map<String, dynamic>> videos = [];
  List<Map<String, dynamic>> recommendedVideos = [];
  bool isLoading = false;
  bool isRecommendedLoading = false;
  String? summaryResult;
  bool isSummarizing = false;
  bool hasSearched = false;
  bool isGeneratingQuiz = false;
  Map<String, dynamic>? quizResult;

  @override
  void initState() {
    super.initState();
    _fetchRecommendedVideos();
  }

  Future<void> _fetchRecommendedVideos() async {
    try {
      setState(() => isRecommendedLoading = true);
      final now = DateTime.now();
      final todayKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      final planDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .collection('ai_daily_plans')
          .doc(todayKey)
          .get();

      if (planDoc.exists) {
        final quests = planDoc.data()?['ai_quests'] as List? ?? [];
        if (quests.isNotEmpty) {
          // Combine all queries or just pick the first few
          final query = quests.map((q) => q['youtube_query']).join(" ");
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.studentID).get();
          final aiConfig = userDoc.data()?['ai_config'] as Map<String, dynamic>?;

          final result = await AIService.generateRoadmap(query, aiConfig: aiConfig);
          setState(() {
            recommendedVideos = List<Map<String, dynamic>>.from(result["videos"] ?? []);
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
              // --- 0. RECOMMENDED FOR YOU (AGENTIC) ---
              if (isRecommendedLoading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.primaryContainer.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: cs.primaryContainer, strokeWidth: 2),
                        const SizedBox(height: 12),
                        Text("AI is preparing your tactical materials...", 
                          style: GoogleFonts.orbitron(fontSize: 10, color: cs.primaryContainer)),
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
                      colors: [cs.primaryContainer.withOpacity(0.15), cs.surfaceContainerLow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.primaryContainer.withOpacity(0.5), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: cs.primaryContainer, size: 18),
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
                      ...recommendedVideos.take(2).map((v) => _buildVideoItem(cs, v)).toList(),
                    ],
                  ),
                ),

              // --- 1. HEADER ---
              // Row(
              //   children: [
              //     Icon(
              //       Icons.auto_awesome_rounded,
              //       color: cs.primaryContainer,
              //       size: 28,
              //     ),
              //     const SizedBox(width: 8),
              //     Text(
              //       "STUDY HQ",
              //       style: GoogleFonts.orbitron(
              //         fontSize: 18,
              //         fontWeight: FontWeight.bold,
              //         color: cs.onSurface,
              //         letterSpacing: 1.2,
              //       ),
              //     ),
              //     const Spacer(),
              //     Container(
              //       padding: const EdgeInsets.all(6),
              //       decoration: BoxDecoration(
              //         border: Border.all(color: cs.outlineVariant),
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //       child: Icon(Icons.history, color: cs.onSurface, size: 20),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 4),
              // Text(
              //   "Deploy your AI companion to master any subject.",
              //   style: GoogleFonts.outfit(
              //     fontSize: 13,
              //     color: cs.onSurfaceVariant,
              //   ),
              // ),
              // const SizedBox(height: 20),

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
                                "Hi There!",
                                style: GoogleFonts.orbitron(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primaryContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Input a subject node to begin\nyour learning sequence.",
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
                        hintText: "e.g. Explain photosynthesis in simple terms",
                        hintStyle: GoogleFonts.outfit(
                          color: cs.onSurfaceVariant.withOpacity(0.6),
                          fontSize: 13,
                        ),
                        fillColor:
                            cs.surfaceContainerHigh, // #241E2E input fill
                        filled: true,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: GestureDetector(
                            onTap: _searchVideos,
                            child: Container(
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
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
                      child: Row(
                        children: [
                          _buildActionChip(
                            cs,
                            Icons.menu_book_outlined,
                            "Decode Topic",
                          ),
                          _buildActionChip(
                            cs,
                            Icons.description_outlined,
                            "Summarize",
                            onTap: _summarizeNotes,
                          ),
                          _buildActionChip(
                            cs,
                            Icons.play_circle_outline_rounded,
                            "Video Recon",
                          ),
                          _buildActionChip(
                            cs,
                            Icons.quiz_outlined,
                            "Run Trial",
                            onTap: _generateQuiz,
                          ),
                          _buildActionChip(cs, Icons.more_horiz, "More"),
                        ],
                      ),
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
                          "VIDEO RECON FEED",
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
                      "Curated transmissions for your subject node",
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
                        "Input a subject node to receive video intelligence.",
                        style: GoogleFonts.outfit(color: cs.onSurfaceVariant),
                      )
                    else if (videos.isEmpty)
                      Text(
                        "No signals detected. Try another query.",
                        style: GoogleFonts.outfit(color: cs.onSurfaceVariant),
                      )
                    else
                      Column(
                        children: videos
                            .map((v) => _buildVideoItem(cs, v))
                            .toList(),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _openYouTubeSearch,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: cs.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "SEE MORE ON YOUTUBE ",
                              style: GoogleFonts.orbitron(
                                color: cs.primaryContainer,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.launch_rounded,
                              size: 13,
                              color: cs.primaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 5. INTEL BANNER ---
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
                            "Use video recon to decode concepts visually and reinforce your knowledge matrix.",
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

  Widget _buildVideoItem(ColorScheme cs, Map<String, dynamic> video) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      onTap: () {
        final url = video["url"]?.toString();
        final fallbackQuery =
            video["youtubeKeywords"]?.first ?? video["title"] ?? "";
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
    );
  }

  // ── Logic ──────────────────────────────────────────────────────────────────

  Future<void> _searchVideos() async {
    try {
      final topic = _controller.text.trim();
      if (topic.isEmpty) return;
      setState(() {
        isLoading = true;
        hasSearched = true;
      });

      // Fetch AI Config
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .get();
      final aiConfig = doc.data()?['ai_config'] as Map<String, dynamic>?;

      final result = await AIService.generateRoadmap(topic, aiConfig: aiConfig);
      setState(() {
        videos = List<Map<String, dynamic>>.from(result["videos"] ?? []);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
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
      final summary = result["summary"];
      if (summary == null || summary.isEmpty) {
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
