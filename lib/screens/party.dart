import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

// ─── Fixed semantic colors (not in ColorScheme) ───────────────────────────────
const Color _goldAccent = Color(0xFFFFD700);
const Color _silverAccent = Color(0xFFB0BEC5);
const Color _bronzeAccent = Color(0xFFFF8A65);

// ─── Data models ──────────────────────────────────────────────────────────────

class Party {
  String id, name, tag, creatorID, description;
  String inviteCode;
  List<String> memberIDs;
  int totalWeeklyXP;

  Party({
    required this.id,
    required this.name,
    required this.tag,
    required this.creatorID,
    required this.memberIDs,
    required this.inviteCode,
    this.totalWeeklyXP = 0,
    this.description = '',
  });

  factory Party.fromJson(Map<String, dynamic> j) => Party(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    tag: j['tag'] ?? '',
    creatorID: j['creatorID'] ?? '',
    memberIDs: List<String>.from(j['memberIDs'] ?? []),
    inviteCode: j['inviteCode'] ?? '',
    totalWeeklyXP: j['totalWeeklyXP'] ?? 0,
    description: j['description'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tag': tag,
    'creatorID': creatorID,
    'memberIDs': memberIDs,
    'totalWeeklyXP': totalWeeklyXP,
    'description': description,
    'inviteCode': inviteCode,
  };
}

class LeaderboardEntry {
  final String studentID, displayName;
  final int weeklyXP, rank;
  const LeaderboardEntry({
    required this.studentID,
    required this.displayName,
    required this.weeklyXP,
    required this.rank,
  });
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class PartyPage extends StatefulWidget {
  final String studentID;
  const PartyPage({super.key, required this.studentID});

  @override
  State<PartyPage> createState() => _PartyPageState();
}

class _PartyPageState extends State<PartyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Party? _myParty;
  bool _isLoading = true;

  final FirestoreService _firestoreService = FirestoreService();
  /*
  final List<LeaderboardEntry> _globalLeaderboard = [
    LeaderboardEntry(
      studentID: 'S001',
      displayName: 'NebulaKnight',
      weeklyXP: 1840,
      rank: 1,
    ),
    LeaderboardEntry(
      studentID: 'S002',
      displayName: 'VoidWalker',
      weeklyXP: 1725,
      rank: 2,
    ),
    LeaderboardEntry(
      studentID: 'S003',
      displayName: 'ArcSorceress',
      weeklyXP: 1580,
      rank: 3,
    ),
    LeaderboardEntry(
      studentID: 'S004',
      displayName: 'CipherMage',
      weeklyXP: 1440,
      rank: 4,
    ),
    LeaderboardEntry(
      studentID: 'S005',
      displayName: 'DataWraith',
      weeklyXP: 1310,
      rank: 5,
    ),
    LeaderboardEntry(
      studentID: 'S006',
      displayName: 'PhotonRogue',
      weeklyXP: 1190,
      rank: 6,
    ),
    LeaderboardEntry(
      studentID: 'S007',
      displayName: 'LunarScribe',
      weeklyXP: 1050,
      rank: 7,
    ),
    LeaderboardEntry(
      studentID: 'S008',
      displayName: 'ByteShaman',
      weeklyXP: 920,
      rank: 8,
    ),
    LeaderboardEntry(
      studentID: 'S009',
      displayName: 'StarForger',
      weeklyXP: 810,
      rank: 9,
    ),
    LeaderboardEntry(
      studentID: 'S010',
      displayName: 'QuantumBard',
      weeklyXP: 700,
      rank: 10,
    ),
  ];

  final List<LeaderboardEntry> _partyLeaderboard = [
    LeaderboardEntry(
      studentID: 'P001',
      displayName: 'Stellar Vanguard',
      weeklyXP: 6840,
      rank: 1,
    ),
    LeaderboardEntry(
      studentID: 'P002',
      displayName: 'Code Wraiths',
      weeklyXP: 6120,
      rank: 2,
    ),
    LeaderboardEntry(
      studentID: 'P003',
      displayName: 'Arc Collective',
      weeklyXP: 5775,
      rank: 3,
    ),
    LeaderboardEntry(
      studentID: 'P004',
      displayName: 'Null Terminators',
      weeklyXP: 4990,
      rank: 4,
    ),
    LeaderboardEntry(
      studentID: 'P005',
      displayName: 'Byte Syndicate',
      weeklyXP: 4310,
      rank: 5,
    ),
  ];
  */
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadParty();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Storage ────────────────────────────────────────────────────────────────
  // aku rubah jadi firestore
  Future<void> _loadParty() async {
    final partyData = await _firestoreService.getUserParty(
      widget.studentID,
    );

    print("========== PARTY DATA ==========");
    print(partyData);
    print("================================");

    setState(() {
      _myParty =
          partyData != null ? Party.fromJson(partyData) : null;
      _isLoading = false;
    });
  }

  // aku jadiin firestore
  Future<void> _saveParty(Party party) async {
    print("SAVE PARTY CALLED");

    await _firestoreService.createParty(
      partyId: party.id,
      name: party.name,
      tag: party.tag,
      creatorID: party.creatorID,
      description: party.description,
    );

    // reload party dari firestore
    await _loadParty();
  }
  // aku ganti ke firestore.
  Future<void> _leaveParty() async {
    await _firestoreService.leaveParty(
      studentID: widget.studentID,
    );

    setState(() {
      _myParty = null;
    });
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showCreatePartyDialog() {
    final cs = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController();
    final tagCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerLow, // #16121E cardDark
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.surfaceBright, width: 1.5), // #3C096C
        ),
        title: Text(
          'FORGE PARTY',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            color: cs.inversePrimary, // #E0AAFF paleLavender
            fontSize: 16,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(cs, nameCtrl, 'Party Name', 'e.g. Stellar Vanguard'),
              const SizedBox(height: 12),
              _dialogField(
                cs,
                tagCtrl,
                'Tag (4 chars)',
                'e.g. NTHU',
                maxLength: 4,
              ),
              const SizedBox(height: 12),
              _dialogField(
                cs,
                descCtrl,
                'Description (optional)',
                'What is your party about?',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final tag = tagCtrl.text.trim().toUpperCase();
              if (name.isEmpty || tag.isEmpty) return;
              final party = Party(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                tag: tag.length > 4 ? tag.substring(0, 4) : tag,
                creatorID: widget.studentID,
                memberIDs: [widget.studentID],
                description: descCtrl.text.trim(),
                inviteCode: '', // will be generated in Firestore service
              );
              _saveParty(party);
              Navigator.pop(ctx);
            },
            child: Text(
              'Forge',
              style: GoogleFonts.orbitron(
                color: cs.primaryContainer, // #C77DFF neonPurple
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinPartyDialog() {
    final cs = Theme.of(context).colorScheme;
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.surfaceBright, width: 1.5),
        ),
        title: Text(
          'JOIN PARTY',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            color: cs.inversePrimary,
            fontSize: 16,
          ),
        ),
        content: _dialogField(
          cs,
          codeCtrl,
          'Party Code',
          'Enter the invite code',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              final code = codeCtrl.text.trim().toUpperCase();

              if (code.isEmpty) return;

              final success = await _firestoreService.joinParty(
                inviteCode: code,
                studentID: widget.studentID,
              );

              Navigator.pop(ctx);

              if (success) {
                await _loadParty();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Joined party successfully!'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid code or party is full.'),
                  ),
                );
              }
            },
            child: Text(
              'Join',
              style: GoogleFonts.orbitron(
                color: cs.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.surfaceBright, width: 1.5),
        ),
        title: Text(
          'LEAVE PARTY?',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            color: cs.error,
            fontSize: 15,
          ),
        ),
        content: Text(
          'Your weekly XP contribution will be removed from the leaderboard.',
          style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Stay', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              _leaveParty();
              Navigator.pop(ctx);
            },
            child: Text(
              'Leave',
              style: GoogleFonts.orbitron(
                color: cs.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPartyDialog(
    ColorScheme cs,
    Party party,
  ) {
    final nameController =
        TextEditingController(text: party.name);

    final descController =
        TextEditingController(text: party.description);

    final tagController =
        TextEditingController(text: party.tag);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cs.surfaceContainerLow,
          title: Text(
            "Edit Party",
            style: GoogleFonts.orbitron(
              color: cs.primaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Party Name",
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: tagController,
                maxLength: 5,
                textCapitalization:
                    TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "Party Tag",
                  counterText: "",
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: "Description",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (tagController.text.trim().isEmpty) {
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('parties')
                    .doc(party.id)
                    .update({
                  'name': nameController.text.trim(),
                  'tag': tagController.text
                      .trim()
                      .toUpperCase(),
                  'description':
                      descController.text.trim(),
                });

                if (mounted) {
                  Navigator.pop(context);
                }

                setState(() {});
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _dialogField(
    ColorScheme cs,
    TextEditingController ctrl,
    String label,
    String hint, {
    int? maxLength,
  }) {
    return TextField(
      controller: ctrl,
      maxLength: maxLength,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.primaryContainer), // #C77DFF
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.24)),
        counterStyle: TextStyle(color: cs.onSurfaceVariant),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: cs.surfaceBright), // #3C096C
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: cs.primaryContainer, width: 2),
        ),
      ),
    );
  }

  Color _rankColor(int rank) {
    if (rank == 1) return _goldAccent;
    if (rank == 2) return _silverAccent;
    if (rank == 3) return _bronzeAccent;
    return const Color(0xFF9E9299); // onSurfaceVariant
  }

  String _rankEmoji(int rank) {
    if (rank == 1) return '👑';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: cs.surface, // #0B090A
        body: Center(
          child: CircularProgressIndicator(color: cs.primaryContainer),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(
          'PARTY NEXUS',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cs.primaryContainer, // #C77DFF
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.orbitron(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelColor: cs.onSurfaceVariant,
          labelColor: cs.primaryContainer,
          tabs: const [
            Tab(text: 'MY PARTY'),
            Tab(text: 'SOLO RANK'),
            Tab(text: 'PARTY RANK'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyPartyTab(cs),
          _buildSoloLeaderboard(cs),
          _buildPartyLeaderboard(cs),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) {
          if (_tabController.index != 0 || _myParty != null)
            return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: cs.outline, // #7B2CBF
            label: Text(
              'FORGE PARTY',
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.bold,
                color: cs.onPrimary,
                fontSize: 12,
              ),
            ),
            icon: Icon(Icons.group_add, color: cs.onPrimary),
            onPressed: _showCreatePartyDialog,
          );
        },
      ),
    );
  }

  // ── Tab: My Party ──────────────────────────────────────────────────────────

  Widget _buildMyPartyTab(ColorScheme cs) {
    return _myParty == null
        ? _buildNoPartyScreen(cs)
        : _buildPartyDetailScreen(cs, _myParty!);
  }

  Widget _buildNoPartyScreen(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow, // #16121E
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: cs.outlineVariant,
                width: 1.5,
              ), // #240046
            ),
            child: Column(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: cs.outline,
                  size: 56,
                ), // #7B2CBF
                const SizedBox(height: 16),
                Text(
                  'NO PARTY ASSIGNED',
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.inversePrimary,
                    letterSpacing: 1.2, // #E0AAFF
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join a party to combine XP with allies and climb the weekly leaderboard together.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _actionButton(
            cs,
            icon: Icons.add_circle_outline,
            label: 'FORGE NEW PARTY',
            subtitle: 'Create and lead your own guild',
            onTap: _showCreatePartyDialog,
          ),
          const SizedBox(height: 12),
          _actionButton(
            cs,
            icon: Icons.login_rounded,
            label: 'JOIN WITH CODE',
            subtitle: 'Enter an invite code to join a party',
            onTap: _showJoinPartyDialog,
          ),
          const SizedBox(height: 28),
          _sectionLabel(cs, 'HOW PARTY XP WORKS'),
          const SizedBox(height: 12),
          _infoCard(
            cs,
            Icons.star_rounded,
            'Combined Weekly XP',
            'Every quest you complete contributes XP to your party\'s weekly total.',
          ),
          const SizedBox(height: 10),
          _infoCard(
            cs,
            Icons.leaderboard_rounded,
            'Weekly Reset',
            'Leaderboards reset every Monday at 00:00. Top parties earn bonus rewards.',
          ),
          const SizedBox(height: 10),
          _infoCard(
            cs,
            Icons.group_rounded,
            'Max 6 Members',
            'Parties are capped at 6 members for balanced competition.',
          ),
        ],
      ),
    );
  }

  Widget _buildPartyDetailScreen(ColorScheme cs, Party party) {
    final bool isLeader = party.creatorID == widget.studentID;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where(
            FieldPath.documentId,
            whereIn: party.memberIDs,
          )
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final members = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          return {
            'id': doc.id,
            'name': doc.id,
            'weeklyXP': data['weeklyXP'] ?? 0,
            'isLeader': doc.id == party.creatorID,
          };
        }).toList();

        members.sort(
          (a, b) => (b['weeklyXP'] as int)
              .compareTo(a['weeklyXP'] as int),
        );

        /*final int totalXP = members.fold(
          0,
          (sum, m) => sum + (m['weeklyXP'] as int),
        );*/

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: cs.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceBright,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cs.outline,
                            ),
                          ),
                          child: Text(
                            '[${party.tag}]',
                            style: GoogleFonts.orbitron(
                              color: cs.primaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            party.name,
                            style: GoogleFonts.orbitron(
                              color: cs.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLeader)
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: cs.onSurfaceVariant,
                              size: 18,
                            ),
                            onPressed: () {
                              _showEditPartyDialog(cs, party);
                            },
                          ),
                      ],
                    ),

                    if (party.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        party.description,
                        style: GoogleFonts.outfit(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _statChip(
                          cs,
                          Icons.bolt,
                          '${party.totalWeeklyXP} XP',
                          'This Week',
                        ),
                        const SizedBox(width: 12),
                        _statChip(
                          cs,
                          Icons.group,
                          '${party.memberIDs.length}/6',
                          'Members',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _sectionLabel(
                cs,
                'PARTY MEMBERS • THIS WEEK',
              ),

              const SizedBox(height: 12),

              ...members.asMap().entries.map((e) {
                final m = e.value;

                return _memberCard(
                  cs,
                  rank: e.key + 1,
                  name: m['name'],
                  xp: m['weeklyXP'],
                  isLeader: m['isLeader'],
                  isMe: m['id'] == widget.studentID,
                );
              }),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.outline),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        Icons.share_outlined,
                        color: cs.primaryContainer,
                        size: 18,
                      ),
                      label: Text(
                        'INVITE',
                        style: GoogleFonts.orbitron(
                          color: cs.primaryContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text: party.inviteCode,
                          ),
                        );

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: cs.surfaceContainerHigh,
                            content: Text(
                              'Invite Code ${party.inviteCode} copied!',
                              style: GoogleFonts.outfit(
                                color: cs.primaryContainer,
                              ),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.error),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        Icons.logout_rounded,
                        color: cs.error,
                        size: 18,
                      ),
                      label: Text(
                        'LEAVE',
                        style: GoogleFonts.orbitron(
                          color: cs.error,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _showLeaveConfirmDialog,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  // ── Tab: Leaderboard ───────────────────────────────────────────────────────
  Widget _buildSoloLeaderboard(ColorScheme cs) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('weeklyXP', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: cs.primaryContainer,
            ),
          );
        }

        final docs = snapshot.data!.docs;

        final entries = docs.asMap().entries.map((entry) {
          final data = entry.value.data() as Map<String, dynamic>;

          return LeaderboardEntry(
            studentID: entry.value.id,
            displayName: entry.value.id,
            weeklyXP: data['weeklyXP'] ?? 0,
            rank: entry.key + 1,
          );
        }).toList();

        return _buildLeaderboardTab(
          cs,
          entries,
          isSolo: true,
        );
      },
    );
  }
  
  Widget _buildPartyLeaderboard(ColorScheme cs) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parties')
          .orderBy('totalWeeklyXP', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: cs.primaryContainer,
            ),
          );
        }

        final docs = snapshot.data!.docs;

        final entries = docs.asMap().entries.map((entry) {
          final data = entry.value.data() as Map<String, dynamic>;

          return LeaderboardEntry(
            studentID: entry.value.id,
            displayName: data['name'] ?? 'Unknown Party',
            weeklyXP: data['totalWeeklyXP'] ?? 0,
            rank: entry.key + 1,
          );
        }).toList();

        return _buildLeaderboardTab(
          cs,
          entries,
          isSolo: false,
        );
      },
    );
  }

  Widget _buildLeaderboardTab(
    ColorScheme cs,
    List<LeaderboardEntry> entries, {
    required bool isSolo,
  }) {
    final myEntry = entries
        .where(
          (e) =>
              e.studentID == widget.studentID ||
              (!isSolo && _myParty != null && e.studentID == _myParty!.id),
        )
        .firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: _goldAccent,
                  size: 36,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSolo ? 'SOLO WEEKLY RANK' : 'PARTY WEEKLY RANK',
                      style: GoogleFonts.orbitron(
                        color: cs.inversePrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Resets every Monday at 00:00',
                      style: GoogleFonts.outfit(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (entries.length >= 3) _buildPodium(cs, entries),
          const SizedBox(height: 20),
          _sectionLabel(cs, 'FULL RANKINGS'),
          const SizedBox(height: 12),
          ...entries.map((e) {
            final bool isMe =
                e.studentID == widget.studentID ||
                (!isSolo && _myParty?.id == e.studentID);
            return _leaderboardRow(cs, e, isMe: isMe);
          }),
          if (myEntry == null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: cs.surfaceContainer, // #1E1A24 cardMid
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outline.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: cs.outline, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    isSolo
                        ? 'Complete quests to appear on the board!'
                        : 'Join a party to compete!',
                    style: GoogleFonts.outfit(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPodium(ColorScheme cs, List<LeaderboardEntry> entries) {
    final top3 = entries.take(3).toList();
    final display = [top3[1], top3[0], top3[2]];
    final heights = [90.0, 120.0, 70.0];
    final colors = [_silverAccent, _goldAccent, _bronzeAccent];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final entry = display[i];
          final color = colors[i];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                i == 1 ? '👑' : (i == 0 ? '🥈' : '🥉'),
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                entry.displayName,
                style: GoogleFonts.outfit(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.weeklyXP} XP',
                style: GoogleFonts.orbitron(color: color, fontSize: 10),
              ),
              const SizedBox(height: 6),
              Container(
                width: 80,
                height: heights[i],
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    '${entry.rank}',
                    style: GoogleFonts.orbitron(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _leaderboardRow(
    ColorScheme cs,
    LeaderboardEntry e, {
    required bool isMe,
  }) {
    final Color rankCol = _rankColor(e.rank);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? cs.surfaceBright.withOpacity(0.35)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? cs.outline : cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              _rankEmoji(e.rank),
              style: TextStyle(
                fontSize: e.rank <= 3 ? 18 : 13,
                color: rankCol,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              e.displayName + (isMe ? ' (You)' : ''),
              style: GoogleFonts.outfit(
                color: isMe ? cs.primaryContainer : cs.onSurface,
                fontWeight: isMe ? FontWeight.bold : FontWeight.w400,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${e.weeklyXP} XP',
            style: GoogleFonts.orbitron(color: rankCol, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _sectionLabel(ColorScheme cs, String text) => Text(
    text,
    style: GoogleFonts.orbitron(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      // inversePrimary = #9D4EDD section label purple
      color: cs.inversePrimary,
      letterSpacing: 1,
    ),
  );

  Widget _actionButton(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceBright, // #3C096C icon bg
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.primaryContainer, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.orbitron(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(ColorScheme cs, IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.outline, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: cs.inversePrimary, // #E0AAFF paleLavender
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.outfit(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(ColorScheme cs, IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainer, // #1E1A24 cardMid
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cs.outline, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.orbitron(
                  color: cs.primaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _memberCard(
    ColorScheme cs, {
    required int rank,
    required String name,
    required int xp,
    required bool isLeader,
    required bool isMe,
  }) {
    return Card(
      color: isMe ? cs.surfaceBright.withOpacity(0.3) : cs.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isMe ? cs.outline : cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        leading: Container(width: 4, height: 26, color: _rankColor(rank)),
        title: Row(
          children: [
            if (isLeader)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text('👑', style: TextStyle(fontSize: 13)),
              ),
            Expanded(
              child: Text(
                name + (isMe ? ' (You)' : ''),
                style: GoogleFonts.outfit(
                  color: isMe ? cs.primaryContainer : cs.onSurface,
                  fontSize: 14,
                  fontWeight: isMe ? FontWeight.bold : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '$xp XP this week',
          style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 11),
        ),
        trailing: Text(
          '#$rank',
          style: GoogleFonts.orbitron(
            color: _rankColor(rank),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
