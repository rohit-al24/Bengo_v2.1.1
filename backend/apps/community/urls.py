from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import FriendRequestViewSet, FriendshipViewSet, UserSearchView, VocabHintViewSet, LeaderboardView

router = DefaultRouter()
router.register('friend-requests', FriendRequestViewSet, basename='friend-request')
router.register('friends',         FriendshipViewSet,    basename='friend')
router.register('hints',           VocabHintViewSet,     basename='hint')

urlpatterns = [
    path('', include(router.urls)),
    path('users/search/', UserSearchView.as_view(), name='user-search'),
    path('leaderboard/', LeaderboardView.as_view(), name='leaderboard'),
]
