import 'package:flutter/material.dart';

// ── Shared RolePlay models with fromJson ────────────────────────────────────────

class RolePlayCharacter {
  final int id;
  final String name, emoji;
  final int displayOrder;

  const RolePlayCharacter({
    required this.id,
    required this.name,
    required this.emoji,
    required this.displayOrder,
  });

  factory RolePlayCharacter.fromJson(Map<String, dynamic> j) => RolePlayCharacter(
    id:           j['id'] as int,
    name:         j['name'] as String? ?? 'Character',
    emoji:        j['emoji'] as String? ?? '👤',
    displayOrder: j['display_order'] as int? ?? 1,
  );

  // Colour derived from id so each character consistently gets a colour
  Color get color {
    final colours = [
      const Color(0xFFFF6B6B), const Color(0xFF4ECDC4),
      const Color(0xFFFFBE0B), const Color(0xFF667eea),
      const Color(0xFF43e97b), const Color(0xFFfa709a),
    ];
    return colours[id % colours.length];
  }
}

class RolePlayDialogue {
  final int id;
  final int characterId;
  final int displayOrder;
  final String speakerName, speakerEmoji;
  final String japanese, romaji, english, emotion;
  final int pauseMs;

  const RolePlayDialogue({
    required this.id,
    required this.characterId,
    required this.displayOrder,
    required this.speakerName,
    required this.speakerEmoji,
    required this.japanese,
    required this.romaji,
    required this.english,
    required this.emotion,
    required this.pauseMs,
  });

  factory RolePlayDialogue.fromJson(Map<String, dynamic> j) => RolePlayDialogue(
    id:            j['id'] as int,
    characterId:   j['character'] as int? ?? 0,
    displayOrder:  j['display_order'] as int? ?? 1,
    speakerName:   j['character_name'] as String? ?? 'Speaker',
    speakerEmoji:  j['character_emoji'] as String? ?? '👤',
    japanese:      j['japanese'] as String? ?? '',
    romaji:        j['romaji'] as String? ?? '',
    english:       j['english'] as String? ?? '',
    emotion:       j['emotion'] as String? ?? 'neutral',
    pauseMs:       j['pause_ms'] as int? ?? 1000,
  );
}

class RolePlayCompletedLine {
  final RolePlayDialogue dialogue;
  final bool correct;
  final double score;
  final String recognizedText;

  const RolePlayCompletedLine(this.dialogue, this.correct, this.score, this.recognizedText);
}

class RolePlayResult {
  final String storyTitle, storyEmoji;
  final String roomCode;
  final List<RolePlayCompletedLine> lines;
  final Duration elapsed;

  const RolePlayResult({
    required this.storyTitle,
    required this.storyEmoji,
    required this.roomCode,
    required this.lines,
    required this.elapsed,
  });
}

class RolePlayMember {
  final int id;
  final int userId;
  final String username, avatarId;
  final bool isCreator;
  final int? characterId;
  final String? characterName, characterEmoji;
  final double score;

  const RolePlayMember({
    required this.id,
    required this.userId,
    required this.username,
    required this.avatarId,
    required this.isCreator,
    this.characterId,
    this.characterName,
    this.characterEmoji,
    required this.score,
  });

  factory RolePlayMember.fromJson(Map<String, dynamic> j) => RolePlayMember(
    id:            j['id'] as int,
    userId:        j['user'] as int,
    username:      j['username'] as String? ?? 'Player',
    avatarId:      j['avatar_id'] as String? ?? 'a1',
    isCreator:     j['is_creator'] as bool? ?? false,
    characterId:   j['character'] as int?,
    characterName: j['character_name'] as String?,
    characterEmoji:j['character_emoji'] as String?,
    score:         (j['score'] as num?)?.toDouble() ?? 0.0,
  );
}

class RolePlayRoom {
  final int id;
  final String roomCode, visibility, status;
  final int creatorId, maxPlayers;
  final int? storyId;
  final String? storyTitle, storyEmoji;
  final List<RolePlayMember> members;

  const RolePlayRoom({
    required this.id,
    required this.roomCode,
    required this.visibility,
    required this.status,
    required this.creatorId,
    required this.maxPlayers,
    this.storyId,
    this.storyTitle,
    this.storyEmoji,
    required this.members,
  });

  factory RolePlayRoom.fromJson(Map<String, dynamic> j) => RolePlayRoom(
    id:          j['id'] as int,
    roomCode:    j['room_code'] as String? ?? '',
    visibility:  j['visibility'] as String? ?? 'public',
    status:      j['status'] as String? ?? 'waiting',
    creatorId:   j['creator_id'] as int? ?? 0,
    maxPlayers:  j['max_players'] as int? ?? 4,
    storyId:     j['story'] as int?,
    storyTitle:  j['story_title'] as String?,
    storyEmoji:  j['story_emoji'] as String?,
    members:     (j['members'] as List<dynamic>?)
        ?.map((m) => RolePlayMember.fromJson(m as Map<String, dynamic>))
        .toList() ?? [],
  );
}
