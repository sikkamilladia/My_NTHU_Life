import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/pet_files/pet_provider.dart';
import 'package:my_nthu_life/screens/party.dart';
import 'package:provider/provider.dart';
import 'package:my_nthu_life/main.dart';
import 'package:my_nthu_life/screens/profile.dart';
import 'package:my_nthu_life/screens/ai_config_screen.dart';
import 'package:my_nthu_life/screens/task_list_page.dart';
import 'package:my_nthu_life/widgets/pet_dashboard_widget.dart';
import 'package:my_nthu_life/services/firestore_services.dart';
import 'transcript.dart';
import 'study.dart';

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
    _buildPages();
  }

  void _buildPages() {
    _pages = [
      _HomePage(studentID: widget.studentID),
      CreditPage(studentID: widget.studentID),
      AIStudyMaterialWidget(studentID: widget.studentID),
      TaskListPage(studentID: widget.studentID),
      PartyPage(studentID: widget.studentID),
    ];
  }

  void _onTap(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: cs.surface,
              elevation: 0,
              title: Text(
                "NTHYou",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
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
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(widget.studentID).snapshots(),
                builder: (context, snapshot) {
                  String displayName = widget.studentID;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    displayName = data['name'] ?? widget.studentID;
                  }

                  return Padding(
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
                                displayName,
                                style: GoogleFonts.orbitron(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.studentID,
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
                  );
                },
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(
                  "Profile",
                  style: GoogleFonts.orbitron(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
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
              // ListTile(
              //   leading: const Icon(Icons.psychology_outlined),
              //   title: Text(
              //     "AI Config",
              //     style: GoogleFonts.orbitron(
              //       fontWeight: FontWeight.w500,
              //       fontSize: 14,
              //     ),
              //   ),
              //   trailing: const Icon(Icons.chevron_right_rounded),
              //   onTap: () {
              //     Navigator.pop(context);
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) =>
              //             AIConfigScreen(studentID: widget.studentID),
              //       ),
              //     );
              //   },
              // ),
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
                      "Theme Mode",
                      style: GoogleFonts.orbitron(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
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
                  style: GoogleFonts.orbitron(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                trailing: StreamBuilder<int>(
                  stream: FirestoreService().getUserRankStream(
                    widget.studentID,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Icon(
                        Icons.error_outline,
                        color: cs.error,
                        size: 16,
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    final rank = snapshot.data ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rank > 0 ? "#$rank" : "N/A",
                        style: GoogleFonts.outfit(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              const Divider(height: 1),
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
      backgroundColor: cs.surface,
      body: _pages[_selectedIndex],
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: _selectedIndex,
      //   onTap: _onTap,
      //   type: BottomNavigationBarType.fixed,
      //   selectedItemColor: const Color(0xFF7C3AED),
      //   unselectedItemColor: Colors.grey,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.school),
      //       label: 'Transcript',
      //     ),
      //     BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Study'),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.task_rounded),
      //       label: 'Quest',
      //     ),
      //     BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Party'),
      //   ],
      // ),
      bottomNavigationBar: _CustomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const _CustomNavBar({required this.selectedIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_rounded, label: 'HOME'),
    (icon: Icons.school_rounded, label: 'TRANSCRIPT'),
    (icon: Icons.auto_stories_rounded, label: 'STUDY'),
    (icon: Icons.crisis_alert_rounded, label: 'QUEST'),
    (icon: Icons.groups_rounded, label: 'PARTY'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(top: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isSelected = i == selectedIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primaryContainer.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(
                              color: cs.primaryContainer.withOpacity(0.25),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with animated scale
                        AnimatedScale(
                          scale: isSelected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: isSelected
                                ? cs.primaryContainer
                                : cs.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Label
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.orbitron(
                            fontSize: isSelected ? 7.5 : 7,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w400,
                            color: isSelected
                                ? cs.primaryContainer
                                : cs.onSurfaceVariant.withOpacity(0.4),
                            letterSpacing: isSelected ? 1 : 0.5,
                          ),
                          child: Text(item.label),
                        ),
                        // Active indicator dot
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 16 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ====== HOME PAGE ======
class _HomePage extends StatefulWidget {
  final String studentID;
  const _HomePage({required this.studentID});

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorColor: cs.primaryContainer,
            labelStyle: GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelColor: cs.onSurfaceVariant,
            labelColor: cs.primaryContainer,
            tabs: const [
              Tab(text: 'STATUS'),
              Tab(text: 'REQUESTS'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildStatusTab(context, cs),
                _buildRequestsTab(context, cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(BuildContext context, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroCard(studentID: widget.studentID),
          const SizedBox(height: 14),
          ValueListenableBuilder<int>(
            valueListenable: totalCreditsNotifier,
            builder: (context, credits, child) {
              return PetDashboardWidget(
                currentCredits: credits,
                studentID: widget.studentID,
              );
            },
          ),
          const SizedBox(height: 20),
          _TodayMissionsCard(studentID: widget.studentID),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(BuildContext context, ColorScheme cs) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final requests = List<Map<String, dynamic>>.from(
          data?['requests'] ?? [],
        );

        if (requests.isEmpty) {
          return Center(
            child: Text(
              'No new requests',
              style: GoogleFonts.outfit(color: cs.onSurfaceVariant),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final bool isParty = req['type'] == 'party';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isParty ? Icons.group_add : Icons.person_add,
                        color: cs.primaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isParty
                              ? 'Party Invite: ${req['partyName']}'
                              : (req['partyId'] != null
                                  ? 'Friend + Party Request'
                                  : 'Friend Request'),
                          style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'From: ${req['fromUid']}',
                    style: GoogleFonts.outfit(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _firestoreService.respondToRequest(
                          uid: widget.studentID,
                          request: req,
                          accept: false,
                        ),
                        child: Text(
                          'Decline',
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _firestoreService.respondToRequest(
                          uid: widget.studentID,
                          request: req,
                          accept: true,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primaryContainer,
                          foregroundColor: cs.onPrimaryContainer,
                        ),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ====== HERO CARD ======
class _HeroCard extends StatelessWidget {
  final String studentID;
  const _HeroCard({required this.studentID});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        // color: cs.surfaceContainerLow,
        // borderRadius: BorderRadius.circular(24),
        // border: Border.all(color: cs.outlineVariant, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WELCOME BACK',
                      style: GoogleFonts.orbitron(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: cs.outline,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      studentID,
                      style: GoogleFonts.orbitron(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Global rank badge
              StreamBuilder<int>(
                stream: FirestoreService().getUserRankStream(studentID),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Icon(Icons.error_outline, color: cs.error, size: 16);
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  final rank = snapshot.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceBright,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.primaryContainer.withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          rank > 0 ? '#$rank' : 'N/A',
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 8),
          // Container(height: 1, color: cs.outlineVariant.withOpacity(0.5)),
          // const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: cs.outline.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: cs.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'NTHU STUDENT',
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    color: cs.primaryContainer,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00CEC9),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'ACTIVE',
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  color: const Color(0xFF00CEC9),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ====== QUICK STATS ROW ======
class _QuickStatsRow extends StatelessWidget {
  final String studentID;
  const _QuickStatsRow({required this.studentID});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final todayKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(studentID)
          .collection('tasks')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final todayCount = docs
            .where((d) => d.data()['assignedDayString'] == todayKey)
            .length;
        final totalCount = docs.length;

        return Row(
          children: [
            _StatChip(
              cs: cs,
              label: 'TODAY',
              value: '$todayCount',
              unit: 'quests',
              color: cs.primaryContainer,
            ),
            const SizedBox(width: 10),
            _StatChip(
              cs: cs,
              label: 'PENDING',
              value: '$totalCount',
              unit: 'total',
              color: const Color(0xFF00CEC9),
            ),
            const SizedBox(width: 10),
            _StatChip(
              cs: cs,
              label: 'STREAK',
              value: '0',
              unit: 'days',
              color: const Color(0xFFFFD700),
            ),
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final ColorScheme cs;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatChip({
    required this.cs,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: 8,
                color: cs.outline,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== TODAY'S MISSIONS CARD ======
class _TodayMissionsCard extends StatelessWidget {
  final String studentID;
  const _TodayMissionsCard({required this.studentID});

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Class':
        return const Color(0xFFA594F9);
      case 'Homework':
        return const Color(0xFF9D4EDD);
      case 'Quiz':
        return const Color(0xFFC77DFF);
      case 'Lab':
        return const Color(0xFF00CEC9);
      case 'Midterm':
        return const Color(0xFFE0AAFF);
      case 'Final':
        return const Color(0xFF5A189A);
      case 'Project':
        return const Color(0xFF64DFDF);
      default:
        return const Color(0xFF7B2CBF);
    }
  }

  String get _todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 10),
          child: Text(
            "TODAY'S MISSIONS",
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cs.inversePrimary,
              letterSpacing: 1,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(studentID)
              .collection('tasks')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: cs.primaryContainer),
              );
            }

            // final docs = snapshot.data?.docs ?? [];
            final today = DateTime.now();
            final todayWeekday = today.weekday; // 1=Mon, 7=Sun

            final docs = (snapshot.data?.docs ?? []).where((doc) {
              final data = doc.data();
              final assignedDay = data['assignedDayString'] as String? ?? '';
              final repeatType = data['repeatType'] as String? ?? 'None';
              final repeatDays = List<int>.from(data['repeatDays'] ?? []);

              if (repeatType == 'None') {
                return assignedDay == _todayKey;
              } else if (assignedDay.compareTo(_todayKey) > 0) {
                return false; // hasn't started yet
              } else if (repeatType == 'Daily') {
                return true;
              } else if (repeatType == 'Weekly') {
                return repeatDays.contains(todayWeekday);
              }
              return false;
            }).toList();

            // Show all tasks (including done), filter empty separately
            // final pendingDocs = docs
            //     .where((d) => !(d.data()['isDone'] ?? false))
            //     .toList();
            // final doneDocs = docs
            //     .where((d) => d.data()['isDone'] ?? false)
            //     .toList();
            final pendingDocs = docs.where((d) {
              final data = d.data();
              final repeatType = data['repeatType'] as String? ?? 'None';
              if (repeatType == 'None') return !(data['isDone'] ?? false);
              final completedDates = List<String>.from(
                data['completedDates'] ?? [],
              );
              return !completedDates.contains(_todayKey);
            }).toList();

            final doneDocs = docs.where((d) {
              final data = d.data();
              final repeatType = data['repeatType'] as String? ?? 'None';
              if (repeatType == 'None') return data['isDone'] ?? false;
              final completedDates = List<String>.from(
                data['completedDates'] ?? [],
              );
              return completedDates.contains(_todayKey);
            }).toList();

            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    "No missions today. Enjoy your break!",
                    style: GoogleFonts.outfit(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Pending tasks first
                ...pendingDocs.map(
                  (doc) => _buildTaskCard(context, doc, cs, isDone: false),
                ),
                // Completed tasks below with muted style
                ...doneDocs.map(
                  (doc) => _buildTaskCard(context, doc, cs, isDone: true),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    ColorScheme cs, {
    required bool isDone,
  }) {
    final task = doc.data();
    final catColor = _getCategoryColor(task['category'] ?? 'Other');
    final expGained = task['exp'] ?? 10;
    final coinsGained = task['coins'] ?? 5;

    return Card(
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDone
              ? cs.outlineVariant.withOpacity(0.2)
              : cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 26,
          color: isDone ? catColor.withOpacity(0.3) : catColor,
        ),
        title: Text(
          task['title'] ?? '',
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: isDone ? cs.onSurface.withOpacity(0.4) : cs.onSurface,
            decoration: isDone ? TextDecoration.lineThrough : null,
            decorationColor: cs.onSurface.withOpacity(0.4),
          ),
        ),
        subtitle: Text(
          "${(task['course'] ?? '').toUpperCase()} • ${task['category'] ?? ''} (+$expGained EXP)",
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: isDone
                ? cs.onSurfaceVariant.withOpacity(0.4)
                : cs.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            isDone ? Icons.check_circle : Icons.radio_button_off,
            color: isDone ? Colors.greenAccent : cs.primaryContainer,
          ),
          // Matches task_list_page: disable button once done, no un-completing
          onPressed: () async {
            final data = doc.data();
            final repeatType = data['repeatType'] as String? ?? 'None';
            final ref = FirebaseFirestore.instance
                .collection('users')
                .doc(studentID)
                .collection('tasks')
                .doc(doc.id);

            if (isDone) {
              // Uncheck
              if (repeatType == 'None') {
                await ref.update({'isDone': false});
              } else {
                await ref.update({
                  'completedDates': FieldValue.arrayRemove([_todayKey]),
                });
              }
              return; // skip XP award on uncheck
            }

            // Check (mark done)
            if (repeatType == 'None') {
              await ref.update({'isDone': true});
            } else {
              await ref.update({
                'completedDates': FieldValue.arrayUnion([_todayKey]),
              });
            }

            // Award EXP + coins — guard against missing provider
            try {
              Provider.of<PetProvider>(
                context,
                listen: false,
              ).awardGrowthPoints(
                studentID: studentID,
                exp: expGained,
                coins: coinsGained,
              );
            } catch (_) {
              // Provider not in tree — write directly to Firestore instead
              final userRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(studentID);
              final snap = await userRef.get();
              final petMap = snap.data()?['pet'] as Map<String, dynamic>?;
              if (petMap != null) {
                final currentCoins = (petMap['coins'] ?? 0) as int;
                final currentGP = (petMap['growthPoints'] ?? 0) as int;
                await userRef.update({
                  'pet.coins': currentCoins + coinsGained,
                  'pet.growthPoints': currentGP + expGained,
                });
              }
            }
          },
        ),
      ),
    );
  }
}
