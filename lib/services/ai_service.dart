import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: dotenv.env['GEMINI_API_KEY']!,
  );
  
  static Future<Map<String, dynamic>> generateRoadmap(String goal, {Map<String, dynamic>? aiConfig}) async {
    final apiKey = dotenv.env['GEMINI_API_KEY']!;

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    String configPrompt = "";
    if (aiConfig != null) {
      configPrompt = """
  User Preferences:
  - Study Intensity: ${aiConfig['intensity'] ?? 'Balanced'}
  - Preferred Study Style: ${aiConfig['studyStyle'] ?? 'Practical'}
  - General Study Goal: ${aiConfig['generalGoal'] ?? 'N/A'}
  - Course Priorities: ${aiConfig['coursePriorities']?.toString() ?? 'N/A'}

  Please tailor your recommendations to match these preferences. 
  If intensity is 'Hardcore', suggest more advanced or longer videos. 
  If study style is 'Visual', prioritize videos with high visual content or animations.
  """;
    }

    final prompt = """
  $configPrompt

  Recommend 3 educational Youtube videos about:
  $goal

  You MUST return ONLY valid JSON.

  Rules:
  - Each video MUST include a REAL YouTube URL.
  - If you are not sure about URL, construct it like: https://www.youtube.com/watch?v=SEARCHABLE_VIDEO_ID
  - DO NOT OMIT url field.
  
  Format:
  {
    "videos" : [
      {
        "title": "...",
        "url": "https://www.youtube.com/watch?v=xxxxx",
        "thumbnail": "https://img.youtube.com/vi/xxxxx/hqdefault.jpg",
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

  static Future<Map<String, dynamic>> generateDailyPlan({
    required String studentID,
    required List<Map<String, dynamic>> existingTasks,
    required Map<String, dynamic>? aiConfig,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY']!;
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

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
  }