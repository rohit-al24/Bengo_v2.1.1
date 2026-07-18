from django.urls import path
from . import views

urlpatterns = [
    path('', views.InstitutionListView.as_view(), name='institution-list'),
    path('<int:pk>/', views.InstitutionDetailView.as_view(), name='institution-detail'),
    path('<int:institution_id>/students/', views.InstitutionStudentsView.as_view(), name='institution-students'),
    path('<int:institution_id>/mentors/', views.InstitutionMentorsView.as_view(), name='institution-mentors'),
    path('<int:institution_id>/assignments/', views.MentorAssignmentView.as_view(), name='institution-assignments'),
    path('assignments/<int:pk>/', views.MentorAssignmentDetailView.as_view(), name='mentor-assignment-detail'),
]
