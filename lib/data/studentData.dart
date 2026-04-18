import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Required for jsonEncode and jsonDecode
import 'package:my_nthu_life/firstTimeEntry.dart';

Map<String, String> studentDatabase = {
  "admin": "1234",
};

class StudentUtilities{
  static int getStudentYear(String studentID){
    if(studentID.length < 3) return 1;

    int entryYear = int.parse(studentID.substring(0,3));

    return(115 - entryYear);
  }

  static int calculatePastSemesters(String studentID){
    int year = getStudentYear(studentID);
    return(year - 1) * 2 + 1;
  }
}

// 1. Save the databse to the phone/PC memory
Future<void> saveUsers() async{
  final prefs = await SharedPreferences.getInstance();
  String encodedData = jsonEncode(studentDatabase);
  await prefs.setString('student_list', encodedData);
}

Future<void> saveStudentData(String studentID, int totalCredits) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('${studentID}_credits', totalCredits);
}

// 2. Load the database when the app starts
Future<void> loadUsers() async{
  final prefs = await SharedPreferences.getInstance();
  String? encodedData = prefs.getString('student_list');
  if(encodedData != null){
    studentDatabase = Map<String, String>.from(jsonDecode(encodedData));
  }
}