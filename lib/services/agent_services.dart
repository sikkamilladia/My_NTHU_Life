import 'package:cloud_functions/cloud_functions.dart';

class AgentService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Future<Map<String, dynamic>?> fetchAgentPlan(
    int availableHours,
  ) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'runStudyPlannerAgent',
      );
      final response = await callable.call(<String, dynamic>{
        'availableHours': availableHours,
      });
      return response.data != null
          ? Map<String, dynamic>.from(response.data)
          : null;
    } catch (e) {
      print("❌ [Agent Service Error]: $e");
      return null;
    }
  }
}
