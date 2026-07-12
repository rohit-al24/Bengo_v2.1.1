from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import RankViewSet, UserRankProgressViewSet, TestLogViewSet, XPConfigViewSet

router = DefaultRouter()
router.register('ranks',      RankViewSet,             basename='rank')
router.register('progress',   UserRankProgressViewSet, basename='rank-progress')
router.register('logs',       TestLogViewSet,          basename='test-log')
router.register('xp-configs', XPConfigViewSet,         basename='xp-config')

urlpatterns = [path('', include(router.urls))]

