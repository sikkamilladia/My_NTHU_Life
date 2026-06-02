import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static Future<Map<String, dynamic>> generateRoadmap(String goal) async {
    final apiKey = dotenv.env['GEMINI_API_KEY']!;

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    final prompt = """
Break this learning goal into structured JSON.

Return ONLY valid JSON.

Goal: $goal

Format:
{
  "title": "...",
  "subtasks": [
    {
      "title": "...",
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

    return jsonDecode(response.text ?? "{}");
  }
}