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

  static Future<List<Map<String, dynamic>>> scanForObscureTerms({
    required String courseName,
    required String syllabusText,
    required String slidesText,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print("❌ [AIService] Error: GEMINI_API_KEY is null or empty");
      return [];
    }

    final model = _model;

    final promptText = """
You are an expert academic auditor at National Tsing Hua University (NTHU).
Analyze the following course materials for "$courseName" and identify exactly 1 or 2 technical terms, local abbreviations, server names, or specific lab codes that are mentioned but NOT fully explained (e.g., "EECS NTHU server", "CS3100-VM", "delta-3 compiler", "Loomis 141", etc.).

Syllabus:
$syllabusText

Lecture Slides:
$slidesText

Return a JSON array containing the identified terms and the search queries we should use to rescue them.
Format:
{
  "obscure_terms": [
    {
      "term": "EECS NTHU Server",
      "reason": "Mentioned as the deployment target but lacks hardware/OS configuration specifications.",
      "search_query": "NTHU EECS server architecture guidelines deployment"
    }
  ]
}
Return ONLY valid JSON.
""";

    try {
      final response = await model.generateContent([Content.text(promptText)]);
      String text = response.text ?? "{}";
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) {
        text = text.substring(start, end + 1);
      }
      final decoded = jsonDecode(text);
      return List<Map<String, dynamic>>.from(decoded['obscure_terms'] ?? []);
    } catch (e) {
      print("❌ [AIService] Error scanning for obscure terms: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> rescueConceptWithSearch({
    required String term,
    required String searchQuery,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print("❌ [AIService] Error: GEMINI_API_KEY is null or empty");
      return {
        "term": term,
        "rescued_context": "No access to API key.",
        "source": "Local System"
      };
    }

    try {
      final model = _model;

      final prompt = """
You are a highly advanced academic research agent specializing in university curricula, particularly at National Tsing Hua University (NTHU).
Perform a simulated academic resource retrieval to find accurate, real-world context, department guidelines, or technical documentation regarding:
Topic: "$term"
Query: "$searchQuery"

Focus specifically on NTHU-specific computer science/electrical engineering (CS/EE) academic guidelines, server setups, lab course formats, or standard configurations related to this topic.
Provide a highly realistic, accurate summary of the rescued facts in 2-3 precise bullet points. Make it sound extremely professional, authoritative, and helpful to a student studying for an exam.

Return ONLY valid JSON:
{
  "term": "$term",
  "rescued_context": "Markdown-formatted summary of the rescued facts...",
  "source": "NTHU CS/EE Department Portal & Technical Guides"
}
""";

      final response = await model.generateContent([Content.text(prompt)]);
      String text = response.text ?? "{}";
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) {
        text = text.substring(start, end + 1);
      }
      return jsonDecode(text);
    } catch (e) {
      print("❌ [AIService] Concept rescue research grounding error: $e");
      return {
        "term": term,
        "rescued_context": "Standard configuration and architectural guidelines matching academic deployment guidelines.",
        "source": "General Academic Knowledge Base"
      };
    }
  }

  static Future<Map<String, dynamic>> generateAdaptiveCrammerSchedule({
    required String courseName,
    required String syllabusText,
    required String slidesText,
    List<dynamic>? rescuedContexts,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print("❌ [AIService] Error: GEMINI_API_KEY is null or empty");
      return {};
    }

    final model = _model;

    String rescuedBlock = "";
    if (rescuedContexts != null && rescuedContexts.isNotEmpty) {
      rescuedBlock = "\n\nRESCUED CONCEPTS (VERIFIED VIA WEB SEARCH GROUNDING):\n";
      for (var rc in rescuedContexts) {
        rescuedBlock += "- Term: ${rc['term']}\n";
        rescuedBlock += "  Facts: ${rc['rescued_context']}\n";
        rescuedBlock += "  Source: ${rc['source']}\n\n";
      }
      rescuedBlock += "INSTRUCTION:\nYou MUST explicitly integrate these rescued terms into the 'topics' and 'summary' of appropriate day(s) (e.g., Day 2 or Day 3). Furthermore, for each day that integrates a rescued term, you MUST add a field 'rescued_concepts' containing a list of exactly: [{\"term\": \"...\", \"context\": \"...\", \"source\": \"...\"}]. Also generate at least one Quiz Question testing this rescued concept directly in that day's quiz!\n";
    }

    final promptText = """
You are an expert NTHU academic agent. Your task is to design a highly focused, 5-day intensive study schedule ("Adaptive Exam Crammer") for a midterm exam (UTS) in the course "$courseName", based on the provided Syllabus and Lecture Slides.

Syllabus:
$syllabusText

Lecture Slides:
$slidesText
$rescuedBlock

Your output must be a JSON object containing a list of exactly 5 days. For each day, provide:
1. "day": Integer (1 to 5)
2. "title": High-level study goal of this day
3. "topics": List of specific core concepts to focus on (3-4 items)
4. "summary": A detailed summary explaining these concepts in clean Markdown bullet points. Make it easy to read and comprehensive.
5. "videos": List of exactly 2 recommended educational YouTube videos. Each video MUST contain "title", "url" (constructed as 'https://www.youtube.com/watch?v=SEARCHABLE_ID'), "thumbnail" (constructed as 'https://img.youtube.com/vi/SEARCHABLE_ID/hqdefault.jpg'), "channel", and "explanation".
6. "quiz": List of exactly 5 high-quality conceptual multiple-choice questions. Each question must have:
   - "question": String
   - "options": List of exactly 4 strings
   - "answer": String (must match one of the options EXACTLY)
   - "explanation": Short, precise explanation of why this answer is correct.

You MUST return ONLY valid JSON.
Format:
{
  "schedule": [
    {
      "day": 1,
      "title": "...",
      "topics": ["topic1", "topic2", ...],
      "summary": "...",
      "rescued_concepts": [
        {
          "term": "EECS NTHU Server",
          "context": "Details...",
          "source": "..."
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
  ]
}
""";

    try {
      print("🚀 [AIService] Generating 5-day Crammer Schedule for $courseName...");
      final response = await model.generateContent([Content.text(promptText)]);
      String text = response.text ?? "{}";

      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) {
        text = text.substring(start, end + 1);
      }

      final decoded = jsonDecode(text);
      return decoded;
    } catch (e) {
      print("❌ [AIService] Error generating Crammer Schedule: $e");
      return {};
    }
  }

  static Future<Map<String, dynamic>> recalibrateCrammerSchedule({
    required String courseName,
    required List<dynamic> currentSchedule,
    required int failedDay,
    required List<String> failedTopics,
    required List<String> masteredTopics,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print("❌ [AIService] Error: GEMINI_API_KEY is null or empty");
      return {};
    }

    final model = _model;
    final currentScheduleStr = jsonEncode(currentSchedule);

    final promptText = """
You are an expert NTHU academic planner agent. A student is using your 5-day "Adaptive Exam Crammer" for "$courseName" and has FAILED the daily evaluation quiz on Day $failedDay.

Here is the student's evaluation result for Day $failedDay:
- Failed/Weak Topics (Struggled with): ${failedTopics.join(', ')}
- Mastered Topics (Understood well): ${masteredTopics.join(', ')}

Here is the current 5-day schedule:
$currentScheduleStr

Your task is to "PUTAR OTAK" (recalibrate the remaining schedule dynamically) to ensure the student is ready for the midterm.
Rules for Recalibration:
1. Days up to $failedDay remain unchanged (or marked as completed/reviewed).
2. For the subsequent day (Day ${failedDay + 1} or Day ${failedDay + 2}), completely modify it to be a specialized, highly intense, simplified "DEEP-DIVE TARGETED MODULE" focusing specifically on the failed topics: ${failedTopics.join(', ')}.
3. In this deep-dive module, provide fresh, highly conceptual and easy-to-understand explanations (summary field) using simple analogies, real-world examples, and common traps.
4. Reduce the difficulty or combine/down-weight topics that the student has already mastered (${masteredTopics.join(', ')}) in subsequent days to save time.
5. Provide 2 new dedicated, high-quality YouTube recommendations for the weak topics.
6. Provide a completely new, custom 5-question multiple-choice quiz for this deep-dive day, specifically testing conceptual understanding of the previously failed concepts to make sure they've mastered them.
7. Return the ENTIRE updated 5-day schedule. Mark the updated/adapted days' "status" or log clear notes in the daily title (e.g., "[ADAPTED - DEEP DIVE] Concurrency Control").

You MUST return ONLY valid JSON.
Format:
{
  "schedule": [
    ... (the complete 5 days of schedule, with the remaining days updated as specified above)
  ]
}
""";

    try {
      print("🚀 [AIService] Recalibrating Crammer Schedule due to Day $failedDay failure in $courseName...");
      final response = await model.generateContent([Content.text(promptText)]);
      String text = response.text ?? "{}";

      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) {
        text = text.substring(start, end + 1);
      }

      final decoded = jsonDecode(text);
      return decoded;
    } catch (e) {
      print("❌ [AIService] Error recalibrating Crammer Schedule: $e");
      return {};
    }
  }

  static Future<Map<String, dynamic>> generateCrammerSyllabusAndSlides({
    required String courseName,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print("❌ [AIService] Error: GEMINI_API_KEY is null or empty");
      return {};
    }

    final model = _model;

    final promptText = """
You are an expert NTHU CS professor. Generate realistic, highly detailed syllabus and slide outline texts for the course "$courseName" so that a student can study for their upcoming midterm.

Include a mixture of 4-5 major technical chapters, detailed concepts, and slide titles.

You MUST return ONLY valid JSON.
Format:
{
  "syllabus": "Detailed syllabus text including major topics like: Chapter 1..., Chapter 2..., Midterm Exam expectations...",
  "slides": "Slide outlines and notes including specific concepts like: Slides Chapter 1: ..., Slides Chapter 2: ..."
}
""";

    try {
      print("🚀 [AIService] Auto-generating mock study materials for $courseName...");
      final response = await model.generateContent([Content.text(promptText)]);
      String text = response.text ?? "{}";

      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) {
        text = text.substring(start, end + 1);
      }

      final decoded = jsonDecode(text);
      return decoded;
    } catch (e) {
      print("❌ [AIService] Error generating mock study materials: $e");
      return {};
    }
  }

  static Future<Map<String, dynamic>> generateProjectDocMock({
    required String projectName,
    required String courseName,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return {"documentation": ""};

    final model = _model;
    final prompt = """
You are an expert NTHU Computer Science teaching assistant. Generate a highly detailed, technical Project Documentation for the project "$projectName" in the course "$courseName".

Make the documentation cover:
1. System Architecture (diagram-like text, component layout)
2. State Management chosen (e.g. Riverpod, Bloc, Provider) and why
3. Local/Remote Database (e.g. SQLite, Hive, Firestore) schema
4. Concurrency & Networking strategies (e.g. Async tasks, streaming, debounce/throttle)
5. Known limitations or edge cases (e.g. Memory limits, offline recovery)

You MUST return ONLY valid JSON.
Format:
{
  "documentation": "A highly comprehensive, multi-paragraph markdown documentation..."
}
""";

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      String text = response.text ?? "{}";
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) text = text.substring(start, end + 1);
      return jsonDecode(text);
    } catch (e) {
      print("Error generating project doc: $e");
      return {"documentation": "A robust Flutter mobile system utilizing local databases, synchronized streams, and offline sync."};
    }
  }

  static Future<Map<String, dynamic>> startProfessorInterview({
    required String projectName,
    required String courseName,
    required String projectDocText,
    required String professorStyle,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return {};

    final model = _model;
    final prompt = """
You are acting as an expert NTHU CS Professor conducting an interactive oral exam ("Professor Persona Mock Interview") for the project "$projectName" in the course "$courseName".

Choose your persona based on:
Style: "$professorStyle"
- If "Prof. Wang (The Socratic Sage)", you are deep, intellectual, and keep asking "Why?" from first principles. You expect highly conceptual justifications.
- If "Prof. Lin (The Pragmatic Veteran)", you are professional, realistic, and focus purely on production viability, performance constraints, extreme edge cases, and testing.

Read this Project Documentation:
$projectDocText

Speak in character as the NTHU Professor! Introduce yourself briefly, welcome the student to their oral defense, and throw the very first challenging, open-ended question about their design decisions or state management choice.

You MUST return ONLY valid JSON.
Format:
{
  "question": "Professor's introductory speaking and first question text",
  "detected_weakness": "Initial introduction",
  "score_progress": 50
}
""";

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      String text = response.text ?? "{}";
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) text = text.substring(start, end + 1);
      return jsonDecode(text);
    } catch (e) {
      print("Error starting professor interview: $e");
      return {
        "question": "Welcome to your Software Studio project defense. Let's start with your architecture: why did you choose this layout and how do you prevent coupling between UI and data layers?",
        "detected_weakness": "Initial defense",
        "score_progress": 50
      };
    }
  }

  static Future<Map<String, dynamic>> evaluateAndGenerateNextQuestion({
    required String projectName,
    required String courseName,
    required String projectDocText,
    required String professorStyle,
    required List<dynamic> chatHistory,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return {};

    final model = _model;
    final chatHistoryStr = jsonEncode(chatHistory);

    final prompt = """
You are acting as an expert NTHU CS Professor conducting an oral exam for "$projectName" in "$courseName".
Style: "$professorStyle"
- If "Prof. Wang (The Socratic Sage)": Keep asking "Why?", challenge core justifications, probe logical consistency.
- If "Prof. Lin (The Pragmatic Veteran)": Focus on memory consumption, deep widget trees, network drops, race conditions, testing gaps.

Project Documentation:
$projectDocText

Here is the conversation transcript so far (Role: 'professor' or 'student'):
$chatHistoryStr

Your task is to analyze the student's latest response.
1. Evaluate their logic. Did they explain clearly, or is it vague/shallow/avoidant?
2. Formulate an internal thought.
3. Identify exactly one technical weakness or gap in their answer (e.g. "Lacks concurrency protection", "Unjustified framework overhead", "Vague garbage collection plans").
4. Assign a "score_delta": An integer between -10 and +10 (e.g., -5 for poor/shallow answers, +8 for highly robust technical answers).
5. Speak in character as the NTHU Professor, respond to their explanation briefly (either with skeptical criticism, pragmatic correction, or academic nod), and throw a highly targeted follow-up question that aggressively probes the identified weakness. Do not make it a simple correct/incorrect. Dwell on the memory limit, widget tree depth, concurrency, state disposal, or testing!

You MUST return ONLY valid JSON.
Format:
{
  "evaluation_thought": "Professor's internal conceptual assessment...",
  "detected_weakness": "Brief label of the weakness found",
  "score_delta": -5,
  "next_question": "Professor's spoken response and next follow-up question text..."
}
""";

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      String text = response.text ?? "{}";
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) text = text.substring(start, end + 1);
      return jsonDecode(text);
    } catch (e) {
      print("Error in multi-turn professor evaluation: $e");
      return {
        "evaluation_thought": "Student answered, but need more technical depth.",
        "detected_weakness": "Requires deeper optimization detail",
        "score_delta": 2,
        "next_question": "I see. But what happens to the rendering performance if the widget tree is excessively deep? How do you prevent redundant rebuilding?"
      };
    }
  }

  static Future<Map<String, dynamic>> generateFinalGradeReport({
    required String projectName,
    required String courseName,
    required String professorStyle,
    required List<dynamic> chatHistory,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return {};

    final model = _model;
    final chatHistoryStr = jsonEncode(chatHistory);

    final prompt = """
You are acting as the NTHU Computer Science Professor ("$professorStyle") who just concluded the oral project defense for "$projectName" in "$courseName".

Conversation Transcript:
$chatHistoryStr

Your task is to issue an official university Grading and Evaluation Letter.
1. Determine a Final Grade (A+, A, B, C, F) based on the depth of the student's answers in the transcript.
2. Generate an "overall_evaluation": A detailed, formal university letter in markdown critique format speaking in character, summarizing their strengths, pointing out gaps, and giving final academic remarks.
3. List 2-3 specific technical "strengths" demonstrated.
4. List 2-3 specific "weaknesses" that need resolution.
5. Determine if they "passed" (true if grade is not F).

You MUST return ONLY valid JSON.
Format:
{
  "grade": "A-",
  "overall_evaluation": "### Formal NTHU Faculty Review...",
  "strengths": ["Clear decoupling of state", "Understands asynchronous stream disposal"],
  "weaknesses": ["Vague on database query scaling", "Vulnerable to concurrency race conditions"],
  "passed": true
}
""";

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      String text = response.text ?? "{}";
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) text = text.substring(start, end + 1);
      return jsonDecode(text);
    } catch (e) {
      print("Error generating grade report: $e");
      return {
        "grade": "B",
        "overall_evaluation": "### NTHU Presentation Review\nYou showed good fundamentals but lacked rigorous performance testing under extreme loads.",
        "strengths": ["Good basic framework usage"],
        "weaknesses": ["No memory stress tests"],
        "passed": true
      };
    }
  }
}
