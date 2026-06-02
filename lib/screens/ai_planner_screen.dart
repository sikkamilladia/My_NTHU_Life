
import 'package:flutter/material.dart';
import 'package:my_nthu_life/services/ai_service.dart';
import 'dart:convert';

class AIPlannerScreen extends StatefulWidget {
  const AIPlannerScreen({super.key});

  @override
  State<AIPlannerScreen> createState() => _AIPlannerScreenState();
}

class _AIPlannerScreenState extends State<AIPlannerScreen> {
  final controller = TextEditingController();
  String result = "";
  bool loading = false;

  Future<void> generate() async {
    setState(() => loading = true);

    final output = await AIService.generateRoadmap(controller.text);

    setState(() {
      result = const JsonEncoder.withIndent(' ').convert(output);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Study Planner")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "What do you want to learn?",
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: generate,
              child: const Text("Generate Plan"),
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : Expanded(child: SingleChildScrollView(child: Text(result))),
          ],
        ),
      ),
    );
  }
}