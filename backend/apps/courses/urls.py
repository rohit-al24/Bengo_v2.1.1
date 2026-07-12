from django.urls import path
from . import views

urlpatterns = [
    # ── Public / User ────────────────────────────────────────────────────
    path('exams/',                          views.ExamListView.as_view(),          name='exam-list'),
    path('exams/<int:pk>/',                 views.ExamDetailView.as_view(),        name='exam-detail'),
    path('exams/<int:pk>/unlock/',          views.UnlockExamView.as_view(),        name='exam-unlock'),
    path('lessons/<int:pk>/study/',         views.LessonStudyView.as_view(),       name='lesson-study'),
    path('lessons/<int:pk>/test/',          views.LessonTestView.as_view(),        name='lesson-test'),
    path('lessons/<int:pk>/submit/',        views.SubmitTestView.as_view(),        name='lesson-submit'),

    # ── Admin – Exams ─────────────────────────────────────────────────────
    path('admin/exams/',                    views.AdminExamView.as_view(),         name='admin-exam-list'),
    path('admin/exams/<int:pk>/',           views.AdminExamDetailView.as_view(),   name='admin-exam-detail'),

    # ── Admin – Categories ────────────────────────────────────────────────
    path('admin/categories/',               views.AdminCategoryView.as_view(),     name='admin-cat-list'),
    path('admin/categories/<int:pk>/',      views.AdminCategoryDetailView.as_view(), name='admin-cat-detail'),

    # ── Admin – Lessons ───────────────────────────────────────────────────
    path('admin/lessons/',                  views.AdminLessonView.as_view(),       name='admin-lesson-list'),
    path('admin/lessons/<int:pk>/',         views.AdminLessonDetailView.as_view(), name='admin-lesson-detail'),

    # ── Admin – Study Import ──────────────────────────────────────────────
    path('admin/lessons/<int:lesson_id>/study-import/', views.AdminStudyImportView.as_view(), name='admin-study-import'),

    # ── Admin – Question Banks ────────────────────────────────────────────
    path('admin/lessons/<int:lesson_id>/banks/',    views.AdminQuestionBankView.as_view(),       name='admin-bank-list'),
    path('admin/banks/<int:pk>/',                   views.AdminQuestionBankDetailView.as_view(),  name='admin-bank-detail'),
    path('admin/banks/<int:bank_id>/import/',       views.AdminBankImportView.as_view(),          name='admin-bank-import'),
    path('admin/study-items/bulk-delete/',          views.AdminStudyItemsBulkDeleteView.as_view(), name='admin-studyitems-bulk-delete'),
]
