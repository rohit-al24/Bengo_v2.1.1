from django.contrib import admin
from .models import Rank, UserRankProgress, TestLog


@admin.register(Rank)
class RankAdmin(admin.ModelAdmin):
    list_display  = ['exam', 'category', 'name', 'rank_type', 'order',
                     'pass_percentage', 'question_timer_seconds', 'has_overall_timer', 'color']
    list_filter   = ['rank_type', 'exam', 'has_overall_timer']
    search_fields = ['name', 'exam__title']
    ordering      = ['exam', 'order']
    fieldsets = (
        ('Rank Identity', {
            'fields': ('exam', 'category', 'name', 'rank_type', 'order', 'color', 'icon'),
        }),
        ('Pass Requirements', {
            'fields': ('pass_percentage',),
        }),
        ('Timer Settings', {
            'fields': ('question_timer_seconds', 'has_overall_timer', 'overall_timer_seconds'),
        }),
    )


@admin.register(UserRankProgress)
class UserRankProgressAdmin(admin.ModelAdmin):
    list_display  = ['user', 'rank', 'is_current', 'is_completed', 'completed_at']
    list_filter   = ['is_current', 'is_completed']
    search_fields = ['user__email', 'rank__name']


@admin.register(TestLog)
class TestLogAdmin(admin.ModelAdmin):
    list_display  = ['user', 'lesson', 'rank', 'score_pct', 'passed',
                     'correct', 'wrong', 'timed_out', 'ended_by_timer', 'created_at']
    list_filter   = ['passed', 'ended_by_timer']
    search_fields = ['user__email', 'lesson__name']
    readonly_fields = ['score_pct', 'created_at', 'question_detail']
