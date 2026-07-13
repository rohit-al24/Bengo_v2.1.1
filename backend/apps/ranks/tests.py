from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase

from .models import DailyRevisionConfig, Rank, UserRankProgress
from apps.courses.models import Exam, Category, Lesson
from apps.progress.models import UserExamUnlock, UserLessonProgress


class DailyRevisionConfigTests(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='admin',
            email='admin@example.com',
            password='secret123',
            is_staff=True,
        )
        self.client.force_authenticate(self.user)

    def test_admin_can_update_daily_revision_config(self):
        url = reverse('test-log-daily-revision-config')
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)

        response = self.client.post(url, {
            'timer_minutes': 15,
            'per_question_xp': 7,
            'overall_completion_xp': 12,
            'streak_count': 2,
            'daily_limit': 2,
        }, format='json')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['timer_minutes'], 15)
        self.assertEqual(response.data['daily_limit'], 2)
        self.assertTrue(DailyRevisionConfig.objects.filter(pk=1).exists())


class RankProgressTests(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='learner',
            email='learner@example.com',
            password='secret123',
        )
        self.client.force_authenticate(self.user)
        self.exam = Exam.objects.create(title='Exam', level='N5')
        self.category = Category.objects.create(exam=self.exam, title='Vocabulary')
        self.rank = Rank.objects.create(exam=self.exam, name='Bronze', order=1)
        self.lesson = Lesson.objects.create(category=self.category, name='Lesson 1', rank=self.rank)
        UserExamUnlock.objects.create(user=self.user, exam=self.exam)
        self.progress = UserRankProgress.objects.create(user=self.user, rank=self.rank, is_current=True)

    def test_rank_reset_action_clears_lesson_progress(self):
        UserLessonProgress.objects.create(user=self.user, lesson=self.lesson, is_completed=True, best_score=100.0, attempts=1)
        url = reverse('rank-progress-reset', kwargs={'pk': self.progress.id})
        response = self.client.post(url)
        self.assertEqual(response.status_code, 200)
        progress = UserLessonProgress.objects.get(user=self.user, lesson=self.lesson)
        self.assertFalse(progress.is_completed)
        self.assertEqual(progress.attempts, 0)
