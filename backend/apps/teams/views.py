from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from . import models, serializers


class TeamRoomViewSet(viewsets.ModelViewSet):
    queryset = models.TeamRoom.objects.all().order_by('-created_at')
    serializer_class = serializers.TeamRoomSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        team = serializer.save(creator=self.request.user)
        # add creator as member
        models.TeamMember.objects.create(team=team, user=self.request.user, is_creator=True)

    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        team = self.get_object()
        if team.started:
            return Response({'detail': 'already started'}, status=status.HTTP_400_BAD_REQUEST)
        team.started = True
        team.save()
        models.TeamGameLog.objects.create(team=team, event_type='game_started', payload={'by': request.user.id})
        return Response({'detail': 'started'})

    @action(detail=True, methods=['post'])
    def end(self, request, pk=None):
        team = self.get_object()
        team.finished = True
        team.started = False
        team.save()
        models.TeamGameLog.objects.create(team=team, event_type='game_ended', payload={'by': request.user.id})
        return Response({'detail': 'ended'})


class InviteViewSet(viewsets.ModelViewSet):
    queryset = models.TeamInvite.objects.all().order_by('-created_at')
    serializer_class = serializers.TeamInviteSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        data = request.data.copy()
        data['from_user'] = request.user.id
        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def respond(self, request, pk=None):
        invite = self.get_object()
        action = request.data.get('action')
        if action == 'accept':
            invite.status = 'accepted'
            invite.save()
            # add member
            models.TeamMember.objects.get_or_create(team=invite.team, user=invite.to_user)
            models.TeamGameLog.objects.create(team=invite.team, event_type='invite_accepted', payload={'invite': invite.id})
            return Response({'detail': 'accepted'})
        elif action == 'reject':
            invite.status = 'rejected'
            invite.save()
            return Response({'detail': 'rejected'})
        return Response({'detail': 'unknown action'}, status=status.HTTP_400_BAD_REQUEST)


class GameActionViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['post'])
    def submit_answer(self, request):
        # minimal placeholder: record the answer in logs
        team_id = request.data.get('team')
        question = request.data.get('question')
        answer = request.data.get('answer')
        team = get_object_or_404(models.TeamRoom, pk=team_id)
        models.TeamGameLog.objects.create(team=team, event_type='answer_submitted', payload={'user': request.user.id, 'question': question, 'answer': answer})
        return Response({'detail': 'recorded'})
