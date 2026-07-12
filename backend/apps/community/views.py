from rest_framework import viewsets, status, generics, permissions
from rest_framework.views import APIView
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from django.contrib.auth import get_user_model
from .models import FriendRequest, Friendship, VocabHint
from .serializers import (
    FriendRequestSerializer, FriendshipSerializer,
    VocabHintSerializer, UserMinSerializer,
)

User = get_user_model()



class FriendRequestViewSet(viewsets.ModelViewSet):
    """Send, list, accept or reject friend requests."""
    serializer_class   = FriendRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return FriendRequest.objects.filter(
            Q(from_user=self.request.user) | Q(to_user=self.request.user)
        )

    def create(self, request, *args, **kwargs):
        to_id = request.data.get('to_user_id')
        if not to_id:
            return Response({'error': 'to_user_id required'}, status=400)
        try:
            to_user = User.objects.get(pk=to_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=404)

        if to_user == request.user:
            return Response({'error': 'Cannot add yourself'}, status=400)

        req, created = FriendRequest.objects.get_or_create(
            from_user=request.user, to_user=to_user,
            defaults={'status': 'pending'}
        )
        return Response(FriendRequestSerializer(req).data,
                        status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        freq = self.get_object()
        if freq.to_user != request.user:
            return Response({'error': 'Not yours to accept'}, status=403)
        freq.status = 'accepted'
        freq.save()
        # Create friendship (always store lower-id first to enforce uniqueness)
        u1, u2 = sorted([freq.from_user, freq.to_user], key=lambda u: u.pk)
        Friendship.objects.get_or_create(user1=u1, user2=u2)
        return Response({'status': 'accepted'})

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        freq = self.get_object()
        if freq.to_user != request.user:
            return Response({'error': 'Not yours to reject'}, status=403)
        freq.status = 'rejected'
        freq.save()
        return Response({'status': 'rejected'})

    @action(detail=False, methods=['get'])
    def incoming(self, request):
        qs = FriendRequest.objects.filter(to_user=request.user, status='pending')
        return Response(FriendRequestSerializer(qs, many=True).data)


class FriendshipViewSet(viewsets.ReadOnlyModelViewSet):
    """List my confirmed friends."""
    serializer_class   = FriendshipSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Friendship.get_friends(self.request.user)

    def get_serializer_context(self):
        return {'request': self.request}

    @action(detail=False, methods=['delete'])
    def remove(self, request):
        friend_id = request.data.get('friend_id')
        try:
            friend = User.objects.get(pk=friend_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=404)
        u1, u2 = sorted([request.user, friend], key=lambda u: u.pk)
        Friendship.objects.filter(user1=u1, user2=u2).delete()
        return Response({'status': 'removed'})


class UserSearchView(generics.ListAPIView):
    """Search users by username for friend discovery."""
    serializer_class   = UserMinSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        q = self.request.query_params.get('q', '')
        if not q:
            return User.objects.none()
        return User.objects.filter(username__icontains=q).exclude(pk=self.request.user.pk)[:20]


class VocabHintViewSet(viewsets.ModelViewSet):
    """CRUD for community vocabulary hints."""
    serializer_class   = VocabHintSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        friendships = Friendship.objects.filter(Q(user1=user) | Q(user2=user))
        friend_ids = set()
        for f in friendships:
            friend_ids.add(f.user2_id if f.user1_id == user.id else f.user1_id)
        friend_ids.add(user.id)

        qs = VocabHint.objects.filter(user_id__in=friend_ids).select_related('user')
        item_id = self.request.query_params.get('study_item_id')
        if item_id:
            qs = qs.filter(study_item_id=item_id)
        return qs

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def like(self, request, pk=None):
        hint = self.get_object()
        hint.likes += 1
        hint.save(update_fields=['likes'])
        return Response({'likes': hint.likes})


class LeaderboardView(APIView):
    """API endpoint to get real leaderboard rankings for Friends vs Institution."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        board_type = request.query_params.get('type', 'friends')
        user = request.user

        if board_type == 'institution':
            inst = user.institution
            if not inst:
                users = User.objects.none()
            else:
                users = User.objects.filter(institution__iexact=inst).order_by('-xp')
        else:
            # Friends leaderboard
            friendships = Friendship.get_friends(user)
            friend_ids = set()
            for f in friendships:
                friend_ids.add(f.user2_id if f.user1_id == user.id else f.user1_id)
            friend_ids.add(user.id)
            
            users = User.objects.filter(id__in=friend_ids).order_by('-xp')

        # Serialize list of users sorted by XP descending
        serializer = UserMinSerializer(users, many=True)
        return Response(serializer.data)
