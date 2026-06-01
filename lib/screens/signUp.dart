import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/auth_widgets.dart';

class SignUp extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  final bool narrow;

  const SignUp({super.key, required this.onSwitchToLogin, this.narrow = false});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String id = '';
  String email = '';
  String password = '';
  String confirm = '';
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  String? _error;
  bool _isLoading = false;

  void _handleSignup() async {
    setState(() => _error = null);

    if (id.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user metadata in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'studentID': id,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),

        'courses' : {}
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created! Please log in.'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      widget.onSwitchToLogin();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: widget.narrow
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create account",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Join NTHU Life and track your credits",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 28),

                  authInputField(
                    label: "Student ID",
                    icon: Icons.badge_outlined,
                    onChanged: (v) => id = v,
                  ),
                  const SizedBox(height: 14),
                  
                  authInputField(
                    label: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) => email = v,
                  ),
                  const SizedBox(height: 14),

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

                  const SizedBox(height: 14),

                  authInputField(
                    label: "Confirm Password",
                    icon: Icons.lock_outline_rounded,
                    obscure: !_confirmVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white38,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _confirmVisible = !_confirmVisible),
                    ),
                    onChanged: (v) => confirm = v,
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    authErrorBanner(_error!),
                  ],

                  const SizedBox(height: 24),

                  _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : authPrimaryButton(
                        label: "Sign Up",
                        accent: const Color(0xFF3A52ED),
                        onTap: _handleSignup,
                      ),

                  if (widget.narrow) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: widget.onSwitchToLogin,
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 13,
                            ),
                            children: const [
                              TextSpan(
                                text: "Log In",
                                style: TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const Spacer(), // keeps center feel
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}