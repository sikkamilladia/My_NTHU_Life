import 'package:flutter/material.dart';
import 'package:my_nthu_life/signUp.dart';
import 'package:my_nthu_life/studentData.dart';
import './home.dart';

//Stateful widget for the Login Screen
class Login extends StatefulWidget{
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

//State class for the Login Widget
class _LoginState extends State<Login>{
  final formKey = GlobalKey<FormState>();

  String id = "";
  String password = "";

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              //Student ID
              TextFormField(
                decoration: const InputDecoration(labelText: 'Student ID'),
                onChanged: (value) => id = value, //updates 'id' as you type
              ),

              //Password
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                onChanged: (value) => password = value, // Again, updates 'password' as you type
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: (){
                  if(studentDatabase.containsKey(id)){
                    if(studentDatabase[id] == password){
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home(studentID: id)));
                    } else{
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Incorrect password/Student ID. Try Again!'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                      );
                    }
                  } else{
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Student ID not found. Redirecting to Sign Up...')),
                    );

                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUp()),
                    );
                  }
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}