from rest_framework import serializers
from .models import Rank, UserRankProgress, TestLog, XPConfig
from apps.courses.models import Exam, Category, Lesson


class RankSerializer(serializers.ModelSerializer):
    exam_title     = serializers.CharField(source='exam.title', read_only=True)
    category_name  = serializers.CharField(source='category.name', read_only=True, allow_null=True)

    class Meta:
        model  = Rank
        fields = [
            'id', 'exam', 'exam_title', 'category', 'category_name',
            'name', 'rank_type', 'order', 'pass_percentage', 'color', 'icon',
            'question_timer_seconds', 'has_overall_timer', 'overall_timer_seconds',
            'created_at',
        ]


class UserRankProgressSerializer(serializers.ModelSerializer):
    rank_name  = serializers.CharField(source='rank.name', read_only=True)
    rank_order = serializers.IntegerField(source='rank.order', read_only=True)
    rank_color = serializers.CharField(source='rank.color', read_only=True)
    rank_icon  = serializers.CharField(source='rank.icon', read_only=True)

    class Meta:
        model  = UserRankProgress
        fields = ['id', 'rank', 'rank_name', 'rank_order', 'rank_color', 'rank_icon',
                  'is_completed', 'is_current', 'completed_at', 'unlocked_at']


class TestLogSerializer(serializers.ModelSerializer):
    lesson_name = serializers.CharField(source='lesson.name', read_only=True)
    rank_name   = serializers.CharField(source='rank.name', read_only=True, allow_null=True)

    class Meta:
        model  = TestLog
        fields = [
            'id', 'lesson', 'lesson_name', 'rank', 'rank_name',
            'total', 'correct', 'wrong', 'timed_out', 'score_pct',
            'time_taken_seconds', 'ended_by_timer', 'passed',
            'question_detail', 'created_at',
        ]
        read_only_fields = ['id', 'score_pct', 'passed', 'created_at']


class XPConfigSerializer(serializers.ModelSerializer):
    lesson_name    = serializers.CharField(source='lesson.name', read_only=True)
    lesson_order   = serializers.IntegerField(source='lesson.order', read_only=True)
    lesson_type    = serializers.CharField(source='lesson.lesson_type', read_only=True)
    category_name  = serializers.CharField(source='lesson.category.title', read_only=True)

    class Meta:
        model  = XPConfig
        fields = ['id', 'rank', 'lesson', 'lesson_name', 'lesson_order',
                  'lesson_type', 'category_name', 'study_xp', 'test_xp']

