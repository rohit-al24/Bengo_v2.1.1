"""
Clan System Models
==================
All database tables for the BenGo Clan — Adrenaline Rush & Clan Rush Edition.

Model hierarchy:
  ClanGlobalSettings       — admin-configurable global config
  SlotUnlockTier           — trophy-gated slot progression tiers
  ClanRushSchedule         — rush event scheduling config
  AdrenalineDuelConfig     — duel mechanics config
  RewardChestConfig        — chest economy config
  RivalSystemConfig        — rival assignment config
  ComebackConfig           — last-stand mechanic config
  RetentionConfig          — notifications & streak config
  ──────────────────────────────
  Clan                     — core clan entity
  ClanMember               — membership with role
  ClanJoinRequest          — join requests queue
  ──────────────────────────────
  ClanRush                 — a single clan rush event
  ClanRushContribution     — per-member contribution to a rush
  ──────────────────────────────
  ClanBattle               — a completed match record
  AdrenalineDuelResult     — tug-of-war duel outcome per battle
  ──────────────────────────────
  RewardChest              — chest awarded to a user
  Rival                    — auto-assigned rival pair
  ClanHistory              — append-only event log per clan
"""

from django.conf import settings
from django.db import models
from django.utils import timezone
import json


# ─────────────────────────────────────────────────────────────────────────────
# ADMIN CONFIGURATION MODELS
# ─────────────────────────────────────────────────────────────────────────────

class ClanGlobalSettings(models.Model):
    """Singleton-style global settings table.  Only one row is ever used."""

    # ── Creation requirements ──────────────────────────────────────────────
    xp_required_to_create        = models.PositiveIntegerField(default=20000)
    coins_required_to_create      = models.PositiveIntegerField(default=500)
    minimum_account_level         = models.PositiveSmallIntegerField(default=5)

    # ── Clan naming ────────────────────────────────────────────────────────
    clan_name_min_length          = models.PositiveSmallIntegerField(default=3)
    clan_name_max_length          = models.PositiveSmallIntegerField(default=24)
    clan_description_max_length   = models.PositiveSmallIntegerField(default=200)
    allow_renames                 = models.BooleanField(default=True)
    rename_coin_cost              = models.PositiveIntegerField(default=200)

    # ── Joining — leader-controlled bounds ─────────────────────────────────
    allow_leader_set_min_trophies = models.BooleanField(default=True)
    global_floor_min_trophies     = models.PositiveIntegerField(default=0)
    global_ceiling_min_trophies   = models.PositiveIntegerField(default=5000)
    default_min_join_trophies     = models.PositiveIntegerField(default=0)

    # ── Slot progression ───────────────────────────────────────────────────
    initial_member_slots          = models.PositiveSmallIntegerField(default=3)
    maximum_clan_members          = models.PositiveSmallIntegerField(default=10)

    # ── Separate progression per league ───────────────────────────────────
    separate_progression_per_league = models.BooleanField(default=False)

    # ── Match / Battle ─────────────────────────────────────────────────────
    knife_decision_timer_seconds  = models.PositiveSmallIntegerField(default=10)
    auto_accept_on_timeout        = models.BooleanField(default=True)

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name        = 'Clan Global Settings'
        verbose_name_plural = 'Clan Global Settings'

    def __str__(self):
        return 'Clan Global Settings'


class SlotUnlockTier(models.Model):
    """Ordered list of trophy milestones that unlock additional clan slots."""

    settings           = models.ForeignKey(ClanGlobalSettings, on_delete=models.CASCADE, related_name='slot_tiers')
    tier_num           = models.PositiveSmallIntegerField()           # auto-numbered, read-only in UI
    extra_slots        = models.PositiveSmallIntegerField(default=2)
    trophies_required  = models.PositiveIntegerField()
    running_total_slots = models.PositiveSmallIntegerField()          # auto-calculated

    # Optional per-league override (used when separate_progression_per_league=True)
    LEAGUE_CHOICES = [
        ('all', 'All Leagues'),
        ('bronze', 'Bronze'), ('silver', 'Silver'), ('gold', 'Gold'),
        ('diamond', 'Diamond'), ('master', 'Master'), ('legend', 'Legend'),
    ]
    league = models.CharField(max_length=10, choices=LEAGUE_CHOICES, default='all')

    class Meta:
        ordering = ['league', 'tier_num']
        unique_together = [('settings', 'league', 'trophies_required')]

    def __str__(self):
        return f'Tier {self.tier_num}: +{self.extra_slots} slots @ {self.trophies_required} trophies ({self.league})'


class ClanRushSchedule(models.Model):
    """Defines when and how Clan Rush events fire."""

    TRIGGER_MODES = [
        ('scheduled',  'Scheduled'),
        ('randomized', 'Randomized Window'),
        ('manual',     'Manual (Admin-triggered)'),
        ('hybrid',     'Hybrid'),
    ]

    trigger_mode             = models.CharField(max_length=12, choices=TRIGGER_MODES, default='scheduled')
    scheduled_times          = models.JSONField(default=list, blank=True,
                                                 help_text='List of "HH:MM" strings for scheduled mode')
    randomized_earliest      = models.TimeField(null=True, blank=True)
    randomized_latest        = models.TimeField(null=True, blank=True)
    randomized_min_gap_hours = models.PositiveSmallIntegerField(default=4)

    rush_duration_minutes    = models.PositiveSmallIntegerField(default=30)
    rushes_per_day_max       = models.PositiveSmallIntegerField(default=3)
    cooldown_between_minutes = models.PositiveSmallIntegerField(default=60)
    minimum_online_members   = models.PositiveSmallIntegerField(default=1)

    # Eligibility
    minimum_clan_level       = models.PositiveSmallIntegerField(default=1)
    minimum_members_for_rewards = models.PositiveSmallIntegerField(default=1)
    exclude_clans_in_war     = models.BooleanField(default=False)

    # Contribution formula
    points_per_correct_answer = models.PositiveSmallIntegerField(default=10)
    points_per_combo_tier     = models.PositiveSmallIntegerField(default=5,
                                    help_text='Points multiplied by combo tier (x2=10, x5=25 etc.)')
    points_per_match_won      = models.PositiveSmallIntegerField(default=50)
    rush_battle_multiplier    = models.FloatField(default=2.0)
    allow_overflow_past_100   = models.BooleanField(default=True)

    # Reward tiers
    bronze_threshold_pct      = models.PositiveSmallIntegerField(default=50)
    bronze_reward_coins        = models.PositiveIntegerField(default=100)
    silver_threshold_pct      = models.PositiveSmallIntegerField(default=75)
    silver_reward_description  = models.CharField(max_length=200, default='Clan-wide XP boost 1 hour')
    gold_threshold_pct         = models.PositiveSmallIntegerField(default=100)
    gold_reward_description    = models.CharField(max_length=200, default='Reward chest for every contributor')
    perfect_rush_threshold_pct = models.PositiveSmallIntegerField(default=110)
    perfect_rush_reward        = models.CharField(max_length=200, default='Perfect Rush badge')
    consolation_reward_coins   = models.PositiveIntegerField(default=20,
                                    help_text='Given to non-contributors when clan reaches the goal')

    # Notifications
    send_rush_start_notification = models.BooleanField(default=True)
    rush_start_template          = models.TextField(default='Your clan is on a Rush! {duration} minutes to hit the goal.')
    send_5min_warning            = models.BooleanField(default=True)
    warning_5min_template        = models.TextField(default='5 minutes left on the Rush! Push together!')
    send_milestone_25            = models.BooleanField(default=True)
    send_milestone_50            = models.BooleanField(default=True)
    send_milestone_75            = models.BooleanField(default=True)
    send_milestone_100           = models.BooleanField(default=True)

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name        = 'Clan Rush Schedule'
        verbose_name_plural = 'Clan Rush Schedules'

    def __str__(self):
        return f'Rush Schedule ({self.trigger_mode})'


class AdrenalineDuelConfig(models.Model):
    """Tuning knobs for the tug-of-war duel bar and Overdrive Clash."""

    # Fill rates
    fill_per_correct_answer   = models.FloatField(default=10.0,  help_text='% of bar filled per correct answer')
    fill_per_combo_tier       = models.FloatField(default=2.0,   help_text='Additional % per combo tier above x1')
    decay_rate_idle           = models.FloatField(default=1.0,   help_text='% lost per second while idle')
    decay_rate_wrong_answer   = models.FloatField(default=5.0,   help_text='% lost on wrong answer')

    # Momentum steal
    combo_tier_steal_threshold = models.PositiveSmallIntegerField(default=5)
    steal_pct_per_combo_tick   = models.FloatField(default=3.0)
    max_steal_per_match        = models.FloatField(default=40.0, help_text='Total % that can be stolen from one opponent')

    # Overdrive Clash (both reach 100%)
    overdrive_trigger_threshold  = models.FloatField(default=100.0)
    overdrive_question_count     = models.PositiveSmallIntegerField(default=3)
    overdrive_question_timer_sec = models.PositiveSmallIntegerField(default=5)
    overdrive_score_multiplier   = models.FloatField(default=2.0)
    overdrive_loser_bp_penalty   = models.PositiveIntegerField(default=50)
    overdrive_winner_badge       = models.BooleanField(default=True)

    # Single-player Adrenaline Mode (only one reaches 100%)
    adrenaline_mode_duration_sec  = models.PositiveSmallIntegerField(default=20)
    adrenaline_mode_bp_multiplier = models.FloatField(default=1.5)
    adrenaline_mode_speed_mult    = models.FloatField(default=1.3)
    adrenaline_mode_timer_reduction_sec = models.PositiveSmallIntegerField(default=3)
    adrenaline_screen_shake       = models.BooleanField(default=True)
    adrenaline_heartbeat_sound    = models.BooleanField(default=True)
    adrenaline_red_aura           = models.BooleanField(default=True)
    adrenaline_voice_announcement = models.BooleanField(default=True)

    # Sabotage Strike
    sabotage_opponent_adrenaline_threshold = models.FloatField(default=70.0,
        help_text='Opponent adrenaline % above which Knife deals bonus steal')
    sabotage_bonus_steal_pct = models.FloatField(default=10.0)

    # Shield Reflect
    shield_reflect_pct = models.FloatField(default=5.0,
        help_text='% of adrenaline reflected back to attacker on successful block')

    # ── Match-wide settings (NEW) ──────────────────────────────────────────────
    duel_timer_seconds    = models.PositiveSmallIntegerField(default=120,
        help_text='Overall match countdown in seconds. When 0, higher BP wins.')
    questions_per_duel    = models.PositiveSmallIntegerField(default=20,
        help_text='Number of questions pulled from active banks per duel session.')
    shield_combo_threshold = models.PositiveSmallIntegerField(default=3,
        help_text='Minimum combo a defender must have to be offered a Shield option on incoming attack.')

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name        = 'Adrenaline Duel Config'
        verbose_name_plural = 'Adrenaline Duel Config'

    def __str__(self):
        return 'Adrenaline Duel Config'


class MomentumBarConfig(models.Model):
    """Visual/haptic tuning for the tug-of-war bar."""

    divider_animation_speed_ms   = models.PositiveSmallIntegerField(default=300)
    color_shift_breakpoints      = models.JSONField(default=list, blank=True,
                                       help_text='List of {pct: int, intensity: str} objects')
    haptic_on_steal              = models.BooleanField(default=True)
    haptic_steal_intensity       = models.CharField(max_length=20, default='medium',
                                       choices=[('light','Light'),('medium','Medium'),('heavy','Heavy')])
    haptic_on_overdrive          = models.BooleanField(default=True)
    screen_darken_on_clash       = models.BooleanField(default=True)
    screen_darken_intensity      = models.FloatField(default=0.6, help_text='0.0–1.0 opacity of darken overlay')

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name        = 'Momentum Bar Config'
        verbose_name_plural = 'Momentum Bar Config'

    def __str__(self):
        return 'Momentum Bar Config'


class RewardChestConfig(models.Model):
    """Chest economy configuration per tier."""

    TIER_CHOICES = [('common','Common'),('rare','Rare'),('epic','Epic'),('legendary','Legendary')]

    tier                    = models.CharField(max_length=12, choices=TIER_CHOICES, unique=True)
    drop_rate_weight        = models.FloatField(default=1.0,
                                help_text='Relative weight; higher = more common drop')
    coin_reward_min         = models.PositiveIntegerField(default=10)
    coin_reward_max         = models.PositiveIntegerField(default=50)
    xp_reward_min           = models.PositiveIntegerField(default=5)
    xp_reward_max           = models.PositiveIntegerField(default=25)
    cosmetic_drop_chance    = models.FloatField(default=0.05, help_text='0.0–1.0')
    chest_key_drop_chance   = models.FloatField(default=0.02, help_text='0.0–1.0')

    # Pity timers (global, stored once — only read from the 'common' row for simplicity)
    guaranteed_rare_after   = models.PositiveSmallIntegerField(default=5,
                                help_text='# common-only chests before a Rare is guaranteed')
    guaranteed_epic_after   = models.PositiveSmallIntegerField(default=20)
    guaranteed_legendary_after = models.PositiveSmallIntegerField(default=50)

    # Source rules
    awarded_on_win          = models.BooleanField(default=True)
    awarded_on_loss         = models.BooleanField(default=True)
    loss_weight_modifier    = models.FloatField(default=0.3,
                                help_text='Multiplies drop_rate_weight on a loss')
    clan_rush_gold_chest_override = models.BooleanField(default=False,
                                help_text='If True, Rush Gold tier always awards this chest tier')
    instant_open            = models.BooleanField(default=True,
                                help_text='False = timed unlock; True = instant open')
    unlock_duration_minutes = models.PositiveSmallIntegerField(default=0)

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering            = ['drop_rate_weight']
        verbose_name        = 'Reward Chest Config'
        verbose_name_plural = 'Reward Chest Configs'

    def __str__(self):
        return f'Chest Config — {self.tier}'


class RivalSystemConfig(models.Model):
    """Configuration for the rotating rival assignment system."""

    ASSIGNMENT_RULES = [
        ('trophy_range',      'Trophy Range'),
        ('recent_opponent',   'Recent Opponent'),
        ('regional',          'Regional'),
        ('hybrid',            'Hybrid'),
    ]

    assignment_rule         = models.CharField(max_length=20, choices=ASSIGNMENT_RULES, default='hybrid')
    trophy_range_tolerance  = models.PositiveIntegerField(default=200,
                                help_text='±N trophies from player for eligible rivals')
    refresh_cooldown_hours  = models.PositiveSmallIntegerField(default=72)
    grudge_match_bonus_pct  = models.FloatField(default=25.0,
                                help_text='% bonus reward for beating your rival')
    escalation_stages       = models.PositiveSmallIntegerField(default=5,
                                help_text='How many unresolved losses before flame hits max stage')
    rematch_prompt_cooldown_hours = models.PositiveSmallIntegerField(default=1)

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name        = 'Rival System Config'
        verbose_name_plural = 'Rival System Config'

    def __str__(self):
        return 'Rival System Config'


class ComebackConfig(models.Model):
    """Last Stand mechanic configuration."""

    enabled                       = models.BooleanField(default=True)
    trailing_bp_trigger_pct       = models.FloatField(default=40.0,
                                      help_text='Must be trailing by this % of leader BP to trigger')
    minimum_match_time_elapsed_sec = models.PositiveSmallIntegerField(default=60,
                                      help_text='Seconds into match before Last Stand can activate')
    bp_multiplier                 = models.FloatField(default=1.5)
    adrenaline_fill_boost         = models.FloatField(default=1.5,
                                      help_text='Multiplier on adrenaline fill rate during Last Stand')
    duration_seconds              = models.PositiveSmallIntegerField(default=20)
    max_activations_per_match     = models.PositiveSmallIntegerField(default=1)

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name        = 'Comeback Config'
        verbose_name_plural = 'Comeback Config'

    def __str__(self):
        return 'Comeback / Last Stand Config'


class RetentionConfig(models.Model):
    """Notification & responsible engagement configuration."""

    streak_multiplier_schedule    = models.JSONField(default=list, blank=True,
                                      help_text='List of {day: int, multiplier: float}')
    streak_grace_period_hours     = models.PositiveSmallIntegerField(default=2)

    # Session reminders
    notify_rush_starting          = models.BooleanField(default=True)
    notify_rival_online           = models.BooleanField(default=True)
    notify_chest_ready            = models.BooleanField(default=True)
    notify_streak_expiring        = models.BooleanField(default=True)

    # Responsible engagement
    session_reminder_after_minutes = models.PositiveSmallIntegerField(default=0,
                                      help_text='0 = disabled')
    quiet_hours_start             = models.TimeField(null=True, blank=True,
                                      help_text='No push notifications after this time')
    quiet_hours_end               = models.TimeField(null=True, blank=True)

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name        = 'Retention Config'
        verbose_name_plural = 'Retention Config'

    def __str__(self):
        return 'Retention & Notification Config'


# ─────────────────────────────────────────────────────────────────────────────
# CORE CLAN MODELS
# ─────────────────────────────────────────────────────────────────────────────

class Clan(models.Model):
    PRIVACY_CHOICES = [
        ('open',         'Open'),
        ('invite_only',  'Invite Only'),
        ('closed',       'Closed'),
    ]
    LEAGUE_CHOICES = [
        ('bronze',   'Bronze'),
        ('silver',   'Silver'),
        ('gold',     'Gold'),
        ('diamond',  'Diamond'),
        ('master',   'Master'),
        ('legend',   'Legend'),
    ]

    name                    = models.CharField(max_length=24, unique=True)
    tag                     = models.CharField(max_length=8, unique=True,
                                help_text='Short hashtag-style identifier, e.g. #BENGO42')
    description             = models.TextField(max_length=200, blank=True, default='')
    badge                   = models.CharField(max_length=8, default='⚔️',
                                help_text='Emoji badge character')
    banner                  = models.CharField(max_length=50, default='red_wave',
                                help_text='Banner style key')
    privacy                 = models.CharField(max_length=12, choices=PRIVACY_CHOICES, default='open')
    league                  = models.CharField(max_length=8, choices=LEAGUE_CHOICES, default='bronze')

    trophies                = models.PositiveIntegerField(default=0)
    slots_unlocked          = models.PositiveSmallIntegerField(default=3,
                                help_text='Current max member count based on slot unlock race')
    min_join_trophies       = models.PositiveIntegerField(default=0,
                                help_text='Leader-set minimum trophies to join')

    leader                  = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                                null=True, blank=True, related_name='led_clans')

    is_active               = models.BooleanField(default=True)
    created_at              = models.DateTimeField(auto_now_add=True)
    updated_at              = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-trophies']

    def __str__(self):
        return f'{self.name} [{self.tag}] ({self.league})'

    @property
    def member_count(self):
        return self.members.filter(is_active=True).count()


class ClanMember(models.Model):
    ROLE_CHOICES = [
        ('leader',     'Leader'),
        ('co_leader',  'Co-Leader'),
        ('elder',      'Elder'),
        ('member',     'Member'),
    ]

    clan                    = models.ForeignKey(Clan, on_delete=models.CASCADE, related_name='members')
    user                    = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                                related_name='clan_memberships')
    role                    = models.CharField(max_length=12, choices=ROLE_CHOICES, default='member')
    trophies_contributed    = models.PositiveIntegerField(default=0)
    is_active               = models.BooleanField(default=True)
    joined_at               = models.DateTimeField(auto_now_add=True)
    last_active_at          = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ('clan', 'user')
        ordering        = ['-trophies_contributed']

    def __str__(self):
        return f'{self.user} @ {self.clan.name} ({self.role})'


class ClanJoinRequest(models.Model):
    STATUS_CHOICES = [
        ('pending',  'Pending'),
        ('accepted', 'Accepted'),
        ('declined', 'Declined'),
    ]

    clan        = models.ForeignKey(Clan, on_delete=models.CASCADE, related_name='join_requests')
    user        = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                    related_name='clan_join_requests')
    status      = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    created_at  = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolved_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                    null=True, blank=True, related_name='resolved_join_requests')

    class Meta:
        unique_together = ('clan', 'user')
        ordering        = ['-created_at']

    def __str__(self):
        return f'JoinRequest: {self.user} → {self.clan.name} ({self.status})'


# ─────────────────────────────────────────────────────────────────────────────
# CLAN RUSH MODELS
# ─────────────────────────────────────────────────────────────────────────────

class ClanRush(models.Model):
    STATUS_CHOICES = [
        ('active',    'Active'),
        ('completed', 'Completed — Goal Reached'),
        ('expired',   'Expired — Goal Missed'),
        ('cancelled', 'Cancelled'),
    ]

    clan                = models.ForeignKey(Clan, on_delete=models.CASCADE, related_name='rushes')
    started_at          = models.DateTimeField(default=timezone.now)
    ends_at             = models.DateTimeField()
    goal_points         = models.PositiveIntegerField(default=1000)
    current_points      = models.PositiveIntegerField(default=0)
    status              = models.CharField(max_length=12, choices=STATUS_CHOICES, default='active')
    rewards_distributed = models.BooleanField(default=False)

    # Milestone flags (prevent double-posting)
    milestone_25_hit    = models.BooleanField(default=False)
    milestone_50_hit    = models.BooleanField(default=False)
    milestone_75_hit    = models.BooleanField(default=False)
    milestone_100_hit   = models.BooleanField(default=False)
    is_perfect_rush     = models.BooleanField(default=False)

    triggered_by        = models.CharField(max_length=20, default='scheduled',
                            choices=[('scheduled','Scheduled'),('randomized','Randomized'),
                                     ('manual','Manual'),('hybrid','Hybrid')])
    created_at          = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-started_at']

    def __str__(self):
        return f'Rush #{self.pk} — {self.clan.name} ({self.status})'

    @property
    def completion_pct(self):
        if self.goal_points == 0:
            return 0
        return round((self.current_points / self.goal_points) * 100, 1)

    @property
    def time_remaining_seconds(self):
        delta = self.ends_at - timezone.now()
        return max(0, int(delta.total_seconds()))


class ClanRushContribution(models.Model):
    """Each row is a single point-scoring event during a Rush."""

    rush        = models.ForeignKey(ClanRush, on_delete=models.CASCADE, related_name='contributions')
    member      = models.ForeignKey(ClanMember, on_delete=models.CASCADE, related_name='rush_contributions')
    points      = models.PositiveSmallIntegerField(default=0)
    source      = models.CharField(max_length=20, default='answer',
                    choices=[('answer','Correct Answer'),('combo','Combo'),
                             ('win','Match Win'),('rush_battle','Rush Battle')])
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f'+{self.points} by {self.member.user} on Rush #{self.rush_id}'


# ─────────────────────────────────────────────────────────────────────────────
# BATTLE & DUEL MODELS
# ─────────────────────────────────────────────────────────────────────────────

class ClanBattle(models.Model):
    BATTLE_TYPE_CHOICES = [
        ('global_ranked',  'Global Ranked'),
        ('friendly',       'Friendly Match'),
        ('clan_internal',  'Clan Internal'),
        ('clan_war',       'Clan War'),
        ('rush_battle',    'Rush Battle'),
    ]

    clan            = models.ForeignKey(Clan, on_delete=models.SET_NULL, null=True, blank=True,
                        related_name='battles')
    battle_type     = models.CharField(max_length=16, choices=BATTLE_TYPE_CHOICES)
    player_1        = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                        null=True, blank=True, related_name='clan_battles_as_p1')
    player_2        = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                        null=True, blank=True, related_name='clan_battles_as_p2')
    winner          = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                        null=True, blank=True, related_name='clan_battles_won')
    p1_battle_points = models.IntegerField(default=0)
    p2_battle_points = models.IntegerField(default=0)
    rush_contribution_points = models.PositiveIntegerField(default=0)
    started_at      = models.DateTimeField(auto_now_add=True)
    ended_at        = models.DateTimeField(null=True, blank=True)
    duration_seconds = models.PositiveIntegerField(default=0)
    linked_rush     = models.ForeignKey(ClanRush, on_delete=models.SET_NULL, null=True, blank=True,
                        related_name='battles')

    class Meta:
        ordering = ['-started_at']

    def __str__(self):
        return f'Battle #{self.pk} ({self.battle_type}) — {self.player_1} vs {self.player_2}'


class AdrenalineDuelResult(models.Model):
    """Stores the tug-of-war outcome of a single ClanBattle."""

    battle              = models.OneToOneField(ClanBattle, on_delete=models.CASCADE,
                            related_name='duel_result')
    attacker            = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                            null=True, blank=True, related_name='duel_attacks')
    defender            = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                            null=True, blank=True, related_name='duel_defenses')

    attacker_peak_meter = models.FloatField(default=0.0)
    defender_peak_meter = models.FloatField(default=0.0)
    total_steals        = models.FloatField(default=0.0,  help_text='Total % stolen across whole match')
    overdrive_triggered = models.BooleanField(default=False)
    overdrive_winner    = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                            null=True, blank=True, related_name='overdrive_wins')
    sabotage_strikes    = models.PositiveSmallIntegerField(default=0)
    shields_used        = models.PositiveSmallIntegerField(default=0)
    shields_reflected   = models.PositiveSmallIntegerField(default=0)
    comeback_activated  = models.BooleanField(default=False)
    near_miss_count     = models.PositiveSmallIntegerField(default=0)

    # Serialized tug-of-war timeline for match result replay
    timeline_json       = models.JSONField(default=list, blank=True,
                            help_text='List of {second, attacker_pct, defender_pct} snapshots')

    class Meta:
        verbose_name        = 'Adrenaline Duel Result'
        verbose_name_plural = 'Adrenaline Duel Results'

    def __str__(self):
        return f'Duel #{self.battle_id}: overdrive={self.overdrive_triggered}'


# ─────────────────────────────────────────────────────────────────────────────
# REWARD CHEST MODEL
# ─────────────────────────────────────────────────────────────────────────────

class RewardChest(models.Model):
    TIER_CHOICES = [('common','Common'),('rare','Rare'),('epic','Epic'),('legendary','Legendary')]
    SOURCE_CHOICES = [
        ('match_win',   'Match Win'),
        ('match_loss',  'Match Loss'),
        ('rush_gold',   'Clan Rush Gold Tier'),
        ('overdrive',   'Overdrive Victory'),
        ('admin_grant', 'Admin Grant'),
    ]

    user            = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                        related_name='reward_chests')
    tier            = models.CharField(max_length=12, choices=TIER_CHOICES)
    source          = models.CharField(max_length=12, choices=SOURCE_CHOICES)
    linked_battle   = models.ForeignKey(ClanBattle, on_delete=models.SET_NULL, null=True, blank=True,
                        related_name='chests_awarded')
    linked_rush     = models.ForeignKey(ClanRush, on_delete=models.SET_NULL, null=True, blank=True,
                        related_name='chests_awarded')

    # Contents (populated on open)
    coin_reward     = models.PositiveIntegerField(default=0)
    xp_reward       = models.PositiveIntegerField(default=0)
    cosmetic_key    = models.CharField(max_length=100, blank=True, default='')
    chest_key_count = models.PositiveSmallIntegerField(default=0)

    opened          = models.BooleanField(default=False)
    unlocks_at      = models.DateTimeField(null=True, blank=True,
                        help_text='Null = instant open; set for timed unlock')
    opened_at       = models.DateTimeField(null=True, blank=True)
    created_at      = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.tier.upper()} chest for {self.user} ({"opened" if self.opened else "sealed"})'


# ─────────────────────────────────────────────────────────────────────────────
# RIVAL MODEL
# ─────────────────────────────────────────────────────────────────────────────

class Rival(models.Model):
    user            = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                        related_name='rivalries_as_challenger')
    rival_user      = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                        related_name='rivalries_as_rival')
    assigned_at     = models.DateTimeField(auto_now_add=True)
    expires_at      = models.DateTimeField()
    user_wins       = models.PositiveSmallIntegerField(default=0)
    rival_wins      = models.PositiveSmallIntegerField(default=0)
    flame_stage     = models.PositiveSmallIntegerField(default=0,
                        help_text='0–5 stages; grows each unresolved match loss')
    is_active       = models.BooleanField(default=True)

    class Meta:
        unique_together = ('user', 'rival_user')
        ordering        = ['-assigned_at']

    def __str__(self):
        return f'Rival: {self.user} vs {self.rival_user} (flame={self.flame_stage})'


# ─────────────────────────────────────────────────────────────────────────────
# CLAN HISTORY (APPEND-ONLY EVENT LOG)
# ─────────────────────────────────────────────────────────────────────────────

class ClanHistory(models.Model):
    EVENT_TYPES = [
        ('member_joined',       'Member Joined'),
        ('member_left',         'Member Left'),
        ('member_kicked',       'Member Kicked'),
        ('role_changed',        'Role Changed'),
        ('slot_unlocked',       'Slot Unlocked'),
        ('rush_started',        'Clan Rush Started'),
        ('rush_completed',      'Clan Rush Completed'),
        ('rush_expired',        'Clan Rush Expired'),
        ('rush_milestone',      'Clan Rush Milestone'),
        ('war_started',         'Clan War Started'),
        ('war_ended',           'Clan War Ended'),
        ('trophy_milestone',    'Trophy Milestone'),
        ('leadership_transfer', 'Leadership Transferred'),
        ('clan_created',        'Clan Created'),
    ]

    clan        = models.ForeignKey(Clan, on_delete=models.CASCADE, related_name='history')
    event_type  = models.CharField(max_length=24, choices=EVENT_TYPES)
    description = models.TextField()
    actor       = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                    null=True, blank=True, related_name='clan_history_entries',
                    help_text='User who triggered the event, if applicable')
    metadata    = models.JSONField(default=dict, blank=True,
                    help_text='Extra payload: trophies overshot, previous role, etc.')
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering            = ['-created_at']
        verbose_name        = 'Clan History Entry'
        verbose_name_plural = 'Clan History'

    def __str__(self):
        return f'[{self.clan.name}] {self.event_type} @ {self.created_at:%Y-%m-%d %H:%M}'
