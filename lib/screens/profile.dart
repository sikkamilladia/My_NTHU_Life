import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  // Added an optional studentID parameter so home.dart stops throwing errors
  final String? studentID;

  const ProfileScreen({
    super.key, 
    this.studentID,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Static default avatar replacing the image picker display
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            // Optional: Displays the ID if passed, just to show it works
            if (widget.studentID != null) ...[
              Text(
                'Student ID: ${widget.studentID}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
            ],

            // Placeholder button notifying the user that the feature is disabled
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Custom profile pictures are currently disabled."),
                  ),
                );
              },
              icon: const Icon(Icons.no_photography),
              label: const Text('Profile Picture Disabled'),
            ),
          ],
        ),
      ),
    );
  }
}