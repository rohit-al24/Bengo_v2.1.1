from rest_framework.views import APIView
from rest_framework.response import Response
from .models import UserExamUnlock, UserLessonProgress
from rest_framework import serializers


class LessonProgressSerializer(serializers.ModelSerializer):
    lesson_name = serializers.CharField(source='lesson.name', read_only=True)
    lesson_id   = serializers.IntegerField(source='lesson.id',   read_only=True)

    class Meta:
        model  = UserLessonProgress
        fields = ['lesson_id', 'lesson_name', 'is_completed', 'best_score', 'attempts', 'last_attempt']


class ExamUnlockSerializer(serializers.ModelSerializer):
    exam_title = serializers.CharField(source='exam.title', read_only=True)
    exam_id    = serializers.IntegerField(source='exam.id',   read_only=True)

    class Meta:
        model  = UserExamUnlock
        fields = ['exam_id', 'exam_title', 'unlocked_at']


class MyProgressView(APIView):
    def get(self, request):
        unlocks  = UserExamUnlock.objects.filter(user=request.user).select_related('exam')
        progress = UserLessonProgress.objects.filter(user=request.user).select_related('lesson')
        return Response({
            'unlocked_exams':    ExamUnlockSerializer(unlocks, many=True).data,
            'lesson_progress':   LessonProgressSerializer(progress, many=True).data,
            'xp':                request.user.xp,
            'streak_days':       request.user.streak_days,
        })


class UnlockExamStatusView(APIView):
    def get(self, request, pk):
        is_unlocked = UserExamUnlock.objects.filter(user=request.user, exam_id=pk).exists()
        return Response({'exam_id': pk, 'is_unlocked': is_unlocked})
