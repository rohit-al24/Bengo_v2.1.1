from rest_framework import serializers
from .models import (
    ClanGlobalSettings, SlotUnlockTier, ClanRushSchedule,
    AdrenalineDuelConfig, MomentumBarConfig, RewardChestConfig,
    RivalSystemConfig, ComebackConfig, RetentionConfig,
    Clan, ClanMember, ClanJoinRequest,
    ClanRush, ClanRushContribution,
    ClanBattle, AdrenalineDuelResult,
    RewardChest, Rival, ClanHistory,
)


# ─────────────────────────────────────────────────────────────────────────────
# CONFIG SERIALIZERS
# ─────────────────────────────────────────────────────────────────────────────

class SlotUnlockTierSerializer(serializers.ModelSerializer):
    class Meta:
        model  = SlotUnlockTier
        fields = '__all__'
        read_only_fields = ('running_total_slots', 'tier_num')


class ClanGlobalSettingsSerializer(serializers.ModelSerializer):
    slot_tiers = SlotUnlockTierSerializer(many=True, read_only=True)

    class Meta:
        model  = ClanGlobalSettings
        fields = '__all__'


class ClanRushScheduleSerializer(serializers.ModelSerializer):
    class Meta:
        model  = ClanRushSchedule
        fields = '__all__'


class AdrenalineDuelConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model  = AdrenalineDuelConfig
        fields = '__all__'


class MomentumBarConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model  = MomentumBarConfig
        fields = '__all__'


class RewardChestConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model  = RewardChestConfig
        fields = '__all__'


class RivalSystemConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model  = RivalSystemConfig
        fields = '__all__'


class ComebackConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model  = ComebackConfig
        fields = '__all__'


class RetentionConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model  = RetentionConfig
        fields = '__all__'


# ─────────────────────────────────────────────────────────────────────────────
# CLAN SERIALIZERS
# ─────────────────────────────────────────────────────────────────────────────

class ClanMemberSerializer(serializers.ModelSerializer):
    username   = serializers.CharField(source='user.username', read_only=True)
    avatar_url = serializers.SerializerMethodField()

    class Meta:
        model  = ClanMember
        fields = ('id', 'user', 'username', 'avatar_url', 'role',
                  'trophies_contributed', 'is_active', 'joined_at', 'last_active_at')
        read_only_fields = ('joined_at',)

    def get_avatar_url(self, obj):
        request = self.context.get('request')
        profile = getattr(obj.user, 'profile', None)
        if profile and profile.avatar and request:
            return request.build_absolute_uri(profile.avatar.url)
        return None


class ClanListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for browse/search lists."""
    member_count = serializers.ReadOnlyField()

    class Meta:
        model  = Clan
        fields = ('id', 'name', 'tag', 'badge', 'banner', 'league', 'trophies',
                  'member_count', 'slots_unlocked', 'privacy', 'min_join_trophies',
                  'is_active', 'created_at')


class ClanDetailSerializer(serializers.ModelSerializer):
    """Full serializer with nested members and history."""
    members      = ClanMemberSerializer(many=True, read_only=True)
    member_count = serializers.ReadOnlyField()
    leader_username = serializers.CharField(source='leader.username', read_only=True)

    class Meta:
        model  = Clan
        fields = '__all__'
        read_only_fields = ('trophies', 'slots_unlocked', 'created_at', 'updated_at')


class ClanJoinRequestSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    clan_name = serializers.CharField(source='clan.name', read_only=True)

    class Meta:
        model  = ClanJoinRequest
        fields = ('id', 'clan', 'clan_name', 'user', 'username', 'status', 'created_at', 'resolved_at')
        read_only_fields = ('created_at', 'resolved_at')


# ─────────────────────────────────────────────────────────────────────────────
# RUSH SERIALIZERS
# ─────────────────────────────────────────────────────────────────────────────

class ClanRushContributionSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='member.user.username', read_only=True)

    class Meta:
        model  = ClanRushContribution
        fields = ('id', 'rush', 'member', 'username', 'points', 'source', 'created_at')
        read_only_fields = ('created_at',)


class ClanRushSerializer(serializers.ModelSerializer):
    completion_pct        = serializers.ReadOnlyField()
    time_remaining_seconds = serializers.ReadOnlyField()
    clan_name             = serializers.CharField(source='clan.name', read_only=True)
    contributions         = ClanRushContributionSerializer(many=True, read_only=True)

    class Meta:
        model  = ClanRush
        fields = '__all__'
        read_only_fields = ('created_at', 'milestone_25_hit', 'milestone_50_hit',
                            'milestone_75_hit', 'milestone_100_hit')


class ClanRushSummarySerializer(serializers.ModelSerializer):
    """Lightweight version for banners / buttons."""
    completion_pct        = serializers.ReadOnlyField()
    time_remaining_seconds = serializers.ReadOnlyField()

    class Meta:
        model  = ClanRush
        fields = ('id', 'status', 'goal_points', 'current_points',
                  'completion_pct', 'time_remaining_seconds', 'ends_at')


# ─────────────────────────────────────────────────────────────────────────────
# BATTLE & DUEL SERIALIZERS
# ─────────────────────────────────────────────────────────────────────────────

class AdrenalineDuelResultSerializer(serializers.ModelSerializer):
    class Meta:
        model  = AdrenalineDuelResult
        fields = '__all__'


class ClanBattleSerializer(serializers.ModelSerializer):
    duel_result         = AdrenalineDuelResultSerializer(read_only=True)
    player_1_username   = serializers.CharField(source='player_1.username', read_only=True)
    player_2_username   = serializers.CharField(source='player_2.username', read_only=True)
    winner_username     = serializers.CharField(source='winner.username', read_only=True)

    class Meta:
        model  = ClanBattle
        fields = '__all__'
        read_only_fields = ('started_at',)


# ─────────────────────────────────────────────────────────────────────────────
# CHEST & RIVAL SERIALIZERS
# ─────────────────────────────────────────────────────────────────────────────

class RewardChestSerializer(serializers.ModelSerializer):
    class Meta:
        model  = RewardChest
        fields = '__all__'
        read_only_fields = ('user', 'coin_reward', 'xp_reward', 'cosmetic_key',
                            'chest_key_count', 'opened_at', 'created_at')


class RivalSerializer(serializers.ModelSerializer):
    user_username       = serializers.CharField(source='user.username', read_only=True)
    rival_username      = serializers.CharField(source='rival_user.username', read_only=True)

    class Meta:
        model  = Rival
        fields = '__all__'
        read_only_fields = ('assigned_at',)


# ─────────────────────────────────────────────────────────────────────────────
# HISTORY & DASHBOARD SERIALIZERS
# ─────────────────────────────────────────────────────────────────────────────

class ClanHistorySerializer(serializers.ModelSerializer):
    actor_username = serializers.CharField(source='actor.username', read_only=True)

    class Meta:
        model  = ClanHistory
        fields = '__all__'
        read_only_fields = ('created_at',)


class ClanDashboardStatsSerializer(serializers.Serializer):
    """Non-model serializer for the admin dashboard stats endpoint."""
    active_rushes_now              = serializers.IntegerField()
    rushes_completed_today         = serializers.IntegerField()
    avg_rush_completion_rate       = serializers.FloatField()
    overdrive_clashes_today        = serializers.IntegerField()
    active_rivalries               = serializers.IntegerField()
    chests_opened_today            = serializers.IntegerField()
    legendary_chests_opened_today  = serializers.IntegerField()
    comeback_activations_today     = serializers.IntegerField()
    avg_duel_duration_seconds      = serializers.FloatField()
    sabotage_strikes_today         = serializers.IntegerField()
    total_clans                    = serializers.IntegerField()
    total_clan_members             = serializers.IntegerField()
