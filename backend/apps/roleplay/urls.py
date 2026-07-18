from django.urls import path
from . import views

urlpatterns = [
    # ── Admin ──────────────────────────────────────────────────────────────────
    path('admin/stories/',           views.AdminStoryView.as_view(),         name='rp-admin-stories'),
    path('admin/stories/template/',  views.AdminStoryTemplateView.as_view(), name='rp-admin-template'),
    path('admin/stories/import/',    views.AdminStoryImportView.as_view(),   name='rp-admin-import'),
    path('admin/stories/<int:pk>/',  views.AdminStoryDetailView.as_view(),   name='rp-admin-story-detail'),

    # ── Public stories ─────────────────────────────────────────────────────────
    path('stories/',                 views.PublicStoryListView.as_view(),    name='rp-stories'),
    path('stories/<int:pk>/',        views.PublicStoryDetailView.as_view(),  name='rp-story-detail'),

    # ── Rooms ──────────────────────────────────────────────────────────────────
    path('rooms/',                            views.RoomListCreateView.as_view(),      name='rp-rooms'),
    path('rooms/<str:code>/',                 views.RoomDetailView.as_view(),          name='rp-room-detail'),
    path('rooms/<str:code>/join/',            views.RoomJoinView.as_view(),            name='rp-room-join'),
    path('rooms/<str:code>/spin/',            views.RoomSpinView.as_view(),            name='rp-room-spin'),
    path('rooms/<str:code>/select-character/',views.RoomSelectCharacterView.as_view(), name='rp-room-char'),
    path('rooms/<str:code>/submit-line/',     views.RoomSubmitLineView.as_view(),      name='rp-room-submit'),

    # ── History ────────────────────────────────────────────────────────────────
    path('history/',                 views.MyHistoryView.as_view(),          name='rp-history'),
]
