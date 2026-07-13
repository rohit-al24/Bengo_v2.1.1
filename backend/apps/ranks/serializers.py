from rest_framework import serializers
from .models import Rank, UserRankProgress, TestLog, XPConfig, DailyRevisionConfig, DailyRevisionAttempt
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
    exam_id    = serializers.IntegerField(source='rank.exam_id', read_only=True)
    exam_title = serializers.CharField(source='rank.exam.title', read_only=True)
    pass_percentage = serializers.IntegerField(source='rank.pass_percentage', read_only=True)
    total_lessons = serializers.SerializerMethodField()
    completed_lessons = serializers.SerializerMethodField()
    progress_pct = serializers.SerializerMethodField()
    has_certificate = serializers.SerializerMethodField()

    class Meta:
        model  = UserRankProgress
        fields = ['id', 'rank', 'rank_name', 'rank_order', 'rank_color', 'rank_icon', 'exam_id', 'exam_title',
                  'pass_percentage', 'total_lessons', 'completed_lessons', 'progress_pct', 'has_certificate',
                  'is_completed', 'is_current', 'completed_at', 'unlocked_at']

    def get_total_lessons(self, obj):
        return obj.rank.lessons.filter(is_active=True).count() if obj.rank else 0

    def get_completed_lessons(self, obj):
        if not obj.rank:
            return 0
        return obj.rank.lessons.filter(is_active=True, user_progress__user=obj.user, user_progress__is_completed=True).count()

    def get_progress_pct(self, obj):
        total = self.get_total_lessons(obj)
        if total == 0:
            return 0.0
        completed = self.get_completed_lessons(obj)
        return round((completed / total) * 100, 2)

    def get_has_certificate(self, obj):
        if not obj.rank:
            return False
        from apps.certificates.models import UserCertificate
        return UserCertificate.objects.filter(user=obj.user, certificate__rank=obj.rank).exists()


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


class DailyRevisionConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyRevisionConfig
        fields = ['timer_minutes', 'per_question_xp', 'overall_completion_xp', 'streak_count', 'daily_limit', 'updated_at']


class DailyRevisionAttemptSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyRevisionAttempt
        fields = ['id', 'total', 'correct', 'wrong', 'timed_out', 'score_pct', 'xp_gained', 'streak_gained', 'created_at']

