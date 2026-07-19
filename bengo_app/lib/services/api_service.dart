import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _defaultBackendBaseUrl = 'https://jback2.zynix.us/api';

String get kBaseUrl {
  if (kIsWeb) {
    final host = Uri.base.host;
    if (host == 'jback2.zynix.us') {
      return 'https://jback2.zynix.us/api';
    }
    if (host == '127.0.0.1' || host == 'localhost') {
      return 'https://jback2.zynix.us/api';
    }
  }
  return _defaultBackendBaseUrl;
}

class ApiService {
  static ApiService? _instance;
  ApiService._();
  static ApiService get instance => _instance ??= ApiService._();

  Map<String, dynamic>? _cachedMe;
  final ValueNotifier<Map<String, dynamic>?> currentUserNotifier = ValueNotifier(null);

  void invalidateCache() {
    _cachedMe = null;
    currentUserNotifier.value = null;
  }

  // ── Token management ────────────────────────────────────────────────────────
  Future<String?> get _access async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, String>> _headersFor(String path) async {
    final token = await _access;
    final publicAuthPaths = {
      '/auth/login/',
      '/auth/register/',
      '/auth/send-verification-code/',
      '/auth/verify-email/',
      '/auth/check-username/',
      '/auth/check-email/',
      '/auth/token/refresh/',
      '/institutions/',
      '/announcements/',
    };
    return {
      'Content-Type': 'application/json',
      if (token != null && !publicAuthPaths.contains(path)) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token',  access);
    await prefs.setString('refresh_token', refresh);
  }

  Future<void> _saveUserToStorage(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  Future<void> clearTokens() async {
    try {
      await _req('POST', '/auth/logout/');
    } catch (_) {}
    _cachedMe = null;
    currentUserNotifier.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user');
  }

  Future<bool> refreshToken() async {
    final prefs  = await SharedPreferences.getInstance();
    final refresh = prefs.getString('refresh_token');
    if (refresh == null) return false;
    final res = await http.post(
      Uri.parse('$kBaseUrl/auth/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await prefs.setString('access_token', data['access']);
      return true;
    }
    return false;
  }

  // ── Generic request with auto-refresh ────────────────────────────────────────
  Future<http.Response> _req(
    String method, String path, {
    Map<String, dynamic>? body,
    bool retry = true,
  }) async {
    final headers = await _headersFor(path);
    final uri     = Uri.parse('$kBaseUrl$path');
    http.Response res;

    switch (method) {
      case 'GET':    res = await http.get(uri, headers: headers); break;
      case 'POST':   res = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null); break;
      case 'PATCH':  res = await http.patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null); break;
      case 'DELETE': res = await http.delete(uri, headers: headers); break;
      default:       throw Exception('Unknown method: $method');
    }

    final noRetryPaths = ['/auth/login/', '/auth/register/', '/auth/token/refresh/'];
    if (res.statusCode == 401 && retry && !noRetryPaths.contains(path)) {
      final ok = await refreshToken();
      if (ok) return _req(method, path, body: body, retry: false);
    }
    return res;
  }

  Map<String, dynamic> _decode(http.Response res) {
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, data.toString());
    }
    return data is Map ? data as Map<String, dynamic> : {'data': data};
  }

  List<dynamic> _decodeList(http.Response res) {
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, res.body);
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as List;
  }

  /// Public passthrough for use by feature-specific services (e.g. ClanService).
  /// Returns the decoded body as a Map, List, or primitive depending on the API response.
  Future<dynamic> req(String method, String path, {Map<String, dynamic>? body}) async {
    final res = await _req(method, path, body: body);
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, res.body);
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  // ── Auth ──────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String password2,
    required String firstName,
    required String lastName,
    required String preferredLevel,
    required String learningGoal,
    String avatarId = 'a1',
    int? institutionId,
    String? institutionalRegistrationNumber,
  }) async {
    final Map<String, dynamic> body = {
      'username': username,
      'email': email,
      'password': password,
      'password2': password2,
      'first_name': firstName,
      'last_name': lastName,
      'preferred_level': preferredLevel,
      'learning_goal': learningGoal,
      'avatar_id': avatarId,
    };
    if (institutionId != null) {
      body['institution_id'] = institutionId;
    }
    if (institutionalRegistrationNumber != null && institutionalRegistrationNumber.isNotEmpty) {
      body['institutional_registration_number'] = institutionalRegistrationNumber;
    }
    final res = await _req('POST', '/auth/register/', body: body);
    final data = _decode(res);
    await saveTokens(data['tokens']['access'], data['tokens']['refresh']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(data['user']));
    _cachedMe = data['user'];
    currentUserNotifier.value = data['user'];
    return data;
  }

  // Fetch institutions with optional search query
  Future<List<dynamic>> fetchInstitutions({String? search}) async {
    try {
      final url = search != null && search.isNotEmpty
          ? '/institutions/?search=$search'
          : '/institutions/';
      final res = await _req('GET', url);
      final data = _decodeList(res);
      print('DEBUG: Fetched ${data.length} institutions');
      return data;
    } catch (e) {
      print('DEBUG: Exception in fetchInstitutions: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> fetchInstitutionMentors(int institutionId) async {
    final res = await _req('GET', '/institutions/$institutionId/mentors/');
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> assignMentor({
    required int institutionId,
    required int studentId,
    required int mentorId,
  }) async {
    final res = await _req('POST', '/institutions/$institutionId/assignments/', body: {
      'student_id': studentId,
      'mentor_id': mentorId,
    });
    return _decode(res);
  }

  Future<Map<String, dynamic>> sendVerificationCode({
    required String email,
  }) async {
    final res = await _req('POST', '/auth/send-verification-code/', body: {
      'email': email,
    });
    return _decode(res);
  }

  Future<Map<String, dynamic>> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final res = await _req('POST', '/auth/verify-email/', body: {
      'email': email,
      'code': code,
    });
    return _decode(res);
  }

  Future<bool> checkUsernameAvailability(String username) async {
    final uri = Uri.parse('$kBaseUrl/auth/check-username/?username=${Uri.encodeComponent(username)}');
    final headers = await _headersFor('/auth/check-username/');
    final res = await http.get(uri, headers: headers);
    final data = _decode(res);
    return data['available'] == true;
  }

  Future<bool> checkEmailAvailability(String email) async {
    final uri = Uri.parse('$kBaseUrl/auth/check-email/?email=${Uri.encodeComponent(email)}');
    final headers = await _headersFor('/auth/check-email/');
    final res = await http.get(uri, headers: headers);
    final data = _decode(res);
    return data['available'] == true;
  }

  Future<Map<String, dynamic>> login({
    required String identifier, required String password,
  }) async {
    final res = await _req('POST', '/auth/login/', body: {
      'email': identifier, 'password': password,
    });
    final data = _decode(res);
    await saveTokens(data['tokens']['access'], data['tokens']['refresh']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(data['user']));
    _cachedMe = data['user'];
    currentUserNotifier.value = data['user'];
    return data;
  }

  Future<Map<String, dynamic>> getMe({bool forceRefresh = false}) async {
    if (_cachedMe != null && !forceRefresh) {
      return _cachedMe!;
    }
    final res = await _req('GET', '/auth/me/');
    final data = _decode(res);
    _cachedMe = data;
    currentUserNotifier.value = data;
    await _saveUserToStorage(data);
    return data;
  }

  Future<List<dynamic>> fetchAnnouncements() async {
    final res = await _req('GET', '/announcements/');
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    _cachedMe = null;
    final res = await _req('PATCH', '/auth/me/', body: data);
    final updated = _decode(res);
    _cachedMe = updated;
    currentUserNotifier.value = updated;
    await _saveUserToStorage(updated);
    return updated;
  }

  // ── Exams ─────────────────────────────────────────────────────────────────────
  Future<List<dynamic>> getExams() async {
    final res = await _req('GET', '/courses/exams/');
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> getExam(int id) async {
    final res = await _req('GET', '/courses/exams/$id/');
    return _decode(res);
  }

  Future<Map<String, dynamic>> unlockExam(int id) async {
    _cachedMe = null;
    final res = await _req('POST', '/courses/exams/$id/unlock/');
    return _decode(res);
  }

  // ── Study & Test ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getLessonStudy(int lessonId) async {
    final res = await _req('GET', '/courses/lessons/$lessonId/study/');
    return _decode(res);
  }

  Future<Map<String, dynamic>> getLessonTest(int lessonId) async {
    final res = await _req('GET', '/courses/lessons/$lessonId/test/');
    return _decode(res);
  }

  Future<Map<String, dynamic>> submitTest({
    required int lessonId,
    required int correct,
    required int total,
  }) async {
    final res = await _req('POST', '/courses/lessons/$lessonId/submit/', body: {
      'correct': correct, 'total': total,
    });
    return _decode(res);
  }

  // ── Progress ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMyProgress() async {
    final res = await _req('GET', '/progress/my-progress/');
    return _decode(res);
  }
  // ── Community / Friends ──────────────────────────────────────────────────────
  Future<List<dynamic>> getFriends() async {
    final res = await _req('GET', '/community/friends/');
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> removeFriend(int friendId) async {
    final res = await _req('DELETE', '/community/friends/remove/', body: {
      'friend_id': friendId,
    });
    return _decode(res);
  }

  Future<List<dynamic>> getIncomingRequests() async {
    final res = await _req('GET', '/community/friend-requests/incoming/');
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> sendFriendRequest(int toUserId) async {
    final res = await _req('POST', '/community/friend-requests/', body: {'to_user_id': toUserId});
    return _decode(res);
  }

  Future<Map<String, dynamic>> acceptFriendRequest(int id) async {
    final res = await _req('POST', '/community/friend-requests/$id/accept/');
    return _decode(res);
  }

  Future<Map<String, dynamic>> rejectFriendRequest(int id) async {
    final res = await _req('POST', '/community/friend-requests/$id/reject/');
    return _decode(res);
  }

  Future<List<dynamic>> searchUsers(String q) async {
    final res = await _req('GET', '/community/users/search/?q=${Uri.encodeComponent(q)}');
    return _decodeList(res);
  }

  // ── Team rooms ─────────────────────────────────────────────────────────────
  Future<List<dynamic>> getTeams() async {
    final res = await _req('GET', '/teams/teams/');
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> getTeam(int id) async {
    final res = await _req('GET', '/teams/teams/$id/');
    return _decode(res);
  }

  Future<Map<String, dynamic>> createTeam(Map<String, dynamic> body) async {
    final res = await _req('POST', '/teams/teams/', body: body);
    return _decode(res);
  }

  Future<Map<String, dynamic>> startTeam(int id) async {
    final res = await _req('POST', '/teams/teams/$id/start/');
    return _decode(res);
  }

  Future<Map<String, dynamic>> endTeam(int id) async {
    final res = await _req('POST', '/teams/teams/$id/end/');
    return _decode(res);
  }

  Future<Map<String, dynamic>> sendTeamInvite(int teamId, int toUserId) async {
    final res = await _req('POST', '/teams/invites/', body: {
      'team': teamId,
      'to_user': toUserId,
    });
    return _decode(res);
  }

  Future<Map<String, dynamic>> submitTeamAnswer({
    required int teamId,
    required int questionId,
    required String answer,
  }) async {
    final res = await _req('POST', '/teams/actions/submit_answer/', body: {
      'team': teamId,
      'question': questionId,
      'answer': answer,
    });
    return _decode(res);
  }

  // ── Ranks ──────────────────────────────────────────────────────────────────
  Future<List<dynamic>> getRanksForExam(int examId) async {
    final res = await _req('GET', '/ranks/ranks/?exam=$examId');
    return _decodeList(res);
  }

  Future<List<dynamic>> getMyRankProgress() async {
    final res = await _req('GET', '/ranks/progress/');
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> activateRank(int progressId) async {
    final res = await _req('POST', '/ranks/progress/$progressId/activate/');
    return _decode(res);
  }

  Future<Map<String, dynamic>> resetRank(int progressId) async {
    final res = await _req('POST', '/ranks/progress/$progressId/reset/');
    return _decode(res);
  }

  Future<List<dynamic>> getRankLogs(int progressId) async {
    final res = await _req('GET', '/ranks/progress/$progressId/logs/');
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> upgradeRank(int rankId) async {
    _cachedMe = null;
    final res = await _req('POST', '/ranks/progress/upgrade/', body: {'rank_id': rankId});
    return _decode(res);
  }

  // ── Test Logs ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> submitTestLog({
    required int lessonId,
    int? rankId,
    required int total,
    required int correct,
    required int wrong,
    required int timedOut,
    required int timeTakenSeconds,
    required bool endedByTimer,
    required List<Map<String, dynamic>> questionDetail,
  }) async {
    final res = await _req('POST', '/ranks/logs/', body: {
      'lesson':              lessonId,
      if (rankId != null) 'rank': rankId,
      'total':               total,
      'correct':             correct,
      'wrong':               wrong,
      'timed_out':           timedOut,
      'time_taken_seconds':  timeTakenSeconds,
      'ended_by_timer':      endedByTimer,
      'question_detail':     questionDetail,
    });
    final data = _decode(res);
    if (_cachedMe != null) {
      if (data.containsKey('total_xp')) {
        _cachedMe!['xp'] = data['total_xp'];
      }
      if (data.containsKey('streak_days')) {
        _cachedMe!['streak_days'] = data['streak_days'];
      }
      currentUserNotifier.value = Map<String, dynamic>.from(_cachedMe!);
      await _saveUserToStorage(_cachedMe!);
    } else {
      await getMe(forceRefresh: true);
    }
    return data;
  }

  Future<Map<String, dynamic>?> getLastTestLog(int lessonId) async {
    final res = await _req('GET', '/ranks/logs/last/?lesson=$lessonId');
    if (res.statusCode == 200 && res.body != 'null') {
      return _decode(res);
    }
    return null;
  }

  Future<Map<String, dynamic>> studyComplete({
    required int lessonId,
    int? rankId,
  }) async {
    final res = await _req('POST', '/ranks/logs/study_complete/', body: {
      'lesson': lessonId,
      if (rankId != null) 'rank': rankId,
    });
    final data = _decode(res);
    if (_cachedMe != null) {
      if (data.containsKey('total_xp')) {
        _cachedMe!['xp'] = data['total_xp'];
      }
      if (data.containsKey('streak_days')) {
        _cachedMe!['streak_days'] = data['streak_days'];
      }
      currentUserNotifier.value = Map<String, dynamic>.from(_cachedMe!);
      await _saveUserToStorage(_cachedMe!);
    } else {
      await getMe(forceRefresh: true);
    }
    return data;
  }

  Future<Map<String, dynamic>> getDailyRevisionSession() async {
    final res = await _req('GET', '/ranks/logs/daily_revision_session/');
    return _decode(res);
  }

  Future<Map<String, dynamic>> submitDailyRevision({
    required int total,
    required int correct,
    required int wrong,
    required int timedOut,
  }) async {
    final res = await _req('POST', '/ranks/logs/daily_revision_submit/', body: {
      'total': total,
      'correct': correct,
      'wrong': wrong,
      'timed_out': timedOut,
    });
    final data = _decode(res);
    if (_cachedMe != null) {
      if (data.containsKey('total_xp')) {
        _cachedMe!['xp'] = data['total_xp'];
      }
      if (data.containsKey('streak_days')) {
        _cachedMe!['streak_days'] = data['streak_days'];
      }
      currentUserNotifier.value = Map<String, dynamic>.from(_cachedMe!);
      await _saveUserToStorage(_cachedMe!);
    } else {
      await getMe(forceRefresh: true);
    }
    return data;
  }

  // ── Certificates ───────────────────────────────────────────────────────────
  Future<List<dynamic>> getMyCertificates() async {
    final res = await _req('GET', '/certificates/mine/');
    return _decodeList(res);
  }

  // ── Community Hints ────────────────────────────────────────────────────────
  Future<List<dynamic>> getVocabHints([int? studyItemId]) async {
    final url = studyItemId != null 
        ? '/community/hints/?study_item_id=$studyItemId' 
        : '/community/hints/';
    final res = await _req('GET', url);
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> postVocabHint(int studyItemId, String hintText) async {
    final res = await _req('POST', '/community/hints/', body: {
      'study_item_id': studyItemId,
      'hint_text': hintText,
    });
    return _decode(res);
  }

  Future<List<dynamic>> getLeaderboard(String type) async {
    final res = await _req('GET', '/community/leaderboard/?type=$type');
    return _decodeList(res);
  }

  // ── RolePlay: Stories ──────────────────────────────────────────────────────
  Future<List<dynamic>> getRolePlayStories() async {
    final res = await _req('GET', '/roleplay/stories/');
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> getRolePlayStory(int id) async {
    final res = await _req('GET', '/roleplay/stories/$id/');
    return _decode(res);
  }

  // ── RolePlay: Rooms ────────────────────────────────────────────────────────
  Future<List<dynamic>> getRolePlayRooms({String? visibility}) async {
    final path = visibility != null
        ? '/roleplay/rooms/?visibility=$visibility'
        : '/roleplay/rooms/';
    final res = await _req('GET', path);
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> createRolePlayRoom({
    required String visibility,
    required int maxPlayers,
  }) async {
    final res = await _req('POST', '/roleplay/rooms/', body: {
      'visibility': visibility,
      'max_players': maxPlayers,
    });
    return _decode(res);
  }

  Future<Map<String, dynamic>> getRolePlayRoom(String code) async {
    final res = await _req('GET', '/roleplay/rooms/${code.toUpperCase()}/');
    return _decode(res);
  }

  Future<Map<String, dynamic>> joinRolePlayRoom(String code) async {
    final res = await _req('POST', '/roleplay/rooms/${code.toUpperCase()}/join/');
    return _decode(res);
  }

  Future<Map<String, dynamic>> spinRolePlayRoom(String code) async {
    final res = await _req('POST', '/roleplay/rooms/${code.toUpperCase()}/spin/');
    return _decode(res);
  }

  Future<Map<String, dynamic>> selectRolePlayCharacter(String code, int characterId) async {
    final res = await _req('POST', '/roleplay/rooms/${code.toUpperCase()}/select-character/', body: {
      'character_id': characterId,
    });
    return _decode(res);
  }

  Future<http.Response> _reqMultipart(
    String path, {
    required Map<String, String> fields,
    required File file,
    required String fileFieldName,
  }) async {
    final headers = await _headersFor(path);
    final uri = Uri.parse('$kBaseUrl$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers..remove('Content-Type'))
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath(fileFieldName, file.path));

    final streamed = await request.send();
    return await http.Response.fromStream(streamed);
  }

  Future<Map<String, dynamic>> submitRolePlayLine(String code, {
    required int dialogueId,
    required bool correct,
    required double score,
    bool passed = false,
    String? recordingPath,
  }) async {
    final path = '/roleplay/rooms/${code.toUpperCase()}/submit-line/';
    if (recordingPath != null) {
      final file = File(recordingPath);
      final res = await _reqMultipart(
        path,
        fields: {
          'dialogue_id': dialogueId.toString(),
          'correct': correct.toString(),
          'score': score.toString(),
          'passed': passed.toString(),
        },
        fileFieldName: 'recording',
        file: file,
      );
      return _decode(res);
    }

    final res = await _req('POST', path, body: {
      'dialogue_id': dialogueId,
      'correct': correct,
      'score': score,
      'passed': passed,
    });
    return _decode(res);
  }

  // ── RolePlay: History ──────────────────────────────────────────────────────
  Future<List<dynamic>> getRolePlayHistory() async {
    final res = await _req('GET', '/roleplay/history/');
    return _decodeList(res);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
