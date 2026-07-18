from rest_framework import serializers
from . import models


class RolePlayCharacterSerializer(serializers.ModelSerializer):
    class Meta:
        model  = models.RolePlayCharacter
        fields = ['id', 'name', 'emoji', 'display_order']


class RolePlayDialogueSerializer(serializers.ModelSerializer):
    character_name  = serializers.CharField(source='character.name', read_only=True)
    character_emoji = serializers.CharField(source='character.emoji', read_only=True)
    character_order = serializers.IntegerField(source='character.display_order', read_only=True)

    class Meta:
        model  = models.RolePlayDialogue
        fields = [
            'id', 'character', 'character_name', 'character_emoji', 'character_order',
            'display_order', 'japanese', 'romaji', 'english', 'emotion', 'pause_ms',
        ]


class RolePlayStorySerializer(serializers.ModelSerializer):
    characters     = RolePlayCharacterSerializer(many=True, read_only=True)
    dialogues      = RolePlayDialogueSerializer(many=True, read_only=True)
    character_count= serializers.SerializerMethodField()
    dialogue_count = serializers.SerializerMethodField()

    class Meta:
        model  = models.RolePlayStory
        fields = [
            'id', 'title', 'category', 'jlpt_level', 'difficulty', 'cover_emoji',
            'is_published', 'created_at', 'updated_at',
            'character_count', 'dialogue_count', 'characters', 'dialogues',
        ]

    def get_character_count(self, obj):
        return obj.characters.count()

    def get_dialogue_count(self, obj):
        return obj.dialogues.count()


class RolePlayStoryListSerializer(serializers.ModelSerializer):
    """Lightweight — no nested dialogues (for list views)."""
    character_count= serializers.SerializerMethodField()
    dialogue_count = serializers.SerializerMethodField()

    class Meta:
        model  = models.RolePlayStory
        fields = [
            'id', 'title', 'category', 'jlpt_level', 'difficulty',
            'cover_emoji', 'is_published', 'created_at',
            'character_count', 'dialogue_count',
        ]

    def get_character_count(self, obj):
        return obj.characters.count()

    def get_dialogue_count(self, obj):
        return obj.dialogues.count()


class RolePlayMemberSerializer(serializers.ModelSerializer):
    username       = serializers.CharField(source='user.username', read_only=True)
    avatar_id      = serializers.CharField(source='user.avatar_id', read_only=True, default='a1')
    character_name = serializers.CharField(source='character.name', read_only=True, default=None)
    character_emoji= serializers.CharField(source='character.emoji', read_only=True, default=None)

    class Meta:
        model  = models.RolePlayMember
        fields = ['id', 'user', 'username', 'avatar_id', 'is_creator',
                  'character', 'character_name', 'character_emoji', 'score', 'joined_at']


class RolePlayRoomSerializer(serializers.ModelSerializer):
    members       = RolePlayMemberSerializer(many=True, read_only=True)
    creator_id    = serializers.IntegerField(source='creator.id', read_only=True)
    story_title   = serializers.CharField(source='story.title', read_only=True, default=None)
    story_emoji   = serializers.CharField(source='story.cover_emoji', read_only=True, default=None)
    member_count  = serializers.SerializerMethodField()

    class Meta:
        model  = models.RolePlayRoom
        fields = [
            'id', 'room_code', 'visibility', 'max_players', 'status',
            'creator_id', 'story', 'story_title', 'story_emoji',
            'members', 'member_count', 'created_at',
        ]
        read_only_fields = ['room_code', 'status', 'creator_id']

    def get_member_count(self, obj):
        return obj.members.count()


class RolePlayLineResultSerializer(serializers.ModelSerializer):
    class Meta:
        model  = models.RolePlayLineResult
        fields = ['id', 'dialogue', 'correct', 'score', 'created_at']


class RolePlayHistorySerializer(serializers.ModelSerializer):
    story_title   = serializers.CharField(source='room.story.title', read_only=True, default='')
    story_emoji   = serializers.CharField(source='room.story.cover_emoji', read_only=True, default='🎭')
    room_code     = serializers.CharField(source='room.room_code', read_only=True)
    line_results  = RolePlayLineResultSerializer(many=True, read_only=True)
    correct_count = serializers.SerializerMethodField()
    accuracy      = serializers.SerializerMethodField()
    created_at    = serializers.DateTimeField(source='room.created_at', read_only=True)

    class Meta:
        model  = models.RolePlayMember
        fields = [
            'id', 'room_code', 'story_title', 'story_emoji',
            'score', 'correct_count', 'accuracy', 'line_results', 'created_at',
        ]

    def get_correct_count(self, obj):
        return obj.line_results.filter(correct=True).count()

    def get_accuracy(self, obj):
        total = obj.line_results.count()
        if total == 0:
            return 0.0
        return round(obj.line_results.filter(correct=True).count() / total, 2)
