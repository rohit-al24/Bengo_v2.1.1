from django.contrib import admin
from .models import (
    ClanGlobalSettings, SlotUnlockTier, ClanRushSchedule,
    AdrenalineDuelConfig, MomentumBarConfig, RewardChestConfig,
    RivalSystemConfig, ComebackConfig, RetentionConfig,
    Clan, ClanMember, ClanJoinRequest,
    ClanRush, ClanRushContribution,
    ClanBattle, AdrenalineDuelResult,
    RewardChest, Rival, ClanHistory,
)


# ── Inline helpers ─────────────────────────────────────────────────────────────

class SlotUnlockTierInline(admin.TabularInline):
    model        = SlotUnlockTier
    extra        = 1
    readonly_fields = ('running_total_slots',)
    ordering     = ['tier_num']


class ClanMemberInline(admin.TabularInline):
    model   = ClanMember
    extra   = 0
    fields  = ('user', 'role', 'trophies_contributed', 'is_active', 'joined_at')
    readonly_fields = ('joined_at',)


class ClanJoinRequestInline(admin.TabularInline):
    model   = ClanJoinRequest
    extra   = 0
    fields  = ('user', 'status', 'created_at', 'resolved_at', 'resolved_by')
    readonly_fields = ('created_at', 'resolved_at')


class ClanRushContributionInline(admin.TabularInline):
    model   = ClanRushContribution
    extra   = 0
    readonly_fields = ('created_at',)


class ClanHistoryInline(admin.TabularInline):
    model   = ClanHistory
    extra   = 0
    readonly_fields = ('event_type', 'description', 'actor', 'created_at')
    can_delete = False


# ── Config admin ───────────────────────────────────────────────────────────────

@admin.register(ClanGlobalSettings)
class ClanGlobalSettingsAdmin(admin.ModelAdmin):
    inlines  = [SlotUnlockTierInline]
    fieldsets = (
        ('Creation Requirements', {
            'fields': ('xp_required_to_create', 'coins_required_to_create', 'minimum_account_level'),
        }),
        ('Clan Identity', {
            'fields': ('clan_name_min_length', 'clan_name_max_length', 'clan_description_max_length',
                       'allow_renames', 'rename_coin_cost'),
        }),
        ('Joining — Leader-Controlled Bounds', {
            'fields': ('allow_leader_set_min_trophies', 'global_floor_min_trophies',
                       'global_ceiling_min_trophies', 'default_min_join_trophies'),
        }),
        ('Slot Progression', {
            'fields': ('initial_member_slots', 'maximum_clan_members', 'separate_progression_per_league'),
        }),
        ('Match Settings', {
            'fields': ('knife_decision_timer_seconds', 'auto_accept_on_timeout'),
        }),
    )

    def has_add_permission(self, request):
        # Only one row allowed
        return not ClanGlobalSettings.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(ClanRushSchedule)
class ClanRushScheduleAdmin(admin.ModelAdmin):
    fieldsets = (
        ('Scheduling', {
            'fields': ('trigger_mode', 'scheduled_times', 'randomized_earliest', 'randomized_latest',
                       'randomized_min_gap_hours', 'rush_duration_minutes', 'rushes_per_day_max',
                       'cooldown_between_minutes', 'minimum_online_members'),
        }),
        ('Eligibility', {
            'fields': ('minimum_clan_level', 'minimum_members_for_rewards', 'exclude_clans_in_war'),
        }),
        ('Contribution Formula', {
            'fields': ('points_per_correct_answer', 'points_per_combo_tier', 'points_per_match_won',
                       'rush_battle_multiplier', 'allow_overflow_past_100'),
        }),
        ('Reward Tiers', {
            'fields': ('bronze_threshold_pct', 'bronze_reward_coins',
                       'silver_threshold_pct', 'silver_reward_description',
                       'gold_threshold_pct', 'gold_reward_description',
                       'perfect_rush_threshold_pct', 'perfect_rush_reward',
                       'consolation_reward_coins'),
        }),
        ('Notifications', {
            'fields': ('send_rush_start_notification', 'rush_start_template',
                       'send_5min_warning', 'warning_5min_template',
                       'send_milestone_25', 'send_milestone_50',
                       'send_milestone_75', 'send_milestone_100'),
        }),
    )


@admin.register(AdrenalineDuelConfig)
class AdrenalineDuelConfigAdmin(admin.ModelAdmin):
    fieldsets = (
        ('Fill Rates', {
            'fields': ('fill_per_correct_answer', 'fill_per_combo_tier',
                       'decay_rate_idle', 'decay_rate_wrong_answer'),
        }),
        ('Momentum Steal', {
            'fields': ('combo_tier_steal_threshold', 'steal_pct_per_combo_tick', 'max_steal_per_match'),
        }),
        ('Overdrive Clash', {
            'fields': ('overdrive_trigger_threshold', 'overdrive_question_count',
                       'overdrive_question_timer_sec', 'overdrive_score_multiplier',
                       'overdrive_loser_bp_penalty', 'overdrive_winner_badge'),
        }),
        ('Single-Player Adrenaline Mode', {
            'fields': ('adrenaline_mode_duration_sec', 'adrenaline_mode_bp_multiplier',
                       'adrenaline_mode_speed_mult', 'adrenaline_mode_timer_reduction_sec',
                       'adrenaline_screen_shake', 'adrenaline_heartbeat_sound',
                       'adrenaline_red_aura', 'adrenaline_voice_announcement'),
        }),
        ('Sabotage Strike', {
            'fields': ('sabotage_opponent_adrenaline_threshold', 'sabotage_bonus_steal_pct'),
        }),
        ('Shield Reflect', {
            'fields': ('shield_reflect_pct',),
        }),
    )

    def has_add_permission(self, request):
        return not AdrenalineDuelConfig.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(MomentumBarConfig)
class MomentumBarConfigAdmin(admin.ModelAdmin):
    pass


@admin.register(RewardChestConfig)
class RewardChestConfigAdmin(admin.ModelAdmin):
    list_display  = ('tier', 'drop_rate_weight', 'coin_reward_min', 'coin_reward_max',
                     'cosmetic_drop_chance', 'instant_open')
    ordering      = ('-drop_rate_weight',)


@admin.register(RivalSystemConfig)
class RivalSystemConfigAdmin(admin.ModelAdmin):
    pass


@admin.register(ComebackConfig)
class ComebackConfigAdmin(admin.ModelAdmin):
    pass


@admin.register(RetentionConfig)
class RetentionConfigAdmin(admin.ModelAdmin):
    pass


# ── Clan admin ─────────────────────────────────────────────────────────────────

@admin.register(Clan)
class ClanAdmin(admin.ModelAdmin):
    list_display  = ('name', 'tag', 'league', 'trophies', 'member_count', 'privacy', 'is_active', 'created_at')
    list_filter   = ('league', 'privacy', 'is_active')
    search_fields = ('name', 'tag')
    inlines       = [ClanMemberInline, ClanJoinRequestInline, ClanHistoryInline]
    readonly_fields = ('created_at', 'updated_at')


@admin.register(ClanMember)
class ClanMemberAdmin(admin.ModelAdmin):
    list_display  = ('user', 'clan', 'role', 'trophies_contributed', 'is_active', 'joined_at')
    list_filter   = ('role', 'is_active')
    search_fields = ('user__username', 'clan__name')


@admin.register(ClanJoinRequest)
class ClanJoinRequestAdmin(admin.ModelAdmin):
    list_display  = ('user', 'clan', 'status', 'created_at')
    list_filter   = ('status',)
    search_fields = ('user__username', 'clan__name')


# ── Rush admin ─────────────────────────────────────────────────────────────────

@admin.register(ClanRush)
class ClanRushAdmin(admin.ModelAdmin):
    list_display  = ('clan', 'status', 'completion_pct', 'current_points', 'goal_points',
                     'started_at', 'ends_at', 'rewards_distributed')
    list_filter   = ('status', 'triggered_by')
    search_fields = ('clan__name',)
    inlines       = [ClanRushContributionInline]
    readonly_fields = ('completion_pct', 'time_remaining_seconds', 'created_at')


@admin.register(ClanRushContribution)
class ClanRushContributionAdmin(admin.ModelAdmin):
    list_display  = ('member', 'rush', 'points', 'source', 'created_at')
    list_filter   = ('source',)


# ── Battle admin ───────────────────────────────────────────────────────────────

@admin.register(ClanBattle)
class ClanBattleAdmin(admin.ModelAdmin):
    list_display  = ('pk', 'battle_type', 'player_1', 'player_2', 'winner',
                     'p1_battle_points', 'p2_battle_points', 'started_at', 'duration_seconds')
    list_filter   = ('battle_type',)
    search_fields = ('player_1__username', 'player_2__username', 'clan__name')


@admin.register(AdrenalineDuelResult)
class AdrenalineDuelResultAdmin(admin.ModelAdmin):
    list_display  = ('battle', 'overdrive_triggered', 'sabotage_strikes', 'comeback_activated')
    list_filter   = ('overdrive_triggered', 'comeback_activated')


# ── Chest admin ────────────────────────────────────────────────────────────────

@admin.register(RewardChest)
class RewardChestAdmin(admin.ModelAdmin):
    list_display  = ('user', 'tier', 'source', 'opened', 'coin_reward', 'xp_reward', 'created_at')
    list_filter   = ('tier', 'source', 'opened')
    search_fields = ('user__username',)


# ── Rival admin ────────────────────────────────────────────────────────────────

@admin.register(Rival)
class RivalAdmin(admin.ModelAdmin):
    list_display  = ('user', 'rival_user', 'user_wins', 'rival_wins', 'flame_stage', 'is_active', 'expires_at')
    list_filter   = ('is_active',)
    search_fields = ('user__username', 'rival_user__username')


# ── History admin ──────────────────────────────────────────────────────────────

@admin.register(ClanHistory)
class ClanHistoryAdmin(admin.ModelAdmin):
    list_display  = ('clan', 'event_type', 'actor', 'description', 'created_at')
    list_filter   = ('event_type',)
    search_fields = ('clan__name', 'description')
    readonly_fields = ('created_at',)

    def has_add_permission(self, request):
        return False   # append-only through code
