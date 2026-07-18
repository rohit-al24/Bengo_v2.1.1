from io import BytesIO

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from django.urls import reverse
from PIL import Image
from rest_framework.test import APIClient, APIRequestFactory

from .models import Announcement
from .serializers import AnnouncementSerializer


class AnnouncementApiTests(TestCase):
    def test_active_announcements_are_listed_for_anyone(self):
        Announcement.objects.create(title='Spring Event', description='Hello', is_active=True)
        Announcement.objects.create(title='Draft Event', description='Hidden', is_active=False)

        client = APIClient()
        response = client.get(reverse('announcement-list'))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.json()), 1)
        self.assertEqual(response.json()[0]['title'], 'Spring Event')

    def test_serializer_returns_absolute_image_url_with_request_context(self):
        buffer = BytesIO()
        Image.new('RGB', (1, 1), color='red').save(buffer, format='PNG')
        uploaded = SimpleUploadedFile('test.png', buffer.getvalue(), content_type='image/png')

        announcement = Announcement.objects.create(title='Image Event', description='Hello')
        announcement.image.save('test.png', uploaded, save=True)

        factory = APIRequestFactory()
        request = factory.get('/')
        serializer = AnnouncementSerializer(announcement, context={'request': request})

        self.assertIn('http', serializer.data['image'])
