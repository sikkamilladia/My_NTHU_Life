import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Required for jsonEncode and jsonDecode

Map<String, String> studentDatabase = {
  "admin": "1234",
};

// 1. Save the databse to the phone/PC memory
Future<void> saveUsers() async{
  final prefs = await SharedPreferences.getInstance();
  String encodedData = jsonEncode(studentDatabase);
  await prefs.setString('student_list', encodedData);
}

// 2. Load the database when the app starts
Future<void> loadUsers() async{
  final prefs = await SharedPreferences.getInstance();
  String? encodedData = prefs.getString('student_list');
  if(encodedData != null){
    studentDatabase = Map<String, String>.from(jsonDecode(encodedData));
  }
}