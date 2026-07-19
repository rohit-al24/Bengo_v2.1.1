import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'clan_theme.dart';

class RivalScreen extends StatefulWidget {
  const RivalScreen({super.key});

  @override
  State<RivalScreen> createState() => _RivalScreenState();
}

class _RivalScreenState extends State<RivalScreen>
    with TickerProviderStateMixin {
  late AnimationController _flameCtrl;
  late Animation<double> _flameAnim;

  final int _myWins = 3;
  final int _rivalWins = 5;
  final int _flameStage = 4; // 0-5
  final String _rivalName = 'Takeshi_JP';

  @override
  void initState() {
    super.initState();
    _flameCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _flameAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _flameCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Rival',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Rival card
            _buildRivalCard(),
            const SizedBox(height: 24),
            // Head-to-head record
            _buildHeadToHead(),
            const SizedBox(height: 24),
            // Unfinished business
            if (_rivalWins > _myWins) _buildUnfinishedBusiness(),
            const Spacer(),
            // Rematch button
            _buildRematchButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRivalCard() {
    return AnimatedBuilder(
      animation: _flameAnim,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF450A0A), Color(0xFF1A0505)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFEB4B6E).withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFFEB4B6E).withOpacity(0.2 * _flameAnim.value),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('YOUR RIVAL',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kClanAccent,
                          letterSpacing: 1.5)),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < _flameStage;
                      return Transform.scale(
                        scale: filled ? _flameAnim.value : 1.0,
                        child: Text(
                          filled ? '🔥' : '▫️',
                          style: TextStyle(fontSize: filled ? 16 : 12),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Rival avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      kClanAccent.withOpacity(0.3),
                      kClanAccent.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(color: kClanAccent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: kClanAccent.withOpacity(0.4 * _flameAnim.value),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _rivalName.substring(0, 1),
                    style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(_rivalName,
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text('🏆 743 trophies',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.4)),
                ),
                child: Text(
                  '🔥 Unfinished Business',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeadToHead() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text('Head-to-Head',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white54)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _H2HScore(
                  label: 'You', wins: _myWins, color: const Color(0xFFEB4B6E)),
              Text('vs',
                  style: GoogleFonts.inter(
                      fontSize: 18, color: Colors.white24)),
              _H2HScore(
                  label: _rivalName.split('_').first,
                  wins: _rivalWins,
                  color: const Color(0xFF3B82F6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnfinishedBusiness() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('😤', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You\'re behind $_rivalWins–$_myWins. Run it back and settle the score.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white70, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRematchButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: kClanAccent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Text('⚔️  Run It Back',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ),
    );
  }
}

class _H2HScore extends StatelessWidget {
  final String label;
  final int wins;
  final Color color;

  const _H2HScore(
      {required this.label, required this.wins, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$wins',
          style: GoogleFonts.inter(
              fontSize: 40, fontWeight: FontWeight.w900, color: color),
        ),
        Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
        Text('wins', style: GoogleFonts.inter(fontSize: 10, color: Colors.white24)),
      ],
    );
  }
}
