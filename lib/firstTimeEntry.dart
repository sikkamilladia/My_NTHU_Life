import 'package:flutter/material.dart';
import 'data/studentData.dart';
import 'screens/home.dart'; // Make sure to import Home!

class FirstTimeEntry extends StatefulWidget {
  final String studentID;
  const FirstTimeEntry({super.key, required this.studentID});

  @override
  State<FirstTimeEntry> createState() => _FirstTimeEntryState();
}

class _FirstTimeEntryState extends State<FirstTimeEntry> {
  late int pastSemesters;
  List<TextEditingController> controllers = [];

  final TextEditingController currentLoadController = TextEditingController();

  @override
  void initState() {
    super.initState();

    pastSemesters = StudentUtilities.calculatePastSemesters(widget.studentID);
    controllers = List.generate(pastSemesters, (index) => TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Initial Credit Setup")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Welcome, ${widget.studentID}! Please enter credits for past semesters:"),
            Expanded(
              child: ListView.builder(
                itemCount: pastSemesters,
                itemBuilder: (context, index) {
                  return TextField(
                    controller: controllers[index],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Semester ${index + 1} Credits",
                    ),
                  );
                },
              ),
            ),
            // ADD THIS: The field for current credits
            TextField(
              controller: currentLoadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Current Semester Load"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                int pastTotal = controllers.fold(0, (sum, c) => sum + (int.tryParse(c.text) ?? 0));
                int currentSemesterLoad = int.tryParse(currentLoadController.text) ?? 0;
                int grandTotal = pastTotal + currentSemesterLoad;

                await saveStudentData(widget.studentID, grandTotal);

                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Home(studentID: widget.studentID),
                  ),
                );
              },
              child: const Text("Save and Continue"), // FIX: Added button text
            ),
          ],
        ),
      ),
    );
  }
}