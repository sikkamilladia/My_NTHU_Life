import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_nthu_life/services/agent_services.dart';

class AgentPlannerModal extends StatefulWidget {
  // 🎯 1. Receive the synchronized string parameter passed from the button
  final String targetDateKey;

  const AgentPlannerModal({super.key, required this.targetDateKey});

  @override
  State<AgentPlannerModal> createState() => _AgentPlannerModalState();
}

class _AgentPlannerModalState extends State<AgentPlannerModal> {
  double _selectedHours = 3.0;
  bool _isLoading = false;
  Map<String, dynamic>? _agentResponse;

  final String _testStudentID = "abby_tsai_nthu";

  void _triggerAgentAnalysis() async {
    setState(() {
      _isLoading = true;
    });

    final result = await AgentService.fetchAgentPlan(_selectedHours.toInt());

    setState(() {
      _agentResponse = result;
      _isLoading = false;
    });
  }

  void _commitMissionsToFirestore(List<dynamic> missions) async {
    final firestore = FirebaseFirestore.instance;

    print("🚀 DEPLOY BUTTON TAPPED. Target Date Key: ${widget.targetDateKey}");
    if (missions.isEmpty) return;

    try {
      final batch = firestore.batch();

      for (var mission in missions) {
        final String taskName = mission['task_name'] ?? mission['title'] ?? 'Tactical Mission';
        final String courseName = mission['course_name'] ?? mission['course'] ?? 'General Task';
        final int minutes = mission['allocated_minutes'] ?? mission['duration_minutes'] ?? 30;

        final docRef = firestore
            .collection('users')
            .doc(_testStudentID)
            .collection('tasks')
            .doc();

        batch.set(docRef, {
          'title': "$taskName (${minutes}m)",
          'course': courseName,
          'category': 'Homework',
          'assignedDayString': widget.targetDateKey, // 🔑 2. Links directly to your grid selection
          'repeatType': 'None',
          'repeatDays': [],
          'exp': 5,
          'coins': 2,
          'isDone': false,
          'completedDates': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      print("⏳ Committing batch to emulator...");
      await batch.commit();
      print("✅ Batch write successful!");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎯 Tactical missions locked into your timeline!'),
            backgroundColor: Color(0xFF7B2CBF),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("❌ Error writing to Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Quest Master Agent", style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              "Target Date: ${widget.targetDateKey}",
              style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),

            if (_agentResponse == null && !_isLoading) ...[
              Text("Available Time: ${_selectedHours.toInt()} Hours", style: theme.textTheme.labelLarge),
              Slider(
                value: _selectedHours,
                min: 1,
                max: 8,
                divisions: 7,
                label: "${_selectedHours.toInt()}h",
                onChanged: (value) {
                  setState(() {
                    _selectedHours = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _triggerAgentAnalysis,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text("Analyze Workload"),
                ),
              ),
            ],

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (_agentResponse != null && !_isLoading) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _agentResponse!['agent_reasoning'] ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 20),
              ...(_agentResponse!['study_missions'] as List<dynamic>).map((mission) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(mission['task_name'] ?? 'Study Block'),
                    subtitle: Text("${mission['course_name'] ?? 'General'} • ${mission['allocated_minutes'] ?? 30} mins"),
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _commitMissionsToFirestore(_agentResponse!['study_missions']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text("Accept & Deploy to Timeline Grid"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}