from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase

from .models import DailyRevisionConfig


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
