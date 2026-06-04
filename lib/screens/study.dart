import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/services/ai_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//hello
class AIStudyMaterialWidget extends StatefulWidget {
  const AIStudyMaterialWidget({super.key});

  @override
  State<AIStudyMaterialWidget> createState() => _AIStudyMaterialWidgetState();
}

class _AIStudyMaterialWidgetState
  extends State<AIStudyMaterialWidget>{
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> videos = [];
  bool isLoading = false;
  String? summaryResult;
  bool isSummarizing = false;
  bool hasSearched = false;
  bool isGeneratingQuiz = false;
  Map<String, dynamic>? quizResult;
  String? getThumbnailUrl(String? url) {
  if (url == null || url.isEmpty) return null;

  final videoId = YoutubePlayer.convertUrlToId(url);

  if (videoId == null) return null;

  return "https://i.ytimg.com/vi/$videoId/maxresdefault.jpg";
}
  @override
  Widget build(BuildContext context) {
    // --- DARK MODE COLOR THEME CONFIGURATION ---
    const primaryPurple = Color(0xFF9F7AEA); // Brighter purple vibrant enough for dark mode
    const bgDark = Color(0xFF121212); // Deep dark background for the scaffold
    const cardBg = Color(0xFF1F1B24); // Surface card color (dark violet tint)
    const textLight = Colors.white; // Main text color
    const textMuted = Color(0xFFA0AEC0); // Subdued grayish-blue text for secondary info
    const borderPurple = Color(0xFF3C344C); // Dark purple outline borders

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER SECTION ---
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: primaryPurple,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "AI study helper",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textLight,
                    ),
                  ),
                  // Using Spacer instead of MainAxisAlignment.between to avoid hidden character compile bugs
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderPurple),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history, color: textLight, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Your personal AI companion to help you study smarter.",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // --- 2. AI COMPANION PROMPT CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderPurple),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryPurple.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.smart_toy_outlined,
                            color: primaryPurple,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hi there! 👋",
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Ask me anything about your topic,\nand I'll help you learn better.",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: textMuted,
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
                      style: GoogleFonts.outfit(color: textLight),
                      decoration: InputDecoration(
                        hintText: "e.g. Explain photosynthesis in simple terms",
                        hintStyle: GoogleFonts.outfit(
                          color: textMuted.withOpacity(0.6),
                          fontSize: 13,
                        ),
                        fillColor: const Color(0xFF2D2636), // Slightly lighter container backdrop
                        filled: true,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: GestureDetector(
                            onTap : _searchVideos,
                            child : Container(
                              decoration : const BoxDecoration(
                                color : primaryPurple,
                                shape: BoxShape.circle,
                              ),
                              child : const Icon(
                                Icons.arrow_upward_rounded,
                                color : Colors.white,
                                size : 18,
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
                          borderSide: const BorderSide(color: borderPurple),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryPurple),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildActionButton(Icons.menu_book_outlined, "Explain a topic", primaryPurple, borderPurple),
                          _buildActionButton(Icons.description_outlined, "Summarize notes", primaryPurple, borderPurple, onTap: _summarizeNotes,),
                          _buildActionButton(Icons.play_circle_outline_rounded, "Recommend videos", primaryPurple, borderPurple),
                          _buildActionButton(Icons.quiz_outlined, "Generate Quiz", primaryPurple, borderPurple, onTap: _generateQuiz,),
                          _buildActionButton(Icons.more_horiz, "More", primaryPurple, borderPurple),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (summaryResult != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1B24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderPurple),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notes, color: primaryPurple),
                          const SizedBox(width: 8),
                          Text(
                            "Summary Notes",
                            style: GoogleFonts.outfit(
                              color: textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        summaryResult ?? "",
                        style: GoogleFonts.outfit(
                          color: textMuted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // --- 3. YOUTUBE STUDY VIDEOS SECTION ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderPurple),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_filled_rounded,
                          color: Color(0xFFFF0000), // YouTube Red Color
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Recommended videos for you",
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                      ],
                    ),
                    const SizedBox(height: 4),
                  
                    const SizedBox(height: 16),
                    if(isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else if (!hasSearched) 
                      Text(
                        "Ask a topic to get recommendations",
                        style: GoogleFonts.outfit(
                          color: textMuted,
                        ),
                      )
                    else if(isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if(videos.isEmpty)
                      Text("No videos found", style: GoogleFonts.outfit(color: textMuted),)
                    else
                      Column(
                        children: videos
                          .map((video) => _buildVideoItem(video))
                          .toList(),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _openYouTubeSearch,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: borderPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "View more on YouTube ",
                              style: GoogleFonts.outfit(
                                color: primaryPurple,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.launch_rounded, size: 14, color: primaryPurple),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 4. STUDY TIP BANNER ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderPurple.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D2636),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: primaryPurple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Study tip",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Use videos to understand concepts visually and reinforce your learning.",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.personal_video_rounded,
                      size: 40,
                      color: borderPurple.withOpacity(0.8),
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

  Widget _buildActionButton(
  IconData icon,
  String label,
  Color primaryPurple,
  Color borderPurple, {
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2636),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderPurple),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryPurple),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: primaryPurple,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildVideoPlaceholderItem(Color mutedColor, Color borderPurple) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF2D2636),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, color: mutedColor, size: 28),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "10:00",
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 9),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2636),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2636),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2636),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    "  •  123K views  •  2 years ago",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: mutedColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Icon(Icons.more_vert_rounded, size: 18, color: mutedColor),
      ],
    );
  }
Widget _buildVideoItem(Map<String, dynamic> video) {
  print("VIDEO DATA: $video");

  return ListTile(
    contentPadding: EdgeInsets.zero,

    onTap: () {
      final url = video["url"]?.toString();

      final fallbackQuery =
          video["youtubeKeywords"]?.first ??
          video["title"] ??
          "";

      final finalUrl = (url != null && url.isNotEmpty)
          ? url
          : "https://www.youtube.com/results?search_query=${Uri.encodeComponent(fallbackQuery)}";

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => YoutubePlayerScreen(url: finalUrl),
        ),
      );
    },

    leading: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            getThumbnailUrl(video["url"]) ??
                "https://via.placeholder.com/120x70",
            width: 120,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                width: 120,
                height: 70,
                color: const Color(0xFF2D2636),
              );
            },
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    ),

    title: Text(
      video["title"] ?? "No title",
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),

    subtitle: Text(
      video["channel"] ?? "Unknown channel",
      style: GoogleFonts.outfit(
        color: Colors.grey,
      ),
    ),
  );
}
  Future<void> _searchVideos() async {
  try {
    final topic = _controller.text.trim();

    if (topic.isEmpty) return;

    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    final result = await AIService.generateRoadmap(topic);

    print(result);

    setState(() {
      videos = List<Map<String, dynamic>>.from(
        result["videos"] ?? [],
      );
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
    "https://www.youtube.com/results?search_query=$topic"
  );

  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw "Could not open YouTube";
  }
}
  Future<void> _summarizeNotes() async {
  try {
    final text = _controller.text.trim();

    if (text.isEmpty) return;
    if (isSummarizing) return;

    setState(() {
      isSummarizing = true;
    });
    print("TEXT = $text");
    final result = await AIService.summarizeNotes(text);
    print("result = $result");
    final summary = result["summary"];

    if (summary == null || summary.isEmpty) {
      setState(() {
        isSummarizing = false;
      });
      return;
    }

    setState(() {
      summaryResult = summary;
      isSummarizing = false;
    });
    if (!mounted) return;
    _showSummaryBottomSheet();

  } catch (e) {
    print("SUMMARY ERROR: $e");

    setState(() {
      isSummarizing = false;
    });
  }
}
  
  void _showSummaryBottomSheet() {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1F1B24),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            summaryResult ?? "",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      );
    },
  );
}
  Future<void> _generateQuiz() async {
  try {
    final topic = _controller.text.trim();
    if (topic.isEmpty) return;
    if (isGeneratingQuiz) return;

    setState(() {
      isGeneratingQuiz = true;
    });

    final result = await AIService.generateQuiz(topic);

    setState(() {
      quizResult = result;
      isGeneratingQuiz = false;
    });

    if (!mounted) return;

    _showQuizBottomSheet();

  } catch (e) {
    print("QUIZ ERROR: $e");

    setState(() {
      isGeneratingQuiz = false;
    });
  }
}
  void _showQuizBottomSheet() {
  final quiz = quizResult?["quiz"] ?? [];

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
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: quiz.length,
          itemBuilder: (context, index) {
            final q = quiz[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2636),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Q${index + 1}. ${q["question"]}",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...List.generate((q["options"] as List).length, (i) {
                    return Text(
                      "${String.fromCharCode(65 + i)}. ${q["options"][i]}",
                      style: GoogleFonts.outfit(color: Colors.grey),
                    );
                  }),

                  const SizedBox(height: 8),

                  Text(
                    "Answer: ${q["answer"]}",
                    style: GoogleFonts.outfit(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    q["explanation"] ?? "",
                    style: GoogleFonts.outfit(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
}

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
    print(widget.url);
    print(videoId);
    if (videoId == null) {
      debugPrint("Invalid YouTube URL: ${widget.url}");
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
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
            "Invalid YouTube link",
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

