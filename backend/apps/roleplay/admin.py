from django.contrib import admin
from . import models


@admin.register(models.RolePlayStory)
class RolePlayStoryAdmin(admin.ModelAdmin):
    list_display  = ['id', 'title', 'category', 'exam', 'difficulty', 'is_published', 'created_at']
    list_filter   = ['is_published', 'exam', 'difficulty']
    search_fields = ['title', 'category']


@admin.register(models.RolePlayCharacter)
class RolePlayCharacterAdmin(admin.ModelAdmin):
    list_display  = ['id', 'story', 'name', 'emoji', 'display_order']
    list_filter   = ['story']


@admin.register(models.RolePlayDialogue)
class RolePlayDialogueAdmin(admin.ModelAdmin):
    list_display  = ['id', 'story', 'character', 'display_order', 'japanese', 'emotion']
    list_filter   = ['story', 'emotion']


@admin.register(models.RolePlayRoom)
class RolePlayRoomAdmin(admin.ModelAdmin):
    list_display  = ['id', 'room_code', 'creator', 'story', 'visibility', 'status', 'max_players', 'created_at']
    list_filter   = ['status', 'visibility']


@admin.register(models.RolePlayMember)
class RolePlayMemberAdmin(admin.ModelAdmin):
    list_display  = ['id', 'room', 'user', 'character', 'is_creator', 'score']


@admin.register(models.RolePlayLineResult)
class RolePlayLineResultAdmin(admin.ModelAdmin):
    list_display  = ['id', 'room', 'member', 'dialogue', 'correct', 'score']
