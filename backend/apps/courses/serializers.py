from rest_framework import serializers
from .models import Exam, Category, Lesson, StudyItem, QuestionBank, BankQuestion


class StudyItemSerializer(serializers.ModelSerializer):
    class Meta:
        model  = StudyItem
        fields = [
            'id', 'target', 'correct_answer',
            'wrong_1', 'wrong_2', 'wrong_3', 'wrong_4',
            'exp1', 'exp2', 'exp3', 'exp4', 'exp5', 'exp6',
            'order',
        ]


class BankQuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model  = BankQuestion
        fields = ['id', 'target', 'correct_answer', 'wrong_1', 'wrong_2', 'wrong_3', 'wrong_4']


class QuestionBankSerializer(serializers.ModelSerializer):
    questions_total = serializers.SerializerMethodField()

    class Meta:
        model  = QuestionBank
        fields = ['id', 'title', 'questions_count', 'is_active', 'questions_total', 'created_at']

    def get_questions_total(self, obj):
        return obj.questions.count()


class QuestionBankDetailSerializer(QuestionBankSerializer):
    questions = BankQuestionSerializer(many=True, read_only=True)

    class Meta(QuestionBankSerializer.Meta):
        fields = QuestionBankSerializer.Meta.fields + ['questions']


class LessonSerializer(serializers.ModelSerializer):
    study_items_count = serializers.SerializerMethodField()
    has_active_bank   = serializers.SerializerMethodField()
    is_unlocked       = serializers.SerializerMethodField()
    is_completed      = serializers.SerializerMethodField()
    category_show_type = serializers.CharField(source='category.show_type', read_only=True)
    
    # Dynamic Rank settings
    rank_id = serializers.SerializerMethodField()
    rank_name = serializers.SerializerMethodField()
    assigned_rank_id = serializers.SerializerMethodField()
    assigned_rank_name = serializers.SerializerMethodField()
    is_visible_for_user = serializers.SerializerMethodField()
    question_timer_seconds = serializers.SerializerMethodField()
    has_overall_timer = serializers.SerializerMethodField()
    overall_timer_seconds = serializers.SerializerMethodField()
    pass_percentage = serializers.SerializerMethodField()

    class Meta:
        model  = Lesson
        fields = [
            'id', 'name', 'order', 'lesson_type', 'test_source', 'test_questions_count',
            'is_active', 'study_items_count', 'has_active_bank',
            'is_unlocked', 'is_completed', 'category_show_type',
            'rank_id', 'rank_name', 'assigned_rank_id', 'assigned_rank_name',
            'is_visible_for_user', 'question_timer_seconds',
            'has_overall_timer', 'overall_timer_seconds', 'pass_percentage',
        ]

    def _get_active_rank(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        from apps.ranks.models import UserRankProgress, Rank
        exam = obj.category.exam
        progress = UserRankProgress.objects.filter(
            user=request.user, rank__exam=exam, is_current=True
        ).select_related('rank').first()
        if progress:
            return progress.rank
        # Fallback to the lowest rank (order=1) or first rank of this exam
        first_rank = Rank.objects.filter(exam=exam).order_by('order').first()
        return first_rank

    def get_rank_id(self, obj):
        rank = self._get_active_rank(obj)
        return rank.id if rank else None

    def get_rank_name(self, obj):
        rank = self._get_active_rank(obj)
        return rank.name if rank else None

    def get_assigned_rank_id(self, obj):
        return obj.rank_id if obj.rank_id else None

    def get_assigned_rank_name(self, obj):
        return obj.rank.name if obj.rank else None

    def get_is_visible_for_user(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return obj.rank_id is None
        if not obj.rank_id:
            return True
        active_rank = self._get_active_rank(obj)
        if active_rank and obj.rank_id == active_rank.id:
            return True
        from apps.ranks.models import UserRankProgress
        return UserRankProgress.objects.filter(
            user=request.user,
            rank_id=obj.rank_id,
            is_current=True,
        ).exists()

    def get_question_timer_seconds(self, obj):
        if obj.category and obj.category.question_timer_seconds is not None:
            return obj.category.question_timer_seconds
        rank = self._get_active_rank(obj)
        return rank.question_timer_seconds if rank else 30

    def get_has_overall_timer(self, obj):
        if obj.category:
            return obj.category.has_overall_timer
        rank = self._get_active_rank(obj)
        return rank.has_overall_timer if rank else False

    def get_overall_timer_seconds(self, obj):
        if obj.category and obj.category.overall_timer_seconds is not None:
            return obj.category.overall_timer_seconds
        rank = self._get_active_rank(obj)
        return rank.overall_timer_seconds if rank else 300

    def get_pass_percentage(self, obj):
        rank = self._get_active_rank(obj)
        return rank.pass_percentage if rank else 70

    def get_study_items_count(self, obj):
        return obj.study_items.count()

    def get_has_active_bank(self, obj):
        return obj.question_banks.filter(is_active=True).exists()

    def get_is_unlocked(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        if obj.order == 0:
            return True
        from apps.progress.models import UserLessonProgress
        prev = Lesson.objects.filter(
            category=obj.category, order__lt=obj.order
        ).order_by('-order').first()
        if not prev:
            return True
        return UserLessonProgress.objects.filter(
            user=request.user, lesson=prev, is_completed=True
        ).exists()

    def get_is_completed(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        from apps.progress.models import UserLessonProgress
        return UserLessonProgress.objects.filter(
            user=request.user, lesson=obj, is_completed=True
        ).exists()


class CategorySerializer(serializers.ModelSerializer):
    lessons       = LessonSerializer(many=True, read_only=True)
    lessons_count = serializers.SerializerMethodField()

    class Meta:
        model  = Category
        fields = [
            'id', 'title', 'description', 'icon', 'order',
            'is_active', 'show_type', 'question_timer_seconds',
            'has_overall_timer', 'overall_timer_seconds', 'lessons_count', 'lessons',
        ]

    def get_lessons_count(self, obj):
        return obj.lessons.count()


class ExamSerializer(serializers.ModelSerializer):
    categories_count = serializers.SerializerMethodField()
    is_unlocked      = serializers.SerializerMethodField()

    class Meta:
        model  = Exam
        fields = ['id', 'title', 'description', 'level', 'thumbnail', 'is_active',
                  'order', 'categories_count', 'is_unlocked', 'created_at']

    def get_categories_count(self, obj):
        return obj.categories.count()

    def get_is_unlocked(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        from apps.progress.models import UserExamUnlock
        return UserExamUnlock.objects.filter(user=request.user, exam=obj).exists()


class ExamDetailSerializer(ExamSerializer):
    categories = CategorySerializer(many=True, read_only=True)

    class Meta(ExamSerializer.Meta):
        fields = ExamSerializer.Meta.fields + ['categories']


# ── Admin write serializers ───────────────────────────────────────────────────
class ExamWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Exam
        fields = ['title', 'description', 'level', 'thumbnail', 'is_active', 'order']


class CategoryWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Category
        fields = ['exam', 'title', 'description', 'icon', 'order', 'is_active', 'show_type',
                  'question_timer_seconds', 'has_overall_timer', 'overall_timer_seconds']


class LessonWriteSerializer(serializers.ModelSerializer):
    test_questions_count = serializers.IntegerField(min_value=1, required=False)

    class Meta:
        model  = Lesson
        fields = ['category', 'name', 'order', 'lesson_type', 'test_source', 'test_questions_count', 'rank', 'is_active']


class QuestionBankWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model  = QuestionBank
        fields = ['lesson', 'title', 'questions_count', 'is_active']
