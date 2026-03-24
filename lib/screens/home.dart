import 'package:flutter/material.dart';
import '../credit_page.dart';
import '../gpa_predictor.dart';

class Home extends StatefulWidget {
  final String studentID;

  const Home({super.key, required this.studentID});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      Center(child: Text("Welcome ${widget.studentID}")),
      CreditPage(studentID: widget.studentID),
      GPAPredictor(),
      Center(child: Text("Notes Page")),
    ];
  }

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My NTHU Life"),
      ),

      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Credit"),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "gpa"),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: "Notes"),
        ],
      ),
    );
  }
}