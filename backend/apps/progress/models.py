from django.db import models
from django.conf import settings
from apps.courses.models import Exam, Lesson


class UserExamUnlock(models.Model):
    """Records which exams a user has unlocked (paid/granted access)."""
    user        = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='exam_unlocks')
    exam        = models.ForeignKey(Exam, on_delete=models.CASCADE, related_name='unlocked_by')
    unlocked_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'exam')

    def __str__(self):
        return f'{self.user.email} unlocked {self.exam}'


class UserLessonProgress(models.Model):
    """Tracks user completion and score per lesson."""
    user        = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='lesson_progress')
    lesson      = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='user_progress')
    is_completed = models.BooleanField(default=False)
    best_score  = models.FloatField(default=0.0)   # percentage 0-100
    attempts    = models.PositiveIntegerField(default=0)
    last_attempt = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ('user', 'lesson')

    def __str__(self):
        return f'{self.user.email} / {self.lesson.name} – {self.best_score}%'
