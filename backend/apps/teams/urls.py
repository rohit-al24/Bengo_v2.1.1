from rest_framework.routers import DefaultRouter
from django.urls import path, include
from . import views

router = DefaultRouter()
router.register(r'teams', views.TeamRoomViewSet, basename='teamroom')
router.register(r'invites', views.InviteViewSet, basename='teaminvite')

game_actions = views.GameActionViewSet.as_view({'post': 'submit_answer'})

urlpatterns = [
    path('', include(router.urls)),
    path('actions/submit_answer/', game_actions, name='team-submit-answer'),
]
