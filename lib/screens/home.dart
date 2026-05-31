import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/main.dart'; // import themeNotifier
import 'package:my_nthu_life/screens/profile.dart';
import 'package:my_nthu_life/screens/task_list_page.dart';
import 'package:my_nthu_life/widgets/pet_dashboard_widget.dart';
import 'task_list_page.dart';
import 'transcript.dart';
import 'study.dart';
import 'gpa_calculator.dart';

class Home extends StatefulWidget {
  final String studentID;

  const Home({super.key, required this.studentID});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  static const _pageTitles = [
    'My NTHU Life', // or whatever you want for Home
    'Transcript',
    'GPA Predictor',
    'Task',
    'Notes',
  ];

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _buildPages();
  }

  void _buildPages() {
    _pages = [
      _HomePage(studentID: widget.studentID),
      CreditPage(studentID: widget.studentID),
      GPAPredictor(studentID: widget.studentID),
      TaskListPage(studentID: widget.studentID),
      Center(
        child: Text(
          "Notes Page",
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
        ),
      ),
    ];
  }

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openDrawer(BuildContext context) {
    // Read current theme from the notifier — single source of truth
    final isDark = themeNotifier.value == ThemeMode.dark;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.45),
        pageBuilder: (context, animation, _) {
          return _SideDrawer(
            animation: animation,
            studentID: widget.studentID,
            isDark: isDark,
            onThemeToggle: () {
              // Toggle the global notifier — MaterialApp rebuilds automatically
              themeNotifier.value = themeNotifier.value == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              Navigator.pop(context);
            },
            onLogout: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: cs.surface,
              elevation: 0,
              title: Text(
                "My NTHU Life",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              actions: [
                Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                        Icons.menu_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 26,
                      ),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                      tooltip: 'Menu',
                    ),
                  ),
                ),
              ],
            )
          : null,
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(
                        0xFF7C3AED,
                      ).withOpacity(0.15),
                      child: const Icon(Icons.person, color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.studentID,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "NTHU Student",
                            style: GoogleFonts.outfit(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(
                  "Profile",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(studentID: widget.studentID),
                    ),
                  );
                },
              ),
              // Dark Mode Toggle
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, currentMode, _) {
                  final isDark = currentMode == ThemeMode.dark;
                  return ListTile(
                    leading: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                    ),
                    title: Text(
                      "Dark Mode",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                    ),
                    trailing: Switch(
                      value: isDark,
                      activeColor: const Color(0xFF7C3AED),
                      onChanged: (val) {
                        themeNotifier.value = val
                            ? ThemeMode.dark
                            : ThemeMode.light;
                      },
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.amber,
                ),
                title: Text(
                  "Global Rank",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "#12",
                    style: GoogleFonts.outfit(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              const Divider(height: 1),

              // Log Out
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                ),
                title: Text(
                  "Log Out",
                  style: GoogleFonts.outfit(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacementNamed('/');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF7C3AED),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Transcript',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Study'),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_rounded),
            label: 'Quest',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Party'),
        ],
      ),
    );
  }
}

// ====== SIDE DRAWER ======
class _SideDrawer extends StatelessWidget {
  final Animation<double> animation;
  final String studentID;
  final bool isDark;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;

  const _SideDrawer({
    required this.animation,
    required this.studentID,
    required this.isDark,
    required this.onThemeToggle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return Align(
      alignment: Alignment.centerRight,
      child: SlideTransition(
        position: slideAnim,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 280,
            height: double.infinity,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(-8, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF3A52ED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          studentID,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "NTHU Student",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Theme toggle
                  _DrawerTile(
                    icon: isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    label: isDark
                        ? "Switch to Light Mode"
                        : "Switch to Dark Mode",
                    iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    onTap: onThemeToggle,
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1,
                    ),
                  ),

                  // Logout
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    label: "Log Out",
                    iconColor: const Color(0xFFEF4444),
                    labelColor: const Color(0xFFEF4444),
                    onTap: onLogout,
                  ),

                  const Spacer(),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      "My NTHU Life v1.0",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? Colors.white.withOpacity(0.75),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: labelColor ?? Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== HOME PAGE ======
class _HomePage extends StatelessWidget {
  final String studentID;

  const _HomePage({required this.studentID});

  @override
  Widget build(BuildContext context) {
    // final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF3A52ED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  studentID,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Track your progress, build your streak, and conquer your semester.",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            "Today",
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 12),

          ValueListenableBuilder<int>(
            valueListenable: totalCreditsNotifier,
            builder: (context, credits, child) {
              return PetDashboardWidget(currentCredits: credits);
            },
          ),
        ],
      ),
    );
  }
}
