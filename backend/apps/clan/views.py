from django.db.models import Avg, Count, Sum, Q
from django.utils import timezone
from datetime import timedelta

from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import (
    ClanGlobalSettings, ClanRushSchedule,
    AdrenalineDuelConfig, MomentumBarConfig, RewardChestConfig,
    RivalSystemConfig, ComebackConfig, RetentionConfig,
    Clan, ClanMember, ClanJoinRequest,
    ClanRush, ClanRushContribution,
    ClanBattle, AdrenalineDuelResult,
    RewardChest, Rival, ClanHistory,
)
from .serializers import (
    ClanGlobalSettingsSerializer, ClanRushScheduleSerializer,
    AdrenalineDuelConfigSerializer, MomentumBarConfigSerializer,
    RewardChestConfigSerializer, RivalSystemConfigSerializer,
    ComebackConfigSerializer, RetentionConfigSerializer,
    ClanListSerializer, ClanDetailSerializer,
    ClanMemberSerializer, ClanJoinRequestSerializer,
    ClanRushSerializer, ClanRushSummarySerializer, ClanRushContributionSerializer,
    ClanBattleSerializer, AdrenalineDuelResultSerializer,
    RewardChestSerializer, RivalSerializer,
    ClanHistorySerializer, ClanDashboardStatsSerializer,
)


class IsAdminUser(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_staff)


# ─────────────────────────────────────────────────────────────────────────────
# SINGLETON CONFIG VIEWSETS (admin-only CRUD)
# ─────────────────────────────────────────────────────────────────────────────

class SingletonConfigMixin:
    """Mixin that turns a model-backed ViewSet into a singleton read/update."""

    def get_object(self):
        obj, _ = self.queryset.model.objects.get_or_create(pk=1)
        return obj

    def list(self, request, *args, **kwargs):
        return self.retrieve(request, *args, **kwargs)

    def retrieve(self, request, *args, **kwargs):
        serializer = self.get_serializer(self.get_object())
        return Response(serializer.data)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    def partial_update(self, request, *args, **kwargs):
        kwargs['partial'] = True
        return self.update(request, *args, **kwargs)


class ClanGlobalSettingsViewSet(SingletonConfigMixin, viewsets.ModelViewSet):
    queryset            = ClanGlobalSettings.objects.all()
    serializer_class    = ClanGlobalSettingsSerializer
    permission_classes  = [IsAdminUser]


class ClanRushScheduleViewSet(SingletonConfigMixin, viewsets.ModelViewSet):
    queryset            = ClanRushSchedule.objects.all()
    serializer_class    = ClanRushScheduleSerializer
    permission_classes  = [IsAdminUser]


class AdrenalineDuelConfigViewSet(SingletonConfigMixin, viewsets.ModelViewSet):
    queryset            = AdrenalineDuelConfig.objects.all()
    serializer_class    = AdrenalineDuelConfigSerializer
    permission_classes  = [IsAdminUser]


class MomentumBarConfigViewSet(SingletonConfigMixin, viewsets.ModelViewSet):
    queryset            = MomentumBarConfig.objects.all()
    serializer_class    = MomentumBarConfigSerializer
    permission_classes  = [IsAdminUser]


class RivalSystemConfigViewSet(SingletonConfigMixin, viewsets.ModelViewSet):
    queryset            = RivalSystemConfig.objects.all()
    serializer_class    = RivalSystemConfigSerializer
    permission_classes  = [IsAdminUser]


class ComebackConfigViewSet(SingletonConfigMixin, viewsets.ModelViewSet):
    queryset            = ComebackConfig.objects.all()
    serializer_class    = ComebackConfigSerializer
    permission_classes  = [IsAdminUser]


class RetentionConfigViewSet(SingletonConfigMixin, viewsets.ModelViewSet):
    queryset            = RetentionConfig.objects.all()
    serializer_class    = RetentionConfigSerializer
    permission_classes  = [IsAdminUser]


class RewardChestConfigViewSet(viewsets.ModelViewSet):
    queryset            = RewardChestConfig.objects.all()
    serializer_class    = RewardChestConfigSerializer
    permission_classes  = [IsAdminUser]


# ─────────────────────────────────────────────────────────────────────────────
# CLAN VIEWSET
# ─────────────────────────────────────────────────────────────────────────────

class ClanViewSet(viewsets.ModelViewSet):
    queryset           = Clan.objects.filter(is_active=True).select_related('leader')
    permission_classes = [permissions.IsAuthenticated]
    search_fields      = ['name', 'tag']

    def get_serializer_class(self):
        if self.action in ('list', 'recommended', 'top'):
            return ClanListSerializer
        return ClanDetailSerializer

    # ── Custom actions ─────────────────────────────────────────────────────

    @action(detail=False, methods=['get'])
    def recommended(self, request):
        """Clans matched by the requesting player's trophy count."""
        from apps.accounts.models import User  # local import to avoid circular
        try:
            profile = request.user.profile
            trophies = getattr(profile, 'trophies', 0)
        except Exception:
            trophies = 0
        qs = self.queryset.filter(
            privacy__in=['open', 'invite_only'],
            min_join_trophies__lte=trophies,
        ).order_by('-trophies')[:20]
        return Response(ClanListSerializer(qs, many=True, context={'request': request}).data)

    @action(detail=False, methods=['get'])
    def top(self, request):
        scope = request.query_params.get('scope', 'world')  # world / country / friends
        qs = self.queryset.order_by('-trophies')
        if scope == 'country':
            country = getattr(getattr(request.user, 'profile', None), 'country', None)
            if country:
                qs = qs.filter(members__user__profile__country=country).distinct()
        return Response(ClanListSerializer(qs[:50], many=True, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def join(self, request, pk=None):
        clan = self.get_object()
        user = request.user

        # Already a member?
        if ClanMember.objects.filter(clan=clan, user=user, is_active=True).exists():
            return Response({'detail': 'Already a member.'}, status=status.HTTP_400_BAD_REQUEST)

        # Slots full?
        if clan.member_count >= clan.slots_unlocked:
            return Response({'detail': 'Clan is full.', 'slots_full': True},
                            status=status.HTTP_400_BAD_REQUEST)

        # Trophy check
        user_trophies = getattr(getattr(user, 'profile', None), 'trophies', 0)
        if user_trophies < clan.min_join_trophies:
            return Response({'detail': f'Requires {clan.min_join_trophies}+ trophies.'},
                            status=status.HTTP_400_BAD_REQUEST)

        if clan.privacy == 'open':
            ClanMember.objects.create(clan=clan, user=user, role='member')
            ClanHistory.objects.create(clan=clan, event_type='member_joined',
                                       description=f'{user.username} joined the clan.', actor=user)
            return Response({'detail': 'Joined successfully.'}, status=status.HTTP_201_CREATED)

        elif clan.privacy == 'invite_only':
            obj, created = ClanJoinRequest.objects.get_or_create(clan=clan, user=user)
            if not created:
                return Response({'detail': 'Join request already pending.'})
            return Response({'detail': 'Join request sent.'}, status=status.HTTP_201_CREATED)

        else:  # closed
            return Response({'detail': 'This clan is closed to requests.'},
                            status=status.HTTP_403_FORBIDDEN)

    @action(detail=True, methods=['post'])
    def leave(self, request, pk=None):
        clan = self.get_object()
        membership = ClanMember.objects.filter(clan=clan, user=request.user, is_active=True).first()
        if not membership:
            return Response({'detail': 'Not a member.'}, status=status.HTTP_400_BAD_REQUEST)
        if membership.role == 'leader':
            return Response({'detail': 'Leader must transfer leadership before leaving.'},
                            status=status.HTTP_400_BAD_REQUEST)
        membership.is_active = False
        membership.save()
        ClanHistory.objects.create(clan=clan, event_type='member_left',
                                   description=f'{request.user.username} left the clan.',
                                   actor=request.user)
        return Response({'detail': 'Left the clan.'})

    @action(detail=True, methods=['post'])
    def kick_member(self, request, pk=None):
        clan      = self.get_object()
        target_id = request.data.get('user_id')
        actor_mem = ClanMember.objects.filter(clan=clan, user=request.user, is_active=True).first()
        if not actor_mem or actor_mem.role not in ('leader', 'co_leader'):
            return Response({'detail': 'Insufficient permissions.'}, status=status.HTTP_403_FORBIDDEN)
        target_mem = ClanMember.objects.filter(clan=clan, user_id=target_id, is_active=True).first()
        if not target_mem:
            return Response({'detail': 'Member not found.'}, status=status.HTTP_404_NOT_FOUND)
        if target_mem.role == 'leader':
            return Response({'detail': 'Cannot kick the leader.'}, status=status.HTTP_400_BAD_REQUEST)
        target_mem.is_active = False
        target_mem.save()
        ClanHistory.objects.create(clan=clan, event_type='member_kicked',
                                   description=f'{target_mem.user.username} was kicked.',
                                   actor=request.user)
        return Response({'detail': 'Member kicked.'})

    @action(detail=True, methods=['post'])
    def promote_member(self, request, pk=None):
        clan      = self.get_object()
        target_id = request.data.get('user_id')
        new_role  = request.data.get('role')
        VALID_ROLES = ('co_leader', 'elder', 'member')
        if new_role not in VALID_ROLES:
            return Response({'detail': 'Invalid role.'}, status=status.HTTP_400_BAD_REQUEST)
        actor_mem = ClanMember.objects.filter(clan=clan, user=request.user, is_active=True).first()
        if not actor_mem or actor_mem.role not in ('leader', 'co_leader'):
            return Response({'detail': 'Insufficient permissions.'}, status=status.HTTP_403_FORBIDDEN)
        target_mem = ClanMember.objects.filter(clan=clan, user_id=target_id, is_active=True).first()
        if not target_mem:
            return Response({'detail': 'Member not found.'}, status=status.HTTP_404_NOT_FOUND)
        old_role = target_mem.role
        target_mem.role = new_role
        target_mem.save()
        ClanHistory.objects.create(clan=clan, event_type='role_changed',
                                   description=f'{target_mem.user.username}: {old_role} → {new_role}',
                                   actor=request.user,
                                   metadata={'old_role': old_role, 'new_role': new_role})
        return Response({'detail': 'Role updated.'})

    @action(detail=True, methods=['post'])
    def transfer_leadership(self, request, pk=None):
        clan      = self.get_object()
        target_id = request.data.get('user_id')
        leader_mem = ClanMember.objects.filter(clan=clan, user=request.user, role='leader', is_active=True).first()
        if not leader_mem:
            return Response({'detail': 'Only the Leader can transfer leadership.'}, status=status.HTTP_403_FORBIDDEN)
        target_mem = ClanMember.objects.filter(clan=clan, user_id=target_id, is_active=True).first()
        if not target_mem:
            return Response({'detail': 'Target member not found.'}, status=status.HTTP_404_NOT_FOUND)
        leader_mem.role = 'member'
        leader_mem.save()
        target_mem.role = 'leader'
        target_mem.save()
        clan.leader = target_mem.user
        clan.save(update_fields=['leader'])
        ClanHistory.objects.create(clan=clan, event_type='leadership_transfer',
                                   description=f'Leadership transferred to {target_mem.user.username}.',
                                   actor=request.user)
        return Response({'detail': 'Leadership transferred.'})

    @action(detail=True, methods=['get'])
    def active_rush(self, request, pk=None):
        clan = self.get_object()
        rush = ClanRush.objects.filter(clan=clan, status='active').first()
        if not rush:
            return Response({'active': False})
        return Response({'active': True, 'rush': ClanRushSummarySerializer(rush).data})


# ─────────────────────────────────────────────────────────────────────────────
# JOIN REQUEST VIEWSET
# ─────────────────────────────────────────────────────────────────────────────

class ClanJoinRequestViewSet(viewsets.ModelViewSet):
    queryset           = ClanJoinRequest.objects.select_related('clan', 'user')
    serializer_class   = ClanJoinRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = super().get_queryset()
        clan_id = self.request.query_params.get('clan')
        if clan_id:
            qs = qs.filter(clan_id=clan_id)
        return qs

    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        req = self.get_object()
        clan = req.clan
        if clan.member_count >= clan.slots_unlocked:
            return Response({'detail': 'Clan is full.'}, status=status.HTTP_400_BAD_REQUEST)
        req.status      = 'accepted'
        req.resolved_at = timezone.now()
        req.resolved_by = request.user
        req.save()
        ClanMember.objects.get_or_create(clan=clan, user=req.user, defaults={'role': 'member'})
        ClanHistory.objects.create(clan=clan, event_type='member_joined',
                                   description=f'{req.user.username} joined via invite.',
                                   actor=request.user)
        return Response({'detail': 'Request accepted.'})

    @action(detail=True, methods=['post'])
    def decline(self, request, pk=None):
        req = self.get_object()
        req.status      = 'declined'
        req.resolved_at = timezone.now()
        req.resolved_by = request.user
        req.save()
        return Response({'detail': 'Request declined.'})


# ─────────────────────────────────────────────────────────────────────────────
# CLAN RUSH VIEWSET
# ─────────────────────────────────────────────────────────────────────────────

class ClanRushViewSet(viewsets.ModelViewSet):
    queryset           = ClanRush.objects.select_related('clan')
    serializer_class   = ClanRushSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = super().get_queryset()
        clan_id = self.request.query_params.get('clan')
        if clan_id:
            qs = qs.filter(clan_id=clan_id)
        return qs

    @action(detail=True, methods=['post'])
    def contribute(self, request, pk=None):
        rush   = self.get_object()
        if rush.status != 'active':
            return Response({'detail': 'Rush is not active.'}, status=status.HTTP_400_BAD_REQUEST)
        member = ClanMember.objects.filter(clan=rush.clan, user=request.user, is_active=True).first()
        if not member:
            return Response({'detail': 'Not a clan member.'}, status=status.HTTP_403_FORBIDDEN)
        points = int(request.data.get('points', 0))
        source = request.data.get('source', 'answer')
        ClanRushContribution.objects.create(rush=rush, member=member, points=points, source=source)
        rush.current_points += points
        rush.save(update_fields=['current_points'])
        return Response({'detail': 'Contribution recorded.', 'current_points': rush.current_points,
                         'completion_pct': rush.completion_pct})


# ─────────────────────────────────────────────────────────────────────────────
# BATTLE & DUEL VIEWSETS
# ─────────────────────────────────────────────────────────────────────────────

class ClanBattleViewSet(viewsets.ModelViewSet):
    queryset           = ClanBattle.objects.select_related('player_1', 'player_2', 'winner')
    serializer_class   = ClanBattleSerializer
    permission_classes = [permissions.IsAuthenticated]


class AdrenalineDuelResultViewSet(viewsets.ModelViewSet):
    queryset           = AdrenalineDuelResult.objects.select_related('battle')
    serializer_class   = AdrenalineDuelResultSerializer
    permission_classes = [permissions.IsAuthenticated]


# ─────────────────────────────────────────────────────────────────────────────
# CHEST & RIVAL VIEWSETS
# ─────────────────────────────────────────────────────────────────────────────

class RewardChestViewSet(viewsets.ModelViewSet):
    serializer_class   = RewardChestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return RewardChest.objects.filter(user=self.request.user)

    @action(detail=True, methods=['post'])
    def open(self, request, pk=None):
        chest = self.get_object()
        if chest.opened:
            return Response({'detail': 'Already opened.'}, status=status.HTTP_400_BAD_REQUEST)
        if chest.unlocks_at and chest.unlocks_at > timezone.now():
            return Response({'detail': 'Chest not yet unlocked.'}, status=status.HTTP_400_BAD_REQUEST)
        # Simple random reward calculation (real version would use RewardChestConfig weights)
        import random
        config = RewardChestConfig.objects.filter(tier=chest.tier).first()
        if config:
            chest.coin_reward = random.randint(config.coin_reward_min, config.coin_reward_max)
            chest.xp_reward   = random.randint(config.xp_reward_min, config.xp_reward_max)
        chest.opened    = True
        chest.opened_at = timezone.now()
        chest.save()
        return Response(RewardChestSerializer(chest).data)


class RivalViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class   = RivalSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Rival.objects.filter(user=self.request.user, is_active=True)


# ─────────────────────────────────────────────────────────────────────────────
# CLAN HISTORY VIEWSET
# ─────────────────────────────────────────────────────────────────────────────

class ClanHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class   = ClanHistorySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        clan_id = self.request.query_params.get('clan')
        qs = ClanHistory.objects.all()
        if clan_id:
            qs = qs.filter(clan_id=clan_id)
        return qs


# ─────────────────────────────────────────────────────────────────────────────
# ADMIN DASHBOARD STATS VIEW
# ─────────────────────────────────────────────────────────────────────────────

class ClanDashboardStatsView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)

        rushes_today = ClanRush.objects.filter(created_at__gte=today_start)
        battles_today = ClanBattle.objects.filter(started_at__gte=today_start)
        chests_today = RewardChest.objects.filter(opened=True, opened_at__gte=today_start)

        completed_rushes = rushes_today.filter(status='completed')
        total_rushes = rushes_today.exclude(status='active').count()
        avg_completion = (completed_rushes.count() / total_rushes * 100) if total_rushes else 0.0

        avg_duel_dur = battles_today.aggregate(a=Avg('duration_seconds'))['a'] or 0.0

        data = {
            'active_rushes_now':             ClanRush.objects.filter(status='active').count(),
            'rushes_completed_today':        completed_rushes.count(),
            'avg_rush_completion_rate':      round(avg_completion, 1),
            'overdrive_clashes_today':       AdrenalineDuelResult.objects.filter(
                                                battle__started_at__gte=today_start,
                                                overdrive_triggered=True).count(),
            'active_rivalries':              Rival.objects.filter(is_active=True).count(),
            'chests_opened_today':           chests_today.count(),
            'legendary_chests_opened_today': chests_today.filter(tier='legendary').count(),
            'comeback_activations_today':    AdrenalineDuelResult.objects.filter(
                                                battle__started_at__gte=today_start,
                                                comeback_activated=True).count(),
            'avg_duel_duration_seconds':     round(avg_duel_dur, 1),
            'sabotage_strikes_today':        AdrenalineDuelResult.objects.filter(
                                                battle__started_at__gte=today_start).aggregate(
                                                s=Sum('sabotage_strikes'))['s'] or 0,
            'total_clans':                   Clan.objects.filter(is_active=True).count(),
            'total_clan_members':            ClanMember.objects.filter(is_active=True).count(),
        }
        return Response(ClanDashboardStatsSerializer(data).data)


# ─────────────────────────────────────────────────────────────────────────────
# DUEL QUESTIONS — serves random BankQuestions for a live duel session
# ─────────────────────────────────────────────────────────────────────────────

class ClanDuelQuestionsView(APIView):
    """
    GET /api/clan/duel/questions/?count=20

    Returns `count` randomly-sampled BankQuestion records from all
    active QuestionBanks.  Each record includes 4 shuffled options
    (correct_answer + up to 3 wrong answers) so the client doesn't
    need to know which one is correct before the user answers.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        import random
        from apps.courses.models import BankQuestion, QuestionBank

        try:
            count = int(request.query_params.get('count', 20))
            count = max(1, min(count, 50))   # clamp 1–50
        except (ValueError, TypeError):
            count = 20

        # Pull from all active banks
        active_bank_ids = QuestionBank.objects.filter(
            is_active=True
        ).values_list('id', flat=True)

        if not active_bank_ids:
            return Response([], status=status.HTTP_200_OK)

        # Fetch a pool larger than needed, then sample
        pool = list(
            BankQuestion.objects.filter(
                bank_id__in=active_bank_ids
            ).values(
                'id', 'target', 'correct_answer',
                'wrong_1', 'wrong_2', 'wrong_3', 'wrong_4',
            )
        )

        if not pool:
            return Response([], status=status.HTTP_200_OK)

        sample = random.sample(pool, min(count, len(pool)))

        questions = []
        for q in sample:
            options = [q['correct_answer']]
            for field in ('wrong_1', 'wrong_2', 'wrong_3', 'wrong_4'):
                val = q.get(field, '').strip()
                if val:
                    options.append(val)
            # Always 4 options max, shuffle
            options = options[:4]
            random.shuffle(options)
            questions.append({
                'id':             q['id'],
                'target':         q['target'],
                'correct_answer': q['correct_answer'],
                'options':        options,
            })

        return Response(questions, status=status.HTTP_200_OK)
