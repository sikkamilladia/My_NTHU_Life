import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _error = null);

    if (id.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Find the user's email by student ID
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('studentID', isEqualTo: id)
          .get();

      if (userQuery.docs.isEmpty) {
        setState(() => _error = 'Student ID not found.');
        return;
      }

      final email = userQuery.docs.first['email'];

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => Home(studentID: id),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _showResetPasswordDialog(context),
            child: const Text(
              "Forgot Password?",
              style: TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          authErrorBanner(_error!),
        ],
        const SizedBox(height: 28),
        _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : authPrimaryButton(
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
  void _showResetPasswordDialog(BuildContext context) {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Reset Password"),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: "Enter your email",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await FirebaseAuth.instance.sendPasswordResetEmail(
                email: controller.text.trim(),
              );

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Reset link sent to email"),
                  backgroundColor: Colors.green,
                ),
              );
            } on FirebaseAuthException catch (e) {
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.message ?? "Error occurred"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text("Send"),
        ),
      ],
    ),
  );
}
}