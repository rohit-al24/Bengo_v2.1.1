import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decorations.dart';

class TeamResultScreen extends StatelessWidget {
  const TeamResultScreen({super.key, required this.teamId, required this.score, required this.streak, required this.events});
  final int teamId;
  final int score;
  final int streak;
  final List<String> events;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Result', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Team ${teamId.toString()}', style: GoogleFonts.inter(color: AppColors.textLight)),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.bgCardDark, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF2F3A57))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Final Score', style: GoogleFonts.sourceCodePro(color: AppColors.accentCyan, letterSpacing: 2, fontSize: 11)),
                    const SizedBox(height: 16),
                    Text('$score', style: GoogleFonts.inter(fontSize: 72, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _statCard('Best streak', '$streak'),
                        const SizedBox(width: 12),
                        _statCard('Knives used', '${events.where((e) => e.contains('Knife')).length}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Battle highlights', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (_, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF101726), borderRadius: BorderRadius.circular(18)),
                      child: Text(events[index], style: GoogleFonts.inter(color: AppColors.textLight)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text('Return to Teams', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF121826), borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12)),
            const SizedBox(height: 10),
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
