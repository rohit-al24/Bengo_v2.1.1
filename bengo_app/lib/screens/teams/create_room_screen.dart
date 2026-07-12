import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decorations.dart';
import '../../widgets/bengo_app_bar.dart';
import 'team_lobby_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _teamNameCtrl = TextEditingController();
  int _maxMembers = 4;
  List<dynamic> _exams = [];
  Map<String, dynamic>? _selectedExam;
  List<dynamic> _categories = [];
  Map<String, dynamic>? _selectedCategory;
  List<dynamic> _lessons = [];
  List<Map<String, dynamic>> _selectedLessons = [];
  final Map<int, List<dynamic>> _lessonQuestionsByLessonId = {};
  int _cooldownSeconds = 4;
  int _questionTimer = 15;
  int _knifeThreshold = 3;
  int _knifePointsPercentage = 25;
  int _durationSeconds = 300;
  bool _loading = false;
  bool _loadingExams = false;
  bool _loadingLessonQuestions = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    super.dispose();
  }

  String _displayName(Map<String, dynamic>? item) {
    if (item == null) return '';
    return (item['title'] ?? item['name'] ?? item['label'] ?? 'Untitled').toString();
  }

  Future<void> _loadExams() async {
    setState(() {
      _loadingExams = true;
      _error = null;
    });

    try {
      final examsData = await ApiService.instance.getExams();
      final exams = examsData.whereType<Map<String, dynamic>>().toList();
      if (!mounted) return;

      setState(() {
        _exams = exams;
        _selectedExam = null;
        _categories = [];
        _selectedCategory = null;
        _lessons = [];
        _selectedLessons = [];
        _lessonQuestionsByLessonId.clear();
      });

      if (exams.isNotEmpty) {
        final examId = exams.first['id'] as int?;
        if (examId != null) {
          await _loadExamDetails(examId);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load exams from the database.');
    } finally {
      if (mounted) {
        setState(() => _loadingExams = false);
      }
    }
  }

  Future<void> _loadExamDetails(int examId) async {
    try {
      final examData = await ApiService.instance.getExam(examId);
      final categories = (examData['categories'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          <Map<String, dynamic>>[];
      if (!mounted) return;

      setState(() {
        _selectedExam = Map<String, dynamic>.from(examData);
        _categories = categories;
        _selectedCategory = null;
        _lessons = [];
        _selectedLessons = [];
        _lessonQuestionsByLessonId.clear();
      });

      if (categories.isNotEmpty) {
        _selectCategory(categories.first);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load exam details.');
    }
  }

  Future<void> _selectExam(Map<String, dynamic> exam) async {
    final examId = exam['id'] as int?;
    if (examId == null) return;

    setState(() {
      _selectedExam = Map<String, dynamic>.from(exam);
      _categories = [];
      _selectedCategory = null;
      _lessons = [];
      _selectedLessons = [];
      _lessonQuestionsByLessonId.clear();
    });

    await _loadExamDetails(examId);
  }

  void _selectCategory(Map<String, dynamic> category) {
    final lessons = (category['lessons'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        <Map<String, dynamic>>[];

    setState(() {
      _selectedCategory = Map<String, dynamic>.from(category);
      _lessons = lessons;
      _selectedLessons = [];
      _lessonQuestionsByLessonId.clear();
    });
  }

  bool _isLessonSelected(Map<String, dynamic> lesson) {
    final lessonId = lesson['id'] as int?;
    if (lessonId == null) return false;
    return _selectedLessons.any((selected) => (selected['id'] as int?) == lessonId);
  }

  void _toggleLesson(Map<String, dynamic> lesson) {
    final lessonId = lesson['id'] as int?;
    if (lessonId == null) return;

    final isSelected = _isLessonSelected(lesson);
    setState(() {
      if (isSelected) {
        _selectedLessons.removeWhere((selected) => (selected['id'] as int?) == lessonId);
        _lessonQuestionsByLessonId.remove(lessonId);
      } else {
        _selectedLessons.add(Map<String, dynamic>.from(lesson));
      }
    });

    if (!isSelected) {
      _loadLessonQuestions(lessonId);
    }
  }

  Future<void> _loadLessonQuestions(int lessonId) async {
    setState(() => _loadingLessonQuestions = true);

    try {
      final testData = await ApiService.instance.getLessonTest(lessonId);
      final questions = (testData['questions'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _lessonQuestionsByLessonId[lessonId] = questions;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load quiz questions for this lesson.');
    } finally {
      if (mounted) {
        setState(() => _loadingLessonQuestions = false);
      }
    }
  }

  List<dynamic> _getPreviewQuestions() {
    return _lessonQuestionsByLessonId.values.expand((questions) => questions).toList();
  }

  Future<void> _createTeam() async {
    final name = _teamNameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please provide a team name.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payload = {
        'name': name,
        'max_members': _maxMembers,
        'settings': {
          'exam_id': _selectedExam?['id'],
          'exam_name': _displayName(_selectedExam).isEmpty ? null : _displayName(_selectedExam),
          'category_id': _selectedCategory?['id'],
          'category_name': _displayName(_selectedCategory).isEmpty ? null : _displayName(_selectedCategory),
          'lesson_ids': _selectedLessons.map((lesson) => lesson['id']).toList(),
          'lesson_names': _selectedLessons.map((lesson) => lesson['name']).toList(),
          'lesson_id': _selectedLessons.isNotEmpty ? _selectedLessons.first['id'] : null,
          'lesson_name': _selectedLessons.isNotEmpty ? _selectedLessons.first['name'] : null,
          'cooldown_seconds': _cooldownSeconds,
          'question_timer': _questionTimer,
          'knife_threshold': _knifeThreshold,
          'knife_points_percentage': _knifePointsPercentage,
          'duration_seconds': _durationSeconds,
        },
      };
      final result = await ApiService.instance.createTeam(payload);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => TeamLobbyScreen(teamId: result['id'] as int),
      ));
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _error = e.message;
        } else {
          _error = 'Could not create room. Please try again.';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text('Create Team Room',
                              style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          const SizedBox(height: 8),
                          Text('Design your battle room with settings, categories, and team rules.',
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400)),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSection(
                        title: 'Room Details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('TEAM NAME'),
                            _buildTextField(controller: _teamNameCtrl, hintText: 'Enter team name'),
                            const SizedBox(height: 16),
                            _buildLabel('MAX PLAYERS'),
                            _buildOptionsRow(['4', '6', '8'], '$_maxMembers', (value) {
                              setState(() => _maxMembers = int.parse(value));
                            }),
                            const SizedBox(height: 16),
                            _buildLabel('EXAM'),
                            if (_loadingExams)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: CircularProgressIndicator(color: AppColors.primary),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF121A2F),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF2F3A57)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _displayName(_selectedExam).isEmpty ? null : _displayName(_selectedExam),
                                    isExpanded: true,
                                    hint: Text('Select exam', style: GoogleFonts.inter(color: Colors.grey.shade500)),
                                    items: _exams.map((exam) {
                                      final examMap = exam as Map<String, dynamic>;
                                      final displayName = _displayName(examMap);
                                      return DropdownMenuItem<String>(
                                        value: displayName,
                                        child: Text(displayName, style: GoogleFonts.inter(color: Colors.white)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      for (final exam in _exams) {
                                        final examMap = exam as Map<String, dynamic>;
                                        if (_displayName(examMap) == value) {
                                          _selectExam(examMap);
                                          break;
                                        }
                                      }
                                    },
                                    dropdownColor: const Color(0xFF121A2F),
                                  ),
                                ),
                              ),
                            if (_exams.isEmpty && !_loadingExams)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('No exams are available right now.', style: GoogleFonts.inter(color: Colors.grey.shade500)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 18)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSection(
                        title: 'Exam Content',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('CATEGORIES'),
                            if (_categories.isEmpty)
                              Text(
                                _selectedExam == null
                                    ? 'Select an exam to load its categories.'
                                    : 'No categories are available for this exam yet.',
                                style: GoogleFonts.inter(color: Colors.grey.shade500),
                              )
                            else
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _categories.map((category) {
                                  final categoryMap = Map<String, dynamic>.from(category);
                                  final selected = _selectedCategory?['id'] == category['id'];
                                  return _buildChoiceChip(
                                    _displayName(categoryMap),
                                    selected,
                                    () => _selectCategory(categoryMap),
                                  );
                                }).toList(),
                              ),
                            if (_selectedCategory != null) ...[
                              const SizedBox(height: 16),
                              _buildLabel('LESSONS'),
                              if (_lessons.isEmpty)
                                Text('No lessons are available for this category.', style: GoogleFonts.inter(color: Colors.grey.shade500))
                              else
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _lessons.map((lesson) {
                                    final selected = _isLessonSelected(Map<String, dynamic>.from(lesson));
                                    return _buildChoiceChip(
                                      (lesson['name'] ?? 'Lesson').toString(),
                                      selected,
                                      () => _toggleLesson(Map<String, dynamic>.from(lesson)),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 16),
                              _buildLabel('QUIZ PREVIEW'),
                              if (_loadingLessonQuestions)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: CircularProgressIndicator(color: AppColors.primary),
                                  ),
                                )
                              else if (_selectedLessons.isEmpty)
                                Text('Select one or more lessons to preview quiz questions from the database.', style: GoogleFonts.inter(color: Colors.grey.shade500))
                              else if (_getPreviewQuestions().isEmpty)
                                Text('No quiz questions were returned for the selected lessons yet.', style: GoogleFonts.inter(color: Colors.grey.shade500))
                              else
                                Column(
                                  children: _getPreviewQuestions().take(6).toList().asMap().entries.map((entry) {
                                    final index = entry.key + 1;
                                    final question = entry.value;
                                    final prompt = (question['target'] ?? question['prompt'] ?? 'Question $index').toString();
                                    final options = <String>[
                                      if (question['correct_answer'] != null) question['correct_answer'].toString(),
                                      if (question['wrong_1'] != null) question['wrong_1'].toString(),
                                      if (question['wrong_2'] != null) question['wrong_2'].toString(),
                                      if (question['wrong_3'] != null) question['wrong_3'].toString(),
                                      if (question['wrong_4'] != null) question['wrong_4'].toString(),
                                    ].where((option) => option.isNotEmpty).toList();
                                    return Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF121A2F),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFF2F3A57)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Q$index: $prompt', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 6),
                                          Text(options.join(' • '), style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 18)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSection(
                        title: 'Game Settings',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('COOLDOWN'),
                            _buildNumberSlider(value: _cooldownSeconds.toDouble(), min: 2, max: 10, label: '${_cooldownSeconds}s', onChanged: (v) => setState(() => _cooldownSeconds = v.toInt())),
                            const SizedBox(height: 14),
                            _buildLabel('QUESTION TIMER'),
                            _buildNumberSlider(value: _questionTimer.toDouble(), min: 10, max: 30, label: '${_questionTimer}s', onChanged: (v) => setState(() => _questionTimer = v.toInt())),
                            const SizedBox(height: 14),
                            _buildLabel('KNIFE THRESHOLD'),
                            _buildNumberSlider(value: _knifeThreshold.toDouble(), min: 2, max: 6, label: '$_knifeThreshold correct', onChanged: (v) => setState(() => _knifeThreshold = v.toInt())),
                            const SizedBox(height: 14),
                            _buildLabel('KNIFE POINTS %'),
                            _buildNumberSlider(value: _knifePointsPercentage.toDouble(), min: 10, max: 50, label: '$_knifePointsPercentage%', onChanged: (v) => setState(() => _knifePointsPercentage = v.toInt())),
                            const SizedBox(height: 14),
                            _buildLabel('GAME DURATION'),
                            _buildNumberSlider(value: _durationSeconds.toDouble(), min: 180, max: 900, label: '${_durationSeconds ~/ 60} min', onChanged: (v) => setState(() => _durationSeconds = v.toInt())),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 22)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF0D0D1A),
                border: Border(top: BorderSide(color: Color(0xFF1F2438), width: 1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _createTeam,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('INITIALIZE ROOM', style: GoogleFonts.sourceCodePro(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return BenGoAppBar(
      showBack: true,
      actions: [
        Container(
          width: 40,
          height: 40,
          decoration: AppDecorations.skeuomorphicCard(radius: 14),
          child: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 22),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2F45), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.sourceCodePro(fontSize: 11, letterSpacing: 2, color: AppColors.accentCyan, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 1));
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF13182A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2F3A57)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildOptionsRow(List<String> options, String active, void Function(String) onTap) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((value) {
        final selected = value == active;
        return GestureDetector(
          onTap: () => onTap(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : const Color(0xFF121A2F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? AppColors.primary : const Color(0xFF2F3A57)),
            ),
            child: Text(value, style: GoogleFonts.inter(color: selected ? Colors.white : Colors.grey.shade400, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChoiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFF121A2F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : const Color(0xFF2F3A57)),
        ),
        child: Text(label, style: GoogleFonts.inter(color: selected ? Colors.white : Colors.grey.shade400)),
      ),
    );
  }

  Widget _buildNumberSlider({required double value, required double min, required double max, required String label, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            Text(label, style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: AppColors.primary,
          inactiveColor: Colors.grey.shade800,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
