from django.db import models
from django.conf import settings
from apps.courses.models import Lesson, Category, Exam

User = settings.AUTH_USER_MODEL


class Rank(models.Model):
    """A rank level within an exam (e.g. Bronze → Silver → Gold)."""
    RANK_TYPE_CHOICES = [
        ('category', 'Category-Wise'),
        ('full',     'Full Exam'),
    ]

    exam          = models.ForeignKey(Exam, on_delete=models.CASCADE, related_name='ranks')
    category      = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True,
                                      related_name='ranks',
                                      help_text='Fill only for Category-Wise ranks')
    name          = models.CharField(max_length=100, help_text='E.g. Bronze, Silver, Gold')
    rank_type     = models.CharField(max_length=10, choices=RANK_TYPE_CHOICES, default='full')
    order         = models.PositiveIntegerField(default=1, help_text='1 = lowest (beginner)')
    pass_percentage = models.PositiveIntegerField(default=70, help_text='Min % to pass each lesson in this rank')
    color         = models.CharField(max_length=7, default='#CD7F32', help_text='Hex color, e.g. #CD7F32 for Bronze')
    icon          = models.CharField(max_length=10, default='🥉', blank=True)
    # Per-question timer
    question_timer_seconds = models.PositiveIntegerField(default=30,
        help_text='Seconds per question. 0 = no limit.')
    # Overall test timer
    has_overall_timer     = models.BooleanField(default=False)
    overall_timer_seconds = models.PositiveIntegerField(default=300,
        help_text='Total seconds for the entire test. Used when has_overall_timer=True.')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['exam', 'order']
        unique_together = [('exam', 'order'), ('exam', 'name')]

    def __str__(self):
        return f"{self.exam.title} — {self.name} (#{self.order})"


class UserRankProgress(models.Model):
    """Tracks which ranks a user has achieved for an exam."""
    user          = models.ForeignKey(User, on_delete=models.CASCADE, related_name='rank_progress')
    rank          = models.ForeignKey(Rank, on_delete=models.CASCADE, related_name='user_progress')
    is_completed  = models.BooleanField(default=False)
    is_current    = models.BooleanField(default=False, help_text='True if this is the user\'s active rank')
    completed_at  = models.DateTimeField(null=True, blank=True)
    unlocked_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'rank')
        ordering = ['rank__order']


class TestLog(models.Model):
    """Detailed log of a single test attempt."""
    user         = models.ForeignKey(User, on_delete=models.CASCADE, related_name='test_logs')
    lesson       = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='test_logs')
    rank         = models.ForeignKey(Rank, on_delete=models.SET_NULL, null=True, blank=True,
                                     related_name='test_logs')
    # Stats
    total        = models.PositiveIntegerField(default=0)
    correct      = models.PositiveIntegerField(default=0)
    wrong        = models.PositiveIntegerField(default=0)
    timed_out    = models.PositiveIntegerField(default=0)
    score_pct    = models.FloatField(default=0.0)
    # Timer info
    time_taken_seconds = models.PositiveIntegerField(default=0)
    ended_by_timer = models.BooleanField(default=False,
        help_text='True if the overall timer expired before user finished')
    passed       = models.BooleanField(default=False)
    # Per-question detail (JSON list of dicts)
    question_detail = models.JSONField(default=list,
        help_text='[{target, chosen, correct, result: correct|wrong|timeout}]')
    created_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user} | {self.lesson} | {self.score_pct:.0f}% | {'PASS' if self.passed else 'FAIL'}"


class XPConfig(models.Model):
    """XP rewards for completing study or test in a lesson within a rank."""
    rank          = models.ForeignKey(Rank, on_delete=models.CASCADE, related_name='xp_configs')
    lesson        = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='xp_configs')
    study_xp      = models.PositiveIntegerField(default=10,
        help_text='XP awarded for completing the Study mode of this lesson')
    test_xp       = models.PositiveIntegerField(default=50,
        help_text='XP awarded for passing the Test of this lesson')

    class Meta:
        unique_together = ('rank', 'lesson')
        ordering = ['lesson__order']

    def __str__(self):
        return f"{self.rank.name} / {self.lesson.name} — study:{self.study_xp} test:{self.test_xp}"


class DailyRevisionConfig(models.Model):
    """Global config for the daily revision experience."""
    timer_minutes = models.PositiveIntegerField(default=10)
    per_question_xp = models.PositiveIntegerField(default=5)
    overall_completion_xp = models.PositiveIntegerField(default=10)
    streak_count = models.PositiveIntegerField(default=1)
    daily_limit = models.PositiveIntegerField(default=1)
    updated_at = models.DateTimeField(auto_now=True)
    updated_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True,
                                   on_delete=models.SET_NULL, related_name='daily_revision_configs')

    class Meta:
        verbose_name = 'Daily Revision Config'
        verbose_name_plural = 'Daily Revision Configs'

    def __str__(self):
        return f"Daily revision config ({self.timer_minutes}m / {self.daily_limit} attempts/day)"


class DailyRevisionAttempt(models.Model):
    """Tracks each daily revision attempt completed by a user."""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                             related_name='daily_revision_attempts')
    total = models.PositiveIntegerField(default=0)
    correct = models.PositiveIntegerField(default=0)
    wrong = models.PositiveIntegerField(default=0)
    timed_out = models.PositiveIntegerField(default=0)
    score_pct = models.FloatField(default=0.0)
    xp_gained = models.PositiveIntegerField(default=0)
    streak_gained = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user} | {self.correct}/{self.total} | {self.xp_gained} XP"

