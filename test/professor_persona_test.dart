import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_nthu_life/pet_files/pet_provider.dart';
import 'package:my_nthu_life/screens/professor_persona.dart';

void main() {
  testWidgets('Professor Persona UI Render Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<PetProvider>(
          create: (_) => PetProvider(),
          child: const ProfessorPersonaScreen(studentID: 'test_student_123'),
        ),
      ),
    );

    // Verify configuration page is loaded
    expect(find.text("PROFESSOR PERSONA"), findsOneWidget);
    expect(find.text("PROJECT NAME"), findsOneWidget);
  });
}
