import 'dart:convert';
import 'api_service.dart';

/// Dedicated service for all Clan API calls.
/// Sits on top of the generic ApiService._req() mechanism.
class ClanService {
  ClanService._();
  static final instance = ClanService._();

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<dynamic> _get(String path, {Map<String, String>? params}) async {
    String url = path;
    if (params != null && params.isNotEmpty) {
      final q = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      url = '$path?$q';
    }
    return ApiService.instance.req('GET', url);
  }

  Future<dynamic> _post(String path, [Map<String, dynamic>? body]) =>
      ApiService.instance.req('POST', path, body: body);

  // ── Clan config ────────────────────────────────────────────────────────────

  /// Returns the singleton AdrenalineDuelConfig including timer, question count,
  /// and shield_combo_threshold.
  Future<Map<String, dynamic>> fetchDuelConfig() async {
    final data = await _get('/clan/config/duel/');
    return Map<String, dynamic>.from(data as Map);
  }

  // ── My clan ────────────────────────────────────────────────────────────────

  /// Returns the Clan the current user belongs to, or null if not in one.
  Future<Map<String, dynamic>?> fetchMyClan() async {
    try {
      final data = await _get('/clan/clans/', params: {'my': 'true'});
      final list = data as List;
      if (list.isEmpty) return null;
      return Map<String, dynamic>.from(list.first as Map);
    } catch (_) {
      return null;
    }
  }

  /// Full clan detail including members.
  Future<Map<String, dynamic>> fetchClanDetail(int clanId) async {
    final data = await _get('/clan/clans/$clanId/');
    return Map<String, dynamic>.from(data as Map);
  }

  /// List all members for a clan.
  Future<List<Map<String, dynamic>>> fetchClanMembers(int clanId) async {
    final detail = await fetchClanDetail(clanId);
    final members = detail['members'] as List? ?? [];
    return members.map((m) => Map<String, dynamic>.from(m as Map)).toList();
  }

  // ── Leaderboard ────────────────────────────────────────────────────────────

  /// scope: 'world' | 'country' | 'friends'
  Future<List<Map<String, dynamic>>> fetchLeaderboard(String scope) async {
    final data = await _get('/clan/clans/top/', params: {'scope': scope});
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Rush ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchActiveRush(int clanId) async {
    try {
      final params = clanId > 0
          ? {'clan': clanId.toString(), 'status': 'active'}
          : {'status': 'active'};
      final data = await _get('/clan/rushes/', params: params);
      final list = data as List;
      if (list.isEmpty) return null;
      return Map<String, dynamic>.from(list.first as Map);
    } catch (_) {
      return null;
    }
  }

  // ── Rival ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchMyRival() async {
    try {
      final data = await _get('/clan/rivals/', params: {'me': 'true'});
      final list = data as List;
      if (list.isEmpty) return null;
      return Map<String, dynamic>.from(list.first as Map);
    } catch (_) {
      return null;
    }
  }

  // ── Duel questions ─────────────────────────────────────────────────────────

  /// Fetches [count] random questions from all active question banks.
  /// Each question: { id, target, correct_answer, options: [List<String>] }
  Future<List<DuelQuestion>> fetchDuelQuestions(int count) async {
    final data = await _get('/clan/duel/questions/', params: {'count': count.toString()});
    return (data as List)
        .map((q) => DuelQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();
  }

  // ── Join / Leave ───────────────────────────────────────────────────────────

  Future<void> joinClan(int clanId) =>
      _post('/clan/clans/$clanId/join/');

  Future<void> leaveClan(int clanId) =>
      _post('/clan/clans/$clanId/leave/');

  // ── Join requests ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchJoinRequests(int clanId) async {
    final data = await _get('/clan/join-requests/', params: {'clan': clanId.toString()});
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> approveJoinRequest(int requestId) =>
      _post('/clan/join-requests/$requestId/approve/');

  Future<void> rejectJoinRequest(int requestId) =>
      _post('/clan/join-requests/$requestId/reject/');

  // ── Battles ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchRecentBattles(int clanId) async {
    final data = await _get('/clan/battles/', params: {
      'clan': clanId.toString(),
      'ordering': '-started_at',
    });
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Chat ───────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchClanChat(int clanId) async {
    // Returns clan history events as a simple chat log (no WebSocket yet)
    try {
      final data = await _get('/clan/history/', params: {'clan': clanId.toString()});
      return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }
}

// ── DuelQuestion model ────────────────────────────────────────────────────────

class DuelQuestion {
  final int id;
  final String target;
  final String correctAnswer;
  final List<String> options;

  const DuelQuestion({
    required this.id,
    required this.target,
    required this.correctAnswer,
    required this.options,
  });

  factory DuelQuestion.fromJson(Map<String, dynamic> j) => DuelQuestion(
        id:            j['id'] as int,
        target:        j['target'] as String,
        correctAnswer: j['correct_answer'] as String,
        options:       List<String>.from(j['options'] as List),
      );
}
