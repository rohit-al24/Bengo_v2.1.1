import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_nav.dart';

class TopicWiseStudyScreen extends StatefulWidget {
  final int lessonId;
  final int? rankId;
  final String category;
  final String level;
  final String lessonName;

  const TopicWiseStudyScreen({
    super.key,
    required this.lessonId,
    this.rankId,
    required this.category,
    required this.level,
    required this.lessonName,
  });

  @override
  State<TopicWiseStudyScreen> createState() => _TopicWiseStudyScreenState();
}

class _TopicWiseStudyScreenState extends State<TopicWiseStudyScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  int _current  = 0;

  late AnimationController _anim;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  bool _goingForward = true;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _loadItems();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.getLessonStudy(widget.lessonId);
      final items = data['study_items'] as List? ?? [];
      setState(() => _items = items.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList());
    } catch (_) {
      // Keep empty
    } finally {
      setState(() => _loading = false);
      _anim.forward(from: 0);
    }
  }

  void _go(int delta) {
    final next = _current + delta;
    if (next < 0 || next >= _items.length) return;
    _goingForward = delta > 0;
    _anim.reverse().then((_) {
      setState(() => _current = next);
      _slide = Tween<Offset>(
        begin: Offset(_goingForward ? 0.3 : -0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
      _anim.forward(from: 0);
    });
  }

  Future<void> _markStudyComplete() async {
    try {
      await ApiService.instance.studyComplete(
        lessonId: widget.lessonId,
        rankId: widget.rankId,
      );
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.star_rounded, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('Study complete! XP earned.'),
          ]),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true); // true = completed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      bottomNavigationBar: BenGoBottomNav(
        currentIndex: 1,
        onTap: (i) { if (i != 1) Navigator.pop(context); },
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _items.isEmpty
                ? _buildEmpty()
                : _buildContent(),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.inbox_outlined, size: 56, color: AppColors.textMuted),
      const SizedBox(height: 12),
      Text('No study content yet', style: AppTextStyles.bodySmall),
    ]),
  );

  Widget _buildContent() {
    final item     = _items[_current];
    final target   = item['target']?.toString() ?? '';
    final exps     = [
      item['exp1']?.toString() ?? '',
      item['exp2']?.toString() ?? '',
      item['exp3']?.toString() ?? '',
      item['exp4']?.toString() ?? '',
      item['exp5']?.toString() ?? '',
    ].where((e) => e.isNotEmpty).toList();
    final isLast   = _current == _items.length - 1;
    final isFirst  = _current == 0;

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────
        _buildHeader(),

        // ── Progress ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_current + 1} of ${_items.length}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                  Text('${((_current + 1) / _items.length * 100).round()}%',
                      style: GoogleFonts.inter(fontSize: 12,
                          fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_current + 1) / _items.length,
                  backgroundColor: AppColors.borderLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),

        // ── Card ─────────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.bgWhite,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        // Target word
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(target,
                              style: GoogleFonts.notoSerif(fontSize: 44,
                                  fontWeight: FontWeight.w800, color: AppColors.primary),
                              textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 24),

                        // Explanations list
                        if (exps.isEmpty)
                          Text('No explanations added yet.',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                              textAlign: TextAlign.center)
                        else
                          ...exps.asMap().entries.map((e) => _expRow(e.key + 1, e.value)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Navigation buttons ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Previous
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isFirst ? null : () => _go(-1),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    disabledForegroundColor: AppColors.textMuted.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Next or Finish
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isLast ? _markStudyComplete : () => _go(1),
                  icon: Icon(isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, size: 18),
                  label: Text(isLast ? 'Complete Study' : 'Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast ? AppColors.accentGreen : AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _expRow(int n, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: n == 1 ? AppColors.primary.withOpacity(0.04) : AppColors.bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: n == 1 ? AppColors.primary.withOpacity(0.2) : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$n',
                  style: GoogleFonts.inter(fontSize: 10,
                      fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(fontSize: 14, height: 1.5,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    ),
  );

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgWhite, borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.lessonName,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${widget.category} · ${widget.level}',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ),
        Text('BenGo', style: AppTextStyles.brandNameSmall),
      ],
    ),
  );
}
