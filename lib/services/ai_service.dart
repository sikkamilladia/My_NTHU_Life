import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static GenerativeModel? _cachedModel;

  static GenerativeModel get _model {
    if (_cachedModel != null) return _cachedModel!;
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
    _cachedModel = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: apiKey,
    );
    return _cachedModel!;
  }
  
  static Future<Map<String, dynamic>> generateRoadmap(String goal) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

    final model = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: apiKey,
    );

    final prompt = """
Recommend 3 educational Youtube videos about:
$goal

You MUST return ONLY valid JSON.

Each video MUST include a REAL YouTube URL.

If you are not sure about URL, construct it like:
https://www.youtube.com/watch?v=SEARCHABLE_VIDEO_ID

DO NOT OMIT url field.
Format:
{
  "videos" : [
    {
      "title": "...",
      "url": "https://www.youtube.com/watch?v=xxxxx",
      "thumbnail": "https://img.youtube.com/vi/xxxxx/hqdefault.jpg"
      "channel": "...",
      "explanation": "...",
      "xp": 10,
      "youtubeKeywords": ["...", "..."]
    }
  ]
}
""";

    final response = await model.generateContent([
      Content.text(prompt),
    ]);
    print("RAW Response:");
    print(response.text);
    String text = response.text ?? "{}";
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1) {
      text = text.substring(start, end + 1);
    }
    print("CLEAN JSON:");
    print(text);

    return jsonDecode(text);
  }

  static Future<Map<String, dynamic>> summarizeNotes(String text) async {
    final response = await _model.generateContent([
      Content.text("Summarize this in simple bullet points:\n$text")
    ]);

    return {
      "summary": response.text ?? "No summary"
    };
  }

  static Future<Map<String, dynamic>> generateQuiz(String topic) async {
    final prompt = """
Generate 5 multiple choice questions about:

$topic

You MUST return ONLY valid JSON.

Format exactly:
{
  "quiz": [
    {
      "question": "...",
      "options": ["A", "B", "C", "D"],
      "answer": "A",
      "explanation": "..."
    }
  ]
}

Rules:
- Focus on conceptual understanding
- 4 options each
- Only one correct answer
- Explanation must be short and clear
""";

    final response = await _model.generateContent([
      Content.text(prompt),
    ]);

    print("RAW QUIZ:");
    print(response.text);

    String text = response.text ?? "{}";

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');

    if (start != -1 && end != -1) {
      text = text.substring(start, end + 1);
    }

    print("CLEAN QUIZ JSON:");
    print(text);

    return jsonDecode(text);
  }

  static Future<Map<String, dynamic>> explainTopic(String topic) async {
    final prompt = """
Explain this topic in a structured way:

$topic

Format your answer like this:
- Simple intuition
- Core concept
- Step-by-step explanation
- Example
- Common mistakes
- Summary

Keep it clear and easy to understand.
""";

    final response = await _model.generateContent([
      Content.text(prompt),
    ]);

    return {
      "explanation": response.text ?? "No explanation"
    };
  }

  static Future<Map<String, dynamic>> generateDailyPlan({
    required String studentID,
    required List<Map<String, dynamic>> existingTasks,
    required Map<String, dynamic>? aiConfig,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
    final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: apiKey);

    final String configStr = aiConfig?.toString() ?? "Default Preferences";
    final String tasksStr = existingTasks.map((t) => "${t['title']} (${t['category']} for ${t['course']})").join(", ");

    final prompt = """
You are an Agentic Study Planner for an NTHU student. 
User Preferences: $configStr
Existing Calendar Tasks: $tasksStr

Based on these, create a "Daily Tactical Study Plan". 
1. Suggest 2-3 specific "AI Quests" (tasks) for today to help the user prepare for upcoming classes or catch up.
2. For each quest, provide a specific search query for Youtube study materials.

You MUST return ONLY valid JSON.
Format:
{
"daily_advice": "Short encouraging message",
"ai_quests": [
  {
    "title": "Study [Topic]",
    "course": "[Course Name]",
    "category": "AI Planned",
    "priority": "High/Medium/Low",
    "youtube_query": "Detailed youtube search query for this topic"
  }
]
}
""";

    final response = await model.generateContent([Content.text(prompt)]);
    String text = response.text ?? "{}";
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1) text = text.substring(start, end + 1);

    return jsonDecode(text);
  }

  static Future<Map<String, dynamic>> generateSubtasks({
    required String taskTitle,
    required String courseName,
    required List<Map<String, dynamic>> studentGrades,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print("❌ [AIService] Error: GEMINI_API_KEY is null or empty in .env");
      return {"subtasks": []};
    }

    final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: apiKey);

    final String gradesStr = studentGrades.isNotEmpty 
        ? studentGrades.map((g) => "${g['courseName']}: ${g['grade']}").join(", ")
        : "No grade history available.";

    final prompt = """
    You are an expert academic assistant at NTHU. 
    A student needs to complete a task: "$taskTitle" for the course: "$courseName".

    Student's previous academic performance: $gradesStr

    Break down this task into 3-5 manageable subtasks. 
    For each subtask, estimate the time required (in minutes) based on:
    1. The student's ability (inferred from their grades). If they have high grades in related subjects, they might be faster.
    2. The typical difficulty of the "$courseName" course.

    You MUST return ONLY valid JSON.
    Format:
    {
      "subtasks": [
        {
          "title": "...",
          "estimated_minutes": 30,
          "reasoning": "Brief explanation of why this time was estimated"
        }
      ]
    }
    """;

    try {
      print("🚀 [AIService] Generating subtasks for: $taskTitle...");
      final response = await model.generateContent([Content.text(prompt)]);
      String text = response.text ?? "{}";

      print("📥 [AIService] RAW response: $text");

      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) text = text.substring(start, end + 1);

      final decoded = jsonDecode(text);
      print("✅ [AIService] Successfully generated ${decoded['subtasks']?.length ?? 0} subtasks.");
      return decoded;
    } catch (e) {
      print("❌ [AIService] Error generating subtasks: $e");
      return {"subtasks": []};
    }
  }

  static Future<Map<String, dynamic>> analyzeStudyMaterial({
    required String fileName,
    required String fileType,
    required Uint8List? fileBytes,
    required String courseName,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print("❌ [AIService] Error: GEMINI_API_KEY is null or empty");
      return {};
    }

    final model = _model;

    final promptText = """
You are an expert NTHU academic agent. Analyze the provided study material file "$fileName" for the course "$courseName".
If PDF bytes are attached, analyze the content thoroughly. If no bytes are attached or this is a PPT/PPTX/other file, generate a highly realistic, academically accurate analysis, summary, quiz, and study schedule based on standard NTHU curricula for "$courseName" (specifically focusing on "$fileName" as the main topic).

Your task is to:
1. Identify 3-5 key important topics (represented as a list of strings).
2. Generate a highly detailed summary of the material in clean Markdown bullet points.
3. Estimate the total study time required in minutes (integer).
4. Recommend 2 educational YouTube videos about the core topics with real-looking or searchable URLs and thumbnails (format: https://www.youtube.com/watch?v=ID and https://img.youtube.com/vi/ID/hqdefault.jpg).
5. Automatically design a Pomodoro Study Schedule (3-5 sessions) distributed over days of the week (e.g., Monday, Tuesday, etc.) to learn these topics systematically.
6. Generate exactly 10 high-quality multiple choice questions testing conceptual understanding. Each question MUST have exactly 4 options and the "answer" field MUST match the correct option EXACTLY.

You MUST return ONLY valid JSON.
Format:
{
  "important_topics": ["topic1", "topic2", ...],
  "summary": "...",
  "estimated_study_time_minutes": 120,
  "pomodoro_schedule": [
    {
      "day": "Monday",
      "topic": "...",
      "duration": "25 mins"
    }
  ],
  "videos": [
    {
      "title": "...",
      "url": "https://www.youtube.com/watch?v=...",
      "thumbnail": "https://img.youtube.com/vi/.../hqdefault.jpg",
      "channel": "...",
      "explanation": "..."
    }
  ],
  "quiz": [
    {
      "question": "...",
      "options": ["A", "B", "C", "D"],
      "answer": "A",
      "explanation": "..."
    }
  ]
}
""";

    try {
      print("🚀 [AIService] Analyzing study material: $fileName for $courseName...");
      GenerateContentResponse response;

      if (fileBytes != null && fileType.toLowerCase() == 'pdf') {
        final List<Part> parts = [
          DataPart('application/pdf', fileBytes),
          TextPart(promptText),
        ];
        response = await model.generateContent([Content.multi(parts)]);
      } else {
        response = await model.generateContent([Content.text(promptText)]);
      }

      String text = response.text ?? "{}";
      print("📥 [AIService] RAW response: $text");

      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) {
        text = text.substring(start, end + 1);
      }

      final decoded = jsonDecode(text);
      print("✅ [AIService] Successfully analyzed study material.");
      return decoded;
    } catch (e) {
      print("❌ [AIService] Error analyzing study material: $e");
      return {};
    }
  }
}
