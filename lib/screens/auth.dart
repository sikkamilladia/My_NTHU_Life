import 'package:flutter/material.dart';
import 'package:my_nthu_life/screens/login.dart';
import 'package:my_nthu_life/screens/signUp.dart';
import 'dart:ui';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slide;
  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slide = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toSignup() {
    setState(() => _isLogin = false);
    _controller.forward();
  }

  void _toLogin() {
    setState(() => _isLogin = true);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // background image
          Positioned.fill(
            child: Image.asset('assets/auth.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth > 700
                  ? _buildWideLayout()
                  : _buildNarrowLayout(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Container(
      width: 860,
      height: 560,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceBright.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            SizedBox(
              width: 860 * 0.55,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: AnimatedBuilder(
                    animation: _slide,
                    builder: (context, _) {
                      final showLogin = _slide.value < 0.5;
                      final opacity = showLogin
                          ? 1 - (_slide.value * 2).clamp(0.0, 1.0)
                          : ((_slide.value - 0.5) * 2).clamp(0.0, 1.0);

                      return Opacity(
                        opacity: opacity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 44,
                            vertical: 44,
                          ),
                          child: showLogin
                              ? Login(onSwitchToSignup: _toSignup)
                              : SignUp(onSwitchToLogin: _toLogin),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF7C3AED).withOpacity(0.6),
                    const Color(0xFF0EA5E9).withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _slide,
                builder: (context, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _slide.value < 0.5
                      ? _PromoPanel(
                          key: const ValueKey('login-promo'),
                          headline: "New here?",
                          sub:
                              "Create an account and start tracking your NTHU journey today.",
                          buttonLabel: "Sign Up",
                          accent: const Color(0xFF3A52ED),
                          onTap: _toSignup,
                        )
                      : _PromoPanel(
                          key: const ValueKey('signup-promo'),
                          headline: "Already a member?",
                          sub: "Log back in and pick up where you left off.",
                          buttonLabel: "Log In",
                          accent: const Color(0xFF7C3AED),
                          onTap: _toLogin,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            height: 560,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceBright.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),

              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 0.5,
              ),

              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) {
                // Login masuk dari kiri (offset -1,0 → 0,0)
                // SignUp masuk dari kanan (offset 1,0 → 0,0)
                final isLogin = child.key == const ValueKey('login');
                final slideIn =
                    Tween<Offset>(
                      begin: Offset(isLogin ? -1.0 : 1.0, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeInOutCubic,
                      ),
                    );
                return ClipRect(
                  child: SlideTransition(
                    position: slideIn,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                );
              },
              child: _isLogin
                  ? Login(
                      key: const ValueKey('login'),
                      onSwitchToSignup: _toSignup,
                      narrow: true,
                    )
                  : SignUp(
                      key: const ValueKey('signup'),
                      onSwitchToLogin: _toLogin,
                      narrow: true,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  //   Widget _buildBackgroundBlobs() {
  //     return Stack(
  //       children: [
  //         Positioned(
  //           top: -80,
  //           left: -80,
  //           child: _blob(300, const Color(0xFF7C3AED), 0.25),
  //         ),
  //         Positioned(
  //           bottom: -100,
  //           right: -60,
  //           child: _blob(350, const Color(0xFF0EA5E9), 0.18),
  //         ),
  //         Positioned(
  //           top: 300,
  //           left: 200,
  //           child: _blob(180, const Color(0xFF10B981), 0.10),
  //         ),
  //       ],
  //     );
  //   }

  //   Widget _blob(double size, Color color, double opacity) {
  //     return Container(
  //       width: size,
  //       height: size,
  //       decoration: BoxDecoration(
  //         shape: BoxShape.circle,
  //         color: color.withOpacity(opacity),
  //       ),
  //     );
  //   }
}

class _PromoPanel extends StatelessWidget {
  final String headline;
  final String sub;
  final String buttonLabel;
  final Color accent;
  final VoidCallback onTap;

  const _PromoPanel({
    super.key,
    required this.headline,
    required this.sub,
    required this.buttonLabel,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withOpacity(0.1), accent.withOpacity(0.8)],
        ),
      ),
      padding: const EdgeInsets.all(44),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Icon(Icons.school_rounded, color: accent, size: 28),
          ),
          const SizedBox(height: 32),
          Text(headline, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Text(
            sub,
            // style: TextStyle(
            //   fontSize: 14,
            //   color: Colors.white.withOpacity(0.55),
            //   height: 1.6,
            // ),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
