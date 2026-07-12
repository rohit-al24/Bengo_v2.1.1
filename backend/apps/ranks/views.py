from django.utils import timezone
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Rank, UserRankProgress, TestLog, XPConfig
from .serializers import (RankSerializer, UserRankProgressSerializer,
                           TestLogSerializer, XPConfigSerializer)
from apps.courses.models import Lesson, Category
from apps.progress.models import UserLessonProgress


class RankViewSet(viewsets.ModelViewSet):
    """CRUD for ranks (admin writes, all authenticated reads)."""
    serializer_class   = RankSerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset           = Rank.objects.select_related('exam', 'category').all()

    def get_queryset(self):
        qs = super().get_queryset()
        exam_id = self.request.query_params.get('exam')
        if exam_id:
            qs = qs.filter(exam_id=exam_id)
        return qs


class UserRankProgressViewSet(viewsets.ReadOnlyModelViewSet):
    """Read user's rank progress. Supports upgrades."""
    serializer_class   = UserRankProgressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserRankProgress.objects.filter(user=self.request.user) \
            .select_related('rank', 'rank__exam')

    @action(detail=False, methods=['post'])
    def upgrade(self, request):
        """Attempt to move to the next rank for an exam."""
        rank_id = request.data.get('rank_id')
        try:
            current_rank = Rank.objects.get(pk=rank_id)
        except Rank.DoesNotExist:
            return Response({'error': 'Rank not found'}, status=404)

        # Check the user has completed current rank
        progress = UserRankProgress.objects.filter(
            user=request.user, rank=current_rank, is_completed=True
        ).first()
        if not progress:
            return Response({'error': 'Current rank not yet completed'}, status=400)

        # Find next rank
        next_rank = Rank.objects.filter(
            exam=current_rank.exam, order__gt=current_rank.order
        ).order_by('order').first()

        if not next_rank:
            return Response({'error': 'Already at highest rank'}, status=400)

        # Unlock next rank
        next_progress, _ = UserRankProgress.objects.get_or_create(
            user=request.user, rank=next_rank,
            defaults={'is_current': True}
        )
        # Mark old rank as not current
        UserRankProgress.objects.filter(
            user=request.user, rank=current_rank
        ).update(is_current=False)
        next_progress.is_current = True
        next_progress.save()

        return Response(UserRankProgressSerializer(next_progress).data)


def _mark_rank_progress_for_lesson(user, lesson, rank, passed):
    if not rank or not passed:
        return None

    progress, _ = UserRankProgress.objects.get_or_create(user=user, rank=rank)
    progress.is_current = True
    progress.save(update_fields=['is_current'])

    UserRankProgress.objects.filter(
        user=user,
        rank__exam=rank.exam,
    ).exclude(pk=progress.pk).update(is_current=False)

    if not progress.is_completed:
        lessons_for_rank = Lesson.objects.filter(rank=rank, is_active=True)
        completed_lessons = UserLessonProgress.objects.filter(
            user=user,
            lesson__in=lessons_for_rank,
            is_completed=True,
        ).count()
        if lessons_for_rank.exists() and completed_lessons >= lessons_for_rank.count():
            progress.is_completed = True
            progress.completed_at = timezone.now()
            progress.save(update_fields=['is_completed', 'completed_at'])

    return progress


class TestLogViewSet(viewsets.ModelViewSet):
    """Submit and retrieve test logs."""
    serializer_class   = TestLogSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return TestLog.objects.filter(user=self.request.user).select_related('lesson', 'rank')

    def create(self, request, *args, **kwargs):
        data = request.data
        lesson_id = data.get('lesson')
        rank_id   = data.get('rank')

        try:
            lesson = Lesson.objects.get(pk=lesson_id)
        except Lesson.DoesNotExist:
            return Response({'error': 'Lesson not found'}, status=404)

        rank = None
        if rank_id:
            try:
                rank = Rank.objects.get(pk=rank_id)
            except Rank.DoesNotExist:
                pass
        if rank is None and lesson.rank_id:
            rank = lesson.rank

        total     = int(data.get('total',     0))
        correct   = int(data.get('correct',   0))
        wrong     = int(data.get('wrong',     0))
        timed_out = int(data.get('timed_out', 0))
        score_pct = (correct / total * 100) if total > 0 else 0.0
        ended_by_timer = bool(data.get('ended_by_timer', False))

        pass_pct = rank.pass_percentage if rank else 70
        passed   = (score_pct >= pass_pct) and (not ended_by_timer)

        log = TestLog.objects.create(
            user       = request.user,
            lesson     = lesson,
            rank       = rank,
            total      = total,
            correct    = correct,
            wrong      = wrong,
            timed_out  = timed_out,
            score_pct  = score_pct,
            time_taken_seconds = int(data.get('time_taken_seconds', 0)),
            ended_by_timer     = ended_by_timer,
            passed             = passed,
            question_detail    = data.get('question_detail', []),
        )

        # Update UserLessonProgress in progress app
        already_completed = False
        try:
            prog, _ = UserLessonProgress.objects.get_or_create(
                user=request.user, lesson=lesson)
            already_completed = bool(prog.is_completed)
            prog.attempts += 1
            if passed:
                prog.is_completed = True
            if score_pct > (prog.best_score or 0):
                prog.best_score = score_pct
            prog.last_attempt = timezone.now()
            prog.save()
        except Exception:
            pass

        if passed:
            _mark_rank_progress_for_lesson(request.user, lesson, rank, passed)

        # Award XP and update streak if passed
        xp_gained = 0
        if passed and not already_completed:
            xp_gained = 50  # default
            if rank:
                try:
                    cfg = XPConfig.objects.get(rank=rank, lesson=lesson)
                    xp_gained = cfg.test_xp
                except XPConfig.DoesNotExist:
                    pass
            request.user.xp += xp_gained
            
            # Update streak
            today = timezone.now().date()
            from datetime import timedelta
            user = request.user
            if user.last_study_date == today - timedelta(days=1):
                user.streak_days = (user.streak_days or 0) + 1
            elif user.last_study_date != today:
                user.streak_days = 1
            user.last_study_date = today
            user.save(update_fields=['xp', 'streak_days', 'last_study_date'])

        # Return serialized log and extra info
        resp_data = TestLogSerializer(log).data
        resp_data['xp_gained'] = xp_gained
        resp_data['total_xp'] = request.user.xp
        resp_data['streak_days'] = request.user.streak_days
        return Response(resp_data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'])
    def study_complete(self, request):
        """Award study XP when a user finishes study mode."""
        lesson_id = request.data.get('lesson')
        rank_id   = request.data.get('rank')
        try:
            lesson = Lesson.objects.get(pk=lesson_id)
        except Lesson.DoesNotExist:
            return Response({'error': 'Lesson not found'}, status=404)

        xp_gained = 10  # default
        if rank_id:
            try:
                cfg = XPConfig.objects.get(rank_id=rank_id, lesson=lesson)
                xp_gained = cfg.study_xp
            except XPConfig.DoesNotExist:
                pass

        request.user.xp += xp_gained
        # Update streak
        today = timezone.now().date()
        from datetime import timedelta
        user  = request.user
        if user.last_study_date == today - timedelta(days=1):
            user.streak_days = (user.streak_days or 0) + 1
        elif user.last_study_date != today:
            user.streak_days = 1
        user.last_study_date = today
        user.save(update_fields=['xp', 'streak_days', 'last_study_date'])

        return Response({'xp_gained': xp_gained, 'total_xp': user.xp,
                         'streak_days': user.streak_days})

    @action(detail=False, methods=['get'])
    def last(self, request):
        """Get the most recent log for a lesson."""
        lesson_id = request.query_params.get('lesson')
        if not lesson_id:
            return Response({'error': 'lesson param required'}, status=400)
        log = TestLog.objects.filter(user=request.user, lesson_id=lesson_id).first()
        if not log:
            return Response(None)
        return Response(TestLogSerializer(log).data)


class XPConfigViewSet(viewsets.ModelViewSet):
    """Manage XP rewards per lesson per rank."""
    serializer_class   = XPConfigSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = XPConfig.objects.select_related('rank', 'lesson', 'lesson__category').all()
        rank_id = self.request.query_params.get('rank')
        exam_id = self.request.query_params.get('exam')
        if rank_id:
            qs = qs.filter(rank_id=rank_id)
        if exam_id:
            qs = qs.filter(rank__exam_id=exam_id)
        return qs

    def create_or_update_bulk(self, request):
        """Bulk upsert XP configs for a rank."""
        configs = request.data.get('configs', [])
        results = []
        for cfg in configs:
            obj, _ = XPConfig.objects.update_or_create(
                rank_id=cfg['rank'], lesson_id=cfg['lesson'],
                defaults={
                    'study_xp': cfg.get('study_xp', 10),
                    'test_xp':  cfg.get('test_xp',  50),
                }
            )
            results.append(XPConfigSerializer(obj).data)
        return Response(results)
