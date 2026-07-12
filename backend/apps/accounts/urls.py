from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    path('register/',           views.RegisterView.as_view(),        name='auth-register'),
    path('login/',              views.LoginView.as_view(),           name='auth-login'),
    path('me/',                 views.MeView.as_view(),              name='auth-me'),
    path('send-verification-code/', views.SendVerificationCodeView.as_view(), name='auth-send-verification-code'),
    path('verify-email/',       views.VerifyEmailView.as_view(),     name='auth-verify-email'),
    path('check-username/',     views.CheckUsernameView.as_view(),   name='auth-check-username'),
    path('token/refresh/',      TokenRefreshView.as_view(),          name='token-refresh'),
    path('admin/users/',        views.AdminUserListView.as_view(),   name='admin-users'),
    path('admin/users/<int:user_id>/assign-role/', views.AdminAssignRoleView.as_view(), name='admin-assign-role'),
]
