import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decorations.dart';
import '../../widgets/bengo_header.dart';
import 'create_room_screen.dart';
import 'team_lobby_screen.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _teams = [];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await ApiService.instance.getTeams();
      setState(() {
        _teams = teams;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to load team rooms.';
        _loading = false;
      });
    }
  }

  void _openCreateRoom() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateRoomScreen()));
    _loadTeams();
  }

  void _openLobby(int teamId) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TeamLobbyScreen(teamId: teamId)));
    _loadTeams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            const BenGoHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Team Arena',
                                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                              const SizedBox(height: 8),
                              Text('Create rooms, invite friends, and launch team battles.',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: _openCreateRoom,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                            child: Text('Create', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: AppDecorations.skeuomorphicCard(color: AppColors.bgCardDark, radius: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Team Access', style: GoogleFonts.sourceCodePro(fontSize: 11, letterSpacing: 2, color: AppColors.accentCyan)),
                            const SizedBox(height: 14),
                            Text('Build your team and begin the competitive challenge with friends.',
                                style: GoogleFonts.inter(fontSize: 15, color: AppColors.textLight, height: 1.45)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_loading) ...[
                      const SizedBox(height: 64),
                      const Center(child: CircularProgressIndicator()),
                    ] else if (_error != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_error!, style: GoogleFonts.inter(color: AppColors.primary)),
                      ),
                    ] else if (_teams.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _buildEmptyState(),
                          ],
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: _teams.map((team) {
                            final id = team['id'] as int;
                            final name = team['name'] as String? ?? 'Team';
                            final members = team['members'] as List<dynamic>? ?? [];
                            final started = team['started'] as bool? ?? false;
                            final finished = team['finished'] as bool? ?? false;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                onTap: () => _openLobby(id),
                                child: Container(
                                  width: double.infinity,
                                  decoration: AppDecorations.skeuomorphicCard(color: AppColors.bgCardDark, radius: 20),
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textWhite)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: started ? AppColors.accentGreen : AppColors.accentCyan,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              finished ? 'Finished' : (started ? 'In Progress' : 'Lobby'),
                                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textWhite, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text('${members.length} players joined', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight)),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: members.take(4).map((member) {
                                          final username = member['user'].toString();
                                          return Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(username, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textWhite)),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: AppDecorations.skeuomorphicCard(color: AppColors.bgCardDark, radius: 20),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No team rooms yet', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textWhite)),
          const SizedBox(height: 12),
          Text('Create a new battle room and invite classmates to compete.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight, height: 1.6)),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: _openCreateRoom, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: Text('Create your first room', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
