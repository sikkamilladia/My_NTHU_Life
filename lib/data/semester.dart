class Semester {
  String semesterName;
  List<Map<String, dynamic>> courses;

  Semester({required this.semesterName, required this.courses});

  Map<String, dynamic> toJson() => {
    'name': semesterName,
    'courses': courses
  };

  // 'factory' to load data back from SharedPreferences
  factory Semester.fromJson(Map<String, dynamic> json){
    return Semester(
      semesterName: json['name'],
      courses: List<Map<String, dynamic>>.from(json['courses']),
    );
  }
}
