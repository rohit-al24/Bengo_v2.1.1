from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ClanGlobalSettingsViewSet, ClanRushScheduleViewSet,
    AdrenalineDuelConfigViewSet, MomentumBarConfigViewSet,
    RewardChestConfigViewSet, RivalSystemConfigViewSet,
    ComebackConfigViewSet, RetentionConfigViewSet,
    ClanViewSet, ClanJoinRequestViewSet,
    ClanRushViewSet, ClanBattleViewSet, AdrenalineDuelResultViewSet,
    RewardChestViewSet, RivalViewSet,
    ClanHistoryViewSet, ClanDashboardStatsView,
    ClanDuelQuestionsView,
)

router = DefaultRouter()

# ── Admin config (singleton) ───────────────────────────────────────────────────
router.register(r'config/global',      ClanGlobalSettingsViewSet,  basename='clan-global-config')
router.register(r'config/rush',        ClanRushScheduleViewSet,    basename='clan-rush-config')
router.register(r'config/duel',        AdrenalineDuelConfigViewSet, basename='clan-duel-config')
router.register(r'config/momentum',    MomentumBarConfigViewSet,   basename='clan-momentum-config')
router.register(r'config/chests',      RewardChestConfigViewSet,   basename='clan-chest-config')
router.register(r'config/rivals',      RivalSystemConfigViewSet,   basename='clan-rival-config')
router.register(r'config/comeback',    ComebackConfigViewSet,      basename='clan-comeback-config')
router.register(r'config/retention',   RetentionConfigViewSet,     basename='clan-retention-config')

# ── Core clan ──────────────────────────────────────────────────────────────────
router.register(r'clans',         ClanViewSet,           basename='clan')
router.register(r'join-requests', ClanJoinRequestViewSet, basename='clan-join-request')

# ── Rush / Battle ──────────────────────────────────────────────────────────────
router.register(r'rushes',        ClanRushViewSet,           basename='clan-rush')
router.register(r'battles',       ClanBattleViewSet,         basename='clan-battle')
router.register(r'duel-results',  AdrenalineDuelResultViewSet, basename='duel-result')

# ── Rewards / Social ───────────────────────────────────────────────────────────
router.register(r'chests',        RewardChestViewSet,   basename='reward-chest')
router.register(r'rivals',        RivalViewSet,         basename='rival')
router.register(r'history',       ClanHistoryViewSet,   basename='clan-history')

urlpatterns = [
    path('', include(router.urls)),
    path('admin/dashboard/', ClanDashboardStatsView.as_view(), name='clan-dashboard-stats'),
    path('duel/questions/',  ClanDuelQuestionsView.as_view(),  name='clan-duel-questions'),
]
