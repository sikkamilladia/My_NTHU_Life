// import 'package:flutter/material.dart';
// import 'package:my_nthu_life/screens/signUp.dart';
// import 'package:my_nthu_life/data/studentData.dart';
// import 'home.dart';

// //Stateful widget for the Login Screen
// class Login extends StatefulWidget {
//   const Login({super.key});

//   @override
//   State<Login> createState() => _LoginState();
// }

// //State class for the Login Widget
// class _LoginState extends State<Login> {
//   final formKey = GlobalKey<FormState>();

//   String id = "";
//   String password = "";

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Login')),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Form(
//           key: formKey,
//           child: Column(
//             children: [
//               //Student ID
//               TextFormField(
//                 decoration: const InputDecoration(labelText: 'Student ID'),
//                 onChanged: (value) => id = value, //updates 'id' as you type
//               ),

//               //Password
//               TextFormField(
//                 obscureText: true,
//                 decoration: const InputDecoration(labelText: 'Password'),
//                 onChanged: (value) =>
//                     password = value, // Again, updates 'password' as you type
//               ),

//               const SizedBox(height: 20),

//               ElevatedButton(
//                 onPressed: () {
//                   if (studentDatabase.containsKey(id)) {
//                     if (studentDatabase[id] == password) {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => Home(studentID: id),
//                         ),
//                       );
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text(
//                             'Incorrect password/Student ID. Try Again!',
//                           ),
//                           backgroundColor: Colors.redAccent,
//                           behavior: SnackBarBehavior.floating,
//                         ),
//                       );
//                     }
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text(
//                           'Student ID not found. Redirecting to Sign Up...',
//                         ),
//                       ),
//                     );

//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => const SignUp()),
//                     );
//                   }
//                 },
//                 child: const Text('Login'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:my_nthu_life/data/studentData.dart';
import '../widgets/auth_widgets.dart';
import 'home.dart';

class Login extends StatefulWidget {
  final VoidCallback onSwitchToSignup;
  final bool narrow;

  const Login({super.key, required this.onSwitchToSignup, this.narrow = false});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String id = '';
  String password = '';
  bool _passwordVisible = false;
  String? _error;

  void _handleLogin() {
    setState(() => _error = null);

    if (id.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (!studentDatabase.containsKey(id)) {
      setState(() => _error = 'Student ID not found.');
      return;
    }
    if (studentDatabase[id] != password) {
      setState(() => _error = 'Incorrect password.');
      return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => Home(studentID: id),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: widget.narrow
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text("Welcome Back", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          "Log in to your NTHU Life account",
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 32),
        authInputField(
          label: "Student ID",
          icon: Icons.badge_outlined,
          onChanged: (v) => id = v,
        ),
        const SizedBox(height: 16),
        authInputField(
          label: "Password",
          icon: Icons.lock_outline_rounded,
          obscure: !_passwordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white38,
              size: 18,
            ),
            onPressed: () =>
                setState(() => _passwordVisible = !_passwordVisible),
          ),
          onChanged: (v) => password = v,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          authErrorBanner(_error!),
        ],
        const SizedBox(height: 28),
        authPrimaryButton(
          label: "Log In",
          accent: const Color(0xFF7C3AED),
          onTap: _handleLogin,
        ),
        if (widget.narrow) ...[
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: widget.onSwitchToSignup,
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                  ),
                  children: const [
                    TextSpan(
                      text: "Sign Up",
                      style: TextStyle(
                        color: Color(0xFF3A52ED),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
