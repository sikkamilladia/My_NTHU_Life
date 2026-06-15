const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { GoogleGenAI } = require('@google/genai');

admin.initializeApp();
const db = admin.firestore();

// Initialize the Gemini SDK using the API key from your environment variables
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

// --- AGENT TOOLS (FUNCTIONS) ---

// Fetches tasks from your true path: users/{studentID}/tasks
async function fetchCurrentUnfinishedTasks(studentID) {
    if (!studentID) return [];
    try {
        const snapshot = await db.collection('users')
            .doc(studentID)
            .collection('tasks')
            .where('isDone', '==', false) // Aligns with your Flutter boolean key
            .get();

        return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error("Error fetching tasks:", error);
        return [];
    }
}

// Fetches quests/calendar events from your daily tracker path
async function fetchTodayCalendarEvents(studentID) {
    if (!studentID) return [];
    try {
        const todayStr = new Date().toISOString().split('T')[0]; // e.g., "2026-06-15"
        const snapshot = await db.collection('users')
            .doc(studentID)
            .collection('tasks')
            .where('date', '==', todayStr) // Looks up items assigned for today
            .get();

        return snapshot.docs.map(doc => doc.data());
    } catch (error) {
        console.error("Error fetching events:", error);
        return [];
    }
}

// --- MAIN AUTONOMOUS AGENT CONTROLLER ---

exports.runStudyPlannerAgent = functions.https.onCall(async (data, context) => {
    // Grab both availableHours and studentID sent from your Flutter app payload
    const availableHours = data.availableHours || 3;
    const studentID = data.studentID || "abby_tsai_nthu"; // Fallback safeguard

    // Define the tool parameters matching the Gemini SDK structure
    const fetchCurrentUnfinishedTasksDeclaration = {
        name: 'fetchCurrentUnfinishedTasks',
        description: 'Retrieves all active student assignments, deadlines, and difficulties from Firestore.',
        parameters: { type: 'OBJECT', properties: {} }
    };

    const fetchTodayCalendarEventsDeclaration = {
        name: 'fetchTodayCalendarEvents',
        description: 'Checks if the user already has tasks scheduled on their timeline grid for today.',
        parameters: { type: 'OBJECT', properties: {} }
    };

    // Start an interactive chat session with the model
    const chat = ai.chats.create({
        model: 'gemini-2.5-flash',
        config: {
            systemInstruction: `You are the NTHU Agentic Quest Master. Your goal is to build a personalized study plan based on the user's available hours today.
      
      CRITICAL JSON FORMAT STEPS:
      1. Reasoning: Call 'fetchCurrentUnfinishedTasks' to gather their real-time homework state.
      2. Reasoning: Call 'fetchTodayCalendarEvents' to see what is already scheduled.
      3. Execution: Prioritize tasks by urgency. Budget tasks so total allocated minutes match or are slightly under the user's available time.
      4. Format: Return ONLY a raw JSON object containing an 'agent_reasoning' string and a 'study_missions' array.
      
      Each item inside 'study_missions' MUST use these exact keys:
      {
        "task_name": "Name of the task",
        "course_name": "Name of the course",
        "allocated_minutes": 45,
        "difficulty": "High"
      }
      Do not wrap inside markdown code blocks (no \`\`\`json blocks).`,
            tools: [{ functionDeclarations: [fetchCurrentUnfinishedTasksDeclaration, fetchTodayCalendarEventsDeclaration] }]
        }
    });

    console.log(`🚀 Triggering agent workflow for student: ${studentID} (${availableHours}h window)`);

    // 1. Send the initial message to kick off the agent workflow
    let response = await chat.sendMessage({
        message: `I have ${availableHours} hours available to allocate today. Analyze my workload and build my missions.`,
        functionHandlers: {
            // ⭐ FIXED: Wrapped array returns inside proper JSON response objects
            fetchCurrentUnfinishedTasks: async () => {
                console.log("🤖 Tool Execution: Fetching unfinished tasks...");
                const dataList = await fetchCurrentUnfinishedTasks(studentID);
                return { unfinished_tasks: dataList }; 
            },
            fetchTodayCalendarEvents: async () => {
                console.log("🤖 Tool Execution: Fetching today's calendar events...");
                const dataList = await fetchTodayCalendarEvents(studentID);
                return { current_calendar_events: dataList };
            }
        }
    });

    // 2. THE MULTI-TURN RESOLVER LOOP
    let attempts = 0;
    while (!response.text && attempts < 4) {
        console.log(`🔄 Agent is processing tool responses (Turn ${attempts + 1})...`);
        response = await chat.sendMessage({
            message: "Proceed and output your final structured JSON plan using the exact specified keys."
        });
        attempts++;
    }

    // 3. Extract the final text payload safely supporting nested part fallbacks
    let responseText = response.text;
    if (!responseText && response.candidates?.[0]?.content?.parts) {
        const parts = response.candidates[0].content.parts;
        for (const part of parts) {
            if (part.text) responseText = part.text;
        }
    }

    if (!responseText) {
        console.error("❌ Gemini got stuck. Response Dump:", JSON.stringify(response));
        throw new functions.https.HttpsError('internal', 'Gemini failed to generate text after executing functions.');
    }

    console.log("✅ Raw Response Received:", responseText);

    // Clean up any rogue Markdown code block styling
    let cleanText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();

    // Hand the clean parsed JSON object back to your Flutter App
    return JSON.parse(cleanText);
});