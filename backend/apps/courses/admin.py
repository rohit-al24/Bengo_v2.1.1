from django.contrib import admin
from .models import Exam, Category, Lesson, StudyItem, QuestionBank, BankQuestion


class StudyItemInline(admin.TabularInline):
    model = StudyItem
    extra = 0


class LessonInline(admin.TabularInline):
    model = Lesson
    extra = 0
    show_change_link = True


class CategoryInline(admin.TabularInline):
    model = Category
    extra = 0
    show_change_link = True


class BankQuestionInline(admin.TabularInline):
    model = BankQuestion
    extra = 0


@admin.register(Exam)
class ExamAdmin(admin.ModelAdmin):
    list_display  = ['level', 'title', 'is_active', 'order', 'created_at']
    list_filter   = ['level', 'is_active']
    search_fields = ['title']
    inlines       = [CategoryInline]


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display  = ['exam', 'title', 'show_type', 'order', 'is_active']
    list_filter   = ['exam', 'show_type', 'is_active']
    inlines       = [LessonInline]


@admin.register(Lesson)
class LessonAdmin(admin.ModelAdmin):
    list_display  = ['name', 'category', 'lesson_type', 'test_source', 'is_active']
    list_filter   = ['lesson_type', 'test_source', 'is_active']
    search_fields = ['name']
    inlines       = [StudyItemInline]


@admin.register(QuestionBank)
class QuestionBankAdmin(admin.ModelAdmin):
    list_display = ['title', 'lesson', 'questions_count', 'is_active']
    inlines      = [BankQuestionInline]
