from datetime import timedelta
from django.utils import timezone
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import FriendRequest, Friendship, VocabHint

User = get_user_model()


class UserMinSerializer(serializers.ModelSerializer):
    is_online = serializers.SerializerMethodField()

    class Meta:
        model  = User
        fields = ['id', 'username', 'email', 'xp', 'streak_days', 'institution', 'avatar_id', 'first_name', 'last_name', 'is_online']

    def get_is_online(self, obj):
        if hasattr(obj, 'last_active') and obj.last_active:
            return obj.last_active >= timezone.now() - timedelta(minutes=5)
        return False


class FriendRequestSerializer(serializers.ModelSerializer):
    from_user = UserMinSerializer(read_only=True)
    to_user   = UserMinSerializer(read_only=True)

    class Meta:
        model  = FriendRequest
        fields = ['id', 'from_user', 'to_user', 'status', 'created_at']


class FriendshipSerializer(serializers.ModelSerializer):
    friend   = serializers.SerializerMethodField()
    is_online = serializers.SerializerMethodField()

    class Meta:
        model  = Friendship
        fields = ['id', 'friend', 'is_online', 'created_at']

    def get_friend(self, obj):
        request = self.context.get('request')
        other = obj.get_other_user(request.user)
        return UserMinSerializer(other, context={'request': request}).data

    def get_is_online(self, obj):
        request = self.context.get('request')
        if request and request.user:
            other = obj.get_other_user(request.user)
            if hasattr(other, 'last_active') and other.last_active:
                return other.last_active >= timezone.now() - timedelta(minutes=5)
        return False


class VocabHintSerializer(serializers.ModelSerializer):
    user = UserMinSerializer(read_only=True)

    class Meta:
        model  = VocabHint
        fields = ['id', 'user', 'study_item_id', 'hint_text', 'likes', 'created_at']
        read_only_fields = ['id', 'user', 'likes', 'created_at']
