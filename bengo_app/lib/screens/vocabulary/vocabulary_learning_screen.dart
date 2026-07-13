import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/bengo_header.dart';
import '../../utils/app_decorations.dart';

class VocabularyLearningScreen extends StatefulWidget {
  final int lessonNumber;
  final String category;
  final String level;
  final int? lessonId;
  final int? rankId;
  final String rankName;

  const VocabularyLearningScreen({
    super.key,
    this.lessonNumber = 1,
    this.category = 'Vocabulary',
    this.level = 'N5',
    this.lessonId,
    this.rankId,
    this.rankName = '',
  });

  @override
  State<VocabularyLearningScreen> createState() => _VocabularyLearningScreenState();
}

class _VocabularyLearningScreenState extends State<VocabularyLearningScreen> {
  List<Map<String, dynamic>> _vocab = [];
  Map<int, List<Map<String, dynamic>>> _hintsByItem = {};
  Map<String, dynamic> _me = {};
  bool _loading = true;
  String _error = '';
  bool _studyCompleted = false;

  // track which rows currently show the red-X (hint open)
  final Set<int> _hintOpen = {};

  @override
  void initState() {
    super.initState();
    _loadStudyItems();
  }

  String _getCompletionKey() {
    final userId = _me['id'] ?? 'guest';
    final rId = widget.rankId ?? 'norank';
    final lId = widget.lessonId ?? widget.lessonNumber;
    return 'study_completed_${userId}_${rId}_${lId}';
  }

  Future<void> _loadStudyItems() async {
    if (widget.lessonId == null) { _setFallback(); return; }
    setState(() { _loading = true; _error = ''; });
    try {
      // Fetch user profile
      try {
        final me = await ApiService.instance.getMe();
        _me = me;
      } catch (_) {}

      // Load SharedPreferences to check completion status
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = _getCompletionKey();
        setState(() {
          _studyCompleted = prefs.getBool(key) ?? false;
        });
      } catch (_) {}

      final data = await ApiService.instance.getLessonStudy(widget.lessonId!);
      final items = data['items'] as List? ?? data['study_items'] as List? ?? [];
      if (items.isEmpty) { _setFallback(); return; }

      // Fetch real vocab hints
      Map<int, List<Map<String, dynamic>>> grouped = {};
      try {
        final hintsList = await ApiService.instance.getVocabHints();
        for (final h in hintsList) {
          if (h is Map<String, dynamic>) {
            final itemId = h['study_item_id'] as int?;
            if (itemId != null) {
              grouped.putIfAbsent(itemId, () => []).add(h);
            }
          }
        }
      } catch (_) {}

      setState(() {
        _vocab = items.map<Map<String, dynamic>>((e) => {
          'id':             e['id'] as int?,
          'target':         e['target']?.toString() ?? '',
          'correct_answer': e['correct_answer']?.toString() ?? '',
          'wrong_1':        e['wrong_1']?.toString() ?? '',
          'wrong_2':        e['wrong_2']?.toString() ?? '',
          'wrong_3':        e['wrong_3']?.toString() ?? '',
        }).toList();
        _hintsByItem = grouped;
      });
    } catch (_) {
      setState(() => _error = 'Offline — showing sample data.');
      _setFallback();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markStudyComplete() async {
    if (widget.lessonId == null) return;
    try {
      await ApiService.instance.studyComplete(
        lessonId: widget.lessonId!,
        rankId: widget.rankId,
      );
      // Save completion state
      final prefs = await SharedPreferences.getInstance();
      final key = _getCompletionKey();
      await prefs.setBool(key, true);
      if (mounted) {
        setState(() {
          _studyCompleted = true;
        });
      }
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

  void _setFallback() {
    _vocab = [
      {'target': 'こんにちは', 'correct_answer': 'Hello',    'wrong_1': 'Goodbye',  'wrong_2': 'Thanks',  'wrong_3': 'Sorry'},
      {'target': 'ありがとう', 'correct_answer': 'Thank you','wrong_1': 'Hello',    'wrong_2': 'Sorry',   'wrong_3': 'Please'},
      {'target': 'さようなら', 'correct_answer': 'Goodbye',  'wrong_1': 'Hello',    'wrong_2': 'Thanks',  'wrong_3': 'Excuse me'},
    ];
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _getHints(int index) {
    if (index < 0 || index >= _vocab.length) return [];
    final item = _vocab[index];
    final itemId = item['id'] as int?;
    if (itemId == null) return [];
    final list = _hintsByItem[itemId] ?? [];
    return list.map<Map<String, dynamic>>((h) {
      final user = h['user'] as Map<String, dynamic>? ?? {};
      final username = user['username']?.toString() ?? 'Friend';
      
      // Hash username to color
      final hash = username.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
      final colors = [
        0xFF4CAF50, // Green
        0xFF2196F3, // Blue
        0xFFE91E63, // Pink
        0xFFFF9800, // Orange
        0xFF9C27B0, // Purple
        0xFF009688, // Teal
        0xFF3F51B5, // Indigo
        0xFF00BCD4, // Cyan
        0xFFFFC107, // Amber
      ];
      final colorVal = colors[hash % colors.length];

      return {
        'name': username,
        'color': colorVal,
        'hint': h['hint_text']?.toString() ?? '',
        'id': h['id'],
      };
    }).toList();
  }

  Future<void> _refreshHints() async {
    Map<int, List<Map<String, dynamic>>> grouped = {};
    try {
      final hintsList = await ApiService.instance.getVocabHints();
      for (final h in hintsList) {
        if (h is Map<String, dynamic>) {
          final itemId = h['study_item_id'] as int?;
          if (itemId != null) {
            grouped.putIfAbsent(itemId, () => []).add(h);
          }
        }
      }
      if (mounted) {
        setState(() {
          _hintsByItem = grouped;
        });
      }
    } catch (_) {}
  }

  // ── Open hint as bottom sheet ─────────────────────────────────────────────────
  void _openHintSheet(BuildContext context, int index, Map<String, dynamic> vocab) {
    setState(() => _hintOpen.add(index));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => _HintBottomSheet(
        vocab: vocab,
        hints: _getHints(index),
        lessonId: widget.lessonId,
        onHintAdded: () {
          _refreshHints();
        },
      ),
    ).then((_) {
      if (mounted) setState(() => _hintOpen.remove(index));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      bottomNavigationBar: BenGoBottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i != 1) Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pinned Header
            const BenGoHeader(isSubPage: true),
            // Pinned Title
            _buildHeader(),
            if (_error.isNotEmpty)
              _buildErrorBanner(),
            
            // Scrollable Vocab Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _vocab.isEmpty
                      ? _buildEmpty()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              _buildVocabTable(context),
                              const SizedBox(height: 100), // padding to prevent occlusion by pinned bottom button
                            ],
                          ),
                        ),
            ),

            // Pinned Bottom Action Button (shows only if study NOT yet completed for this lesson+rank)
            if (!_loading && _vocab.isNotEmpty && !_studyCompleted)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _markStudyComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Claim Learning XP',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Vocabulary table ─────────────────────────────────────────────────────────
  Widget _buildVocabTable(BuildContext context) {
    return Container(
      decoration: AppDecorations.skeuomorphicCard(radius: 20),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Expanded(flex: 5, child: Text('JAPANESE', style: AppTextStyles.captionUpper)),
                Expanded(flex: 6, child: Text('ENGLISH', style: AppTextStyles.captionUpper)),
                Text('STUDY', style: AppTextStyles.captionUpper),
              ],
            ),
          ),
          Divider(color: AppColors.borderLight, height: 1.2),
          ..._vocab.asMap().entries.map((e) => _buildRow(context, e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index, Map<String, dynamic> vocab) {
    final hints         = _getHints(index);
    final visibleAvatars = hints.take(3).toList();
    final overflow      = hints.length > 3 ? hints.length - 3 : 0;
    final isOpen        = _hintOpen.contains(index);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // TARGET
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(vocab['target'] ?? '',
                          style: GoogleFonts.notoSerif(fontSize: 15, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.volume_up_rounded, size: 13, color: AppColors.primary),
                  ],
                ),
              ),

              // MEANING — full, no truncation
              Expanded(
                flex: 6,
                child: Text(vocab['correct_answer'] ?? '',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
              ),

              // STUDY: avatar stack + hint button (no fixed width, just Row min)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar stack
                  if (visibleAvatars.isNotEmpty)
                    SizedBox(
                      width: visibleAvatars.length * 13.0 + 4,
                      height: 20,
                      child: Stack(
                        children: visibleAvatars.asMap().entries.map((e) =>
                          Positioned(
                            left: e.key * 13.0,
                            child: Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(e.value['color'] as int),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Center(
                                child: Text((e.value['name'] as String)[0],
                                    style: GoogleFonts.inter(fontSize: 8,
                                        fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                    ),

                  // +n badge
                  if (overflow > 0) ...[
                    const SizedBox(width: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('+$overflow',
                          style: GoogleFonts.inter(fontSize: 8, color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],

                  const SizedBox(width: 6),

                  // Hint lightbulb / red-X toggle
                  GestureDetector(
                    onTap: () => _openHintSheet(context, index, vocab),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28, height: 28,
                      decoration: AppDecorations.skeuomorphicCard(
                        radius: 14,
                        color: isOpen ? const Color(0xFFFFEBEE) : Colors.white,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isOpen ? Icons.close_rounded : Icons.lightbulb_outline,
                          key: ValueKey(isOpen),
                          size: 15,
                          color: isOpen ? Colors.red.shade500 : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (index < _vocab.length - 1)
          Divider(color: AppColors.borderLight, height: 1, indent: 14, endIndent: 14),
      ],
    );
  }

  Widget _buildHeader() {
    final rName = widget.rankName.isNotEmpty ? '${widget.rankName.toUpperCase()} • ' : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: AppDecorations.skeuomorphicCard(radius: 20),
            child: Text('$rName${widget.level} • ${widget.category.toUpperCase()} • LESSON ${widget.lessonNumber}',
                style: AppTextStyles.captionUpper),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(children: [
              TextSpan(text: 'Learning ', style: GoogleFonts.inter(fontSize: 28,
                  fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              TextSpan(text: 'Mode', style: GoogleFonts.inter(fontSize: 28,
                  fontWeight: FontWeight.w800, color: AppColors.primary)),
            ]),
          ),
          const SizedBox(height: 4),
          Center(child: Container(width: 32, height: 3,
              decoration: BoxDecoration(color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2)))),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(_error, style: AppTextStyles.bodySmall)),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(children: [
          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No study items yet.', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 4),
          Text('Import content via the Admin UI.', style: AppTextStyles.bodySmall),
        ]),
      ),
    );
  }
}

// ─── Hint Bottom Sheet (75% height, blur bg, slides from bottom) ─────────────

class _HintBottomSheet extends StatefulWidget {
  final Map<String, dynamic> vocab;
  final List<Map<String, dynamic>> hints;
  final int? lessonId;
  final VoidCallback? onHintAdded;

  const _HintBottomSheet({
    required this.vocab,
    required this.hints,
    this.lessonId,
    this.onHintAdded,
  });

  @override
  State<_HintBottomSheet> createState() => _HintBottomSheetState();
}

class _HintBottomSheetState extends State<_HintBottomSheet>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  final _hintCtrl = TextEditingController();
  bool _submitted = false;
  List<Map<String, dynamic>> _localHints = [];

  @override
  void initState() {
    super.initState();
    _localHints = List<Map<String, dynamic>>.from(widget.hints);
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  void _close() {
    _ctrl.reverse().then((_) => Navigator.pop(context));
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SizedBox(
          height: screenH * 0.75,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Header with word + close
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.vocab['target'] ?? '',
                                    style: GoogleFonts.notoSerif(fontSize: 30,
                                        fontWeight: FontWeight.w700, color: AppColors.primary)),
                                Text(widget.vocab['correct_answer'] ?? '',
                                    style: GoogleFonts.inter(fontSize: 16,
                                        fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                          // Audio button
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          // Close red X
                          GestureDetector(
                            onTap: _close,
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE), shape: BoxShape.circle,
                                border: Border.all(color: Colors.red.shade200)),
                              child: Icon(Icons.close_rounded, color: Colors.red.shade500, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(color: AppColors.borderLight, height: 20),

                    // Scrollable body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── Set My Hint ──────────────────────────────────
                            Row(children: [
                              const Icon(Icons.edit_outlined, size: 13, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Text('SET MY HINT',
                                  style: AppTextStyles.captionUpper.copyWith(color: AppColors.primary)),
                            ]),
                            const SizedBox(height: 8),

                            if (!_submitted)
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.bgLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: TextField(
                                  controller: _hintCtrl,
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Your mnemonic / memory trick…',
                                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    suffixIcon: GestureDetector(
                                      onTap: () async {
                                        final txt = _hintCtrl.text.trim();
                                        if (txt.isEmpty) return;
                                        final itemId = widget.vocab['id'] as int?;
                                        if (itemId == null) return;
                                        
                                        setState(() => _submitted = true);
                                        try {
                                          final h = await ApiService.instance.postVocabHint(itemId, txt);
                                          final user = h['user'] as Map<String, dynamic>? ?? {};
                                          final username = user['username']?.toString() ?? 'Friend';
                                          
                                          // Hash username to color
                                          final hash = username.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
                                          final colors = [
                                            0xFF4CAF50, // Green
                                            0xFF2196F3, // Blue
                                            0xFFE91E63, // Pink
                                            0xFFFF9800, // Orange
                                            0xFF9C27B0, // Purple
                                            0xFF009688, // Teal
                                            0xFF3F51B5, // Indigo
                                            0xFF00BCD4, // Cyan
                                            0xFFFFC107, // Amber
                                          ];
                                          final colorVal = colors[hash % colors.length];

                                          setState(() {
                                            _localHints.insert(0, {
                                              'name': username,
                                              'color': colorVal,
                                              'hint': txt,
                                              'id': h['id'],
                                            });
                                          });

                                          widget.onHintAdded?.call();
                                        } catch (_) {
                                          setState(() => _submitted = false);
                                        }
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.send_rounded,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                  maxLines: 3, minLines: 1,
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded,
                                        color: AppColors.accentGreen, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('"${_hintCtrl.text}"',
                                          style: GoogleFonts.inter(fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: AppColors.textSecondary)),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() => _submitted = false),
                                      child: const Icon(Icons.edit, size: 14, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 20),

                            // ── Community Hints ───────────────────────────────
                            if (_localHints.isNotEmpty) ...[
                              Row(children: [
                                const Icon(Icons.people_outline_rounded, size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 5),
                                Text('COMMUNITY HINTS (${_localHints.length})',
                                    style: AppTextStyles.captionUpper),
                                const Spacer(),
                                Text('+ ADD YOURS',
                                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
                                        color: AppColors.primary, letterSpacing: 0.8)),
                              ]),
                              const SizedBox(height: 10),
                              ..._localHints.asMap().entries.map((e) =>
                                  _buildFriendHint(e.key, e.value)),
                            ] else
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(children: [
                                    const Icon(Icons.lightbulb_outline,
                                        size: 36, color: AppColors.textMuted),
                                    const SizedBox(height: 8),
                                    Text('No hints yet — be the first!',
                                        style: AppTextStyles.bodySmall),
                                  ]),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendHint(int index, Map<String, dynamic> hint) {
    final isFirst = index == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFirst ? AppColors.primary.withOpacity(0.05) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFirst ? AppColors.primary.withOpacity(0.2) : AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(hint['color'] as int),
            ),
            child: Center(
              child: Text((hint['name'] as String)[0],
                  style: GoogleFonts.inter(fontSize: 13,
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(hint['name'] as String,
                      style: GoogleFonts.inter(fontSize: 12,
                          fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  if (isFirst) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('TOP', style: GoogleFonts.inter(fontSize: 8,
                          fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(hint['hint'] as String,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
