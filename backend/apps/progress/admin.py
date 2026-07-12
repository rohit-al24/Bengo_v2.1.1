from django.contrib import admin
from .models import UserExamUnlock, UserLessonProgress


@admin.register(UserExamUnlock)
class UserExamUnlockAdmin(admin.ModelAdmin):
    list_display  = ['user', 'exam', 'unlocked_at']
    list_filter   = ['exam']
    search_fields = ['user__email']


@admin.register(UserLessonProgress)
class UserLessonProgressAdmin(admin.ModelAdmin):
    list_display  = ['user', 'lesson', 'is_completed', 'best_score', 'attempts', 'last_attempt']
    list_filter   = ['is_completed']
    search_fields = ['user__email', 'lesson__name']
