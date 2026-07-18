from django.test import TestCase
from .models import Institution


class InstitutionModelTests(TestCase):
    def test_create_institution(self):
        institution = Institution.objects.create(code='ABC123', name='Sample Institute')
        self.assertEqual(str(institution), 'ABC123 - Sample Institute')
