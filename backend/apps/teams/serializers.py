from rest_framework import serializers
from . import models


class TeamMemberSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.TeamMember
        fields = ['id', 'user', 'is_creator', 'score', 'streak', 'knives', 'eliminates']


class TeamInviteSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.TeamInvite
        fields = ['id', 'team', 'from_user', 'to_user', 'status', 'created_at']


class TeamRoomSerializer(serializers.ModelSerializer):
    # Creator is set server-side in the view's perform_create, so mark it read-only
    creator = serializers.PrimaryKeyRelatedField(read_only=True)
    members = TeamMemberSerializer(many=True, read_only=True)
    invites = TeamInviteSerializer(many=True, read_only=True)

    class Meta:
        model = models.TeamRoom
        fields = ['id', 'name', 'creator', 'max_members', 'settings', 'started', 'finished', 'created_at', 'members', 'invites']


class TeamGameLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.TeamGameLog
        fields = ['id', 'team', 'event_type', 'payload', 'created_at']
