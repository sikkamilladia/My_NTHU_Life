import 'package:my_nthu_life/data/semester.dart';

/// Called once when a new user has no saved transcript data.
/// Seeds 4 semesters of CS courses into memory, then the caller
/// should invoke saveCourses() + saveAllToFirebase() to persist.
List<Semester> getDefaultSemesters() {
  return [
    Semester(
      semesterName: "Semester 1",
      courses: [
        {
          'name': 'Introduction to Programming I',
          'code': '',
          'credits': 3,
          'grade': 'A',
        },
        {'name': 'Calculus I', 'code': 'MATH101', 'credits': 4, 'grade': 'A-'},
        {'name': 'Linear Algebra', 'code': '', 'credits': 3, 'grade': 'B+'},
        {'name': 'English Composition', 'code': '', 'credits': 2, 'grade': 'A'},
        {
          'name': 'Introduction to Logic',
          'code': '',
          'credits': 3,
          'grade': 'A+',
        },
        {'name': 'Basic Mandarin I', 'code': '', 'credits': 3, 'grade': 'A+'},
      ],
    ),
    Semester(
      semesterName: "Semester 2",
      courses: [
        {'name': 'Data Structures', 'code': '', 'credits': 3, 'grade': 'A'},
        {
          'name': 'Discrete Mathematics',
          'code': '',
          'credits': 3,
          'grade': 'B+',
        },
        {
          'name': 'Object-Oriented Programming',
          'code': '',
          'credits': 3,
          'grade': 'A-',
        },
        {'name': 'Calculus II', 'code': '', 'credits': 4, 'grade': 'B'},
        {'name': 'Physics I', 'code': '', 'credits': 3, 'grade': 'B+'},
      ],
    ),
    Semester(
      semesterName: "Semester 3",
      courses: [
        {'name': 'Algorithms', 'code': '', 'credits': 3, 'grade': 'A-'},
        {
          'name': 'Computer Organization',
          'code': '',
          'credits': 3,
          'grade': 'B+',
        },
        {
          'name': 'Probability & Statistics',
          'code': '',
          'credits': 3,
          'grade': 'A',
        },
        {'name': 'Database Systems', 'code': '', 'credits': 3, 'grade': 'A'},
        {'name': 'Digital Circuits', 'code': '', 'credits': 3, 'grade': 'B'},
      ],
    ),
    Semester(
      semesterName: "Semester 4",
      courses: [
        {'name': 'Operating Systems', 'code': '', 'credits': 3, 'grade': 'A-'},
        {'name': 'Computer Networks', 'code': '', 'credits': 3, 'grade': 'B+'},
        {
          'name': 'Computer Architecture',
          'code': '',
          'credits': 3,
          'grade': 'A',
        },
        {
          'name': 'Software Engineering',
          'code': '',
          'credits': 3,
          'grade': 'B+',
        },
        {
          'name': 'Theory of Computation',
          'code': '',
          'credits': 3,
          'grade': 'A-',
        },
      ],
    ),
  ];
}
