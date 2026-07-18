from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.models import Role, User
from .models import Announcement


class AnnouncementApiTests(TestCase):
    def test_active_announcements_are_listed_for_anyone(self):
        Announcement.objects.create(title='Spring Event', description='Hello', is_active=True)
        Announcement.objects.create(title='Draft Event', description='Hidden', is_active=False)

        client = APIClient()
        response = client.get(reverse('announcement-list'))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.json()), 1)
        self.assertEqual(response.json()[0]['title'], 'Spring Event')
