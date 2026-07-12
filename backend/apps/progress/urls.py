from django.urls import path
from . import views

urlpatterns = [
    path('my-progress/',         views.MyProgressView.as_view(),    name='my-progress'),
    path('unlock-exam/<int:pk>/', views.UnlockExamStatusView.as_view(), name='unlock-status'),
]
