from django.db import models
from django.conf import settings


# ── Exam ──────────────────────────────────────────────────────────────────────
class Exam(models.Model):
    title       = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    level       = models.CharField(max_length=10, default='N5')  # N5, N4, N3…
    thumbnail   = models.ImageField(upload_to='exams/', null=True, blank=True)
    is_active   = models.BooleanField(default=True)
    order       = models.PositiveIntegerField(default=0)
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['order', 'created_at']

    def __str__(self):
        return f'{self.level} – {self.title}'


# ── Category ──────────────────────────────────────────────────────────────────
class Category(models.Model):
    # Show mode for all lessons in this category
    FULL_ROW   = 'full_row'
    TOPIC_WISE = 'topic_wise'
    SHOW_CHOICES = [(FULL_ROW, 'Full Row Show'), (TOPIC_WISE, 'Topic Wise Show')]

    exam        = models.ForeignKey(Exam, on_delete=models.CASCADE, related_name='categories')
    title       = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    icon        = models.CharField(max_length=50, blank=True)   # material icon name
    order       = models.PositiveIntegerField(default=0)
    is_active   = models.BooleanField(default=True)
    show_type   = models.CharField(max_length=20, choices=SHOW_CHOICES, default=FULL_ROW,
                                   help_text='How study content is displayed for lessons in this category')
    question_timer_seconds = models.PositiveIntegerField(default=30,
                                                          help_text='Default seconds per question for lessons in this category')
    has_overall_timer = models.BooleanField(default=False,
                                            help_text='Enable an overall test timer for lessons in this category')
    overall_timer_seconds = models.PositiveIntegerField(default=300,
                                                        help_text='Default overall test duration for this category')

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f'{self.exam.level} / {self.title}'


# ── Lesson ────────────────────────────────────────────────────────────────────
class Lesson(models.Model):
    # Types
    STUDY = 'study'
    EXAM  = 'exam'
    TYPE_CHOICES = [(STUDY, 'Study'), (EXAM, 'Exam')]

    # Show types (only for study)
    FULL_ROW   = 'full_row'
    TOPIC_WISE = 'topic_wise'
    SHOW_CHOICES = [(FULL_ROW, 'Full Row Show'), (TOPIC_WISE, 'Topic Wise Show')]

    # Test source types
    FROM_STUDY  = 'from_study'
    CUSTOM_BANK = 'custom_bank'
    TEST_CHOICES = [(FROM_STUDY, 'Take From Study'), (CUSTOM_BANK, 'Custom Question Bank')]

    category        = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='lessons')
    name            = models.CharField(max_length=200)
    order           = models.PositiveIntegerField(default=0)
    lesson_type         = models.CharField(max_length=20, choices=TYPE_CHOICES, default=STUDY)
    test_source         = models.CharField(max_length=20, choices=TEST_CHOICES, default=FROM_STUDY)
    test_questions_count = models.PositiveIntegerField(default=40,
                                        help_text='How many questions to draw for each take-test from all active banks')
    rank                = models.ForeignKey('ranks.Rank', on_delete=models.SET_NULL, null=True, blank=True,
                                        related_name='lessons',
                                        help_text='Leave blank to show this lesson to all ranks')
    is_active           = models.BooleanField(default=True)
    created_at          = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f'{self.category} / {self.name}'


# ── Study Item (imported from Excel) ─────────────────────────────────────────
class StudyItem(models.Model):
    lesson         = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='study_items')
    target         = models.CharField(max_length=500)
    correct_answer = models.CharField(max_length=500, blank=True)
    wrong_1        = models.CharField(max_length=500, blank=True)
    wrong_2        = models.CharField(max_length=500, blank=True)
    wrong_3        = models.CharField(max_length=500, blank=True)
    wrong_4        = models.CharField(max_length=500, blank=True)
    # Topic-wise extra explanation columns (optional)
    exp1           = models.CharField(max_length=1000, blank=True)
    exp2           = models.CharField(max_length=1000, blank=True)
    exp3           = models.CharField(max_length=1000, blank=True)
    exp4           = models.CharField(max_length=1000, blank=True)
    exp5           = models.CharField(max_length=1000, blank=True)
    exp6           = models.CharField(max_length=1000, blank=True)
    order          = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f'{self.target} → {self.correct_answer}'


# ── Question Bank ─────────────────────────────────────────────────────────────
class QuestionBank(models.Model):
    lesson          = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='question_banks')
    title           = models.CharField(max_length=200)
    questions_count = models.PositiveIntegerField(default=40)   # how many to pull for test
    is_active       = models.BooleanField(default=True)
    created_at      = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.lesson.name} / Bank: {self.title}'


class BankQuestion(models.Model):
    bank           = models.ForeignKey(QuestionBank, on_delete=models.CASCADE, related_name='questions')
    target         = models.CharField(max_length=500)
    correct_answer = models.CharField(max_length=500)
    wrong_1        = models.CharField(max_length=500, blank=True)
    wrong_2        = models.CharField(max_length=500, blank=True)
    wrong_3        = models.CharField(max_length=500, blank=True)
    wrong_4        = models.CharField(max_length=500, blank=True)

    def __str__(self):
        return f'{self.target} → {self.correct_answer}'
