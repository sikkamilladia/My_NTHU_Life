import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_nthu_life/pet_files/pet_provider.dart';
import 'package:my_nthu_life/screens/exam_crammer.dart';

void main() {
  testWidgets('Adaptive Exam Crammer UI Render Test', (WidgetTester tester) async {
    // Build our widget inside a Mock Provider
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<PetProvider>(
          create: (_) => PetProvider(),
          child: const AdaptiveExamCrammerScreen(studentID: 'test_student_123'),
        ),
      ),
    );

    // Verify loading or main Ingestion phase elements
    expect(find.text("CRAMMER WAR ROOM"), findsOneWidget);
  });
}
