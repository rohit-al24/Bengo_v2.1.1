from django.contrib import admin
from . import models


@admin.register(models.TeamRoom)
class TeamRoomAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'creator', 'max_members', 'started', 'finished', 'created_at')


@admin.register(models.TeamMember)
class TeamMemberAdmin(admin.ModelAdmin):
    list_display = ('id', 'team', 'user', 'is_creator', 'score', 'streak')


@admin.register(models.TeamInvite)
class TeamInviteAdmin(admin.ModelAdmin):
    list_display = ('id', 'team', 'from_user', 'to_user', 'status', 'created_at')


@admin.register(models.TeamGameLog)
class TeamGameLogAdmin(admin.ModelAdmin):
    list_display = ('id', 'team', 'event_type', 'created_at')
