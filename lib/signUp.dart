import 'package:flutter/material.dart';
import 'studentData.dart'; // Import the shared map

class SignUp extends StatefulWidget{
  const SignUp({super.key});
  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp>{
  String newID = '';
  String newPassword = '';

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Create My NTHU Life Account')),
      body: Center(
        child: SizedBox(
          width: 300,
          child: Column(
            children: [
              TextField(onChanged: (value) => newID = value, decoration: const InputDecoration(labelText: 'Student ID')),
              TextField(onChanged: (value) => newPassword = value, decoration: const InputDecoration(labelText: 'Password')),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  if(newID.isNotEmpty && newPassword.isNotEmpty){
                    studentDatabase[newID] = newPassword;
                    await saveUsers();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}