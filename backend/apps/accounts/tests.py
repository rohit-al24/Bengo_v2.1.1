from django.test import TestCase

from apps.accounts.models import EmailVerification, StudentProfile
from apps.accounts.serializers import RegisterSerializer
from apps.institutions.models import Institution


class RegisterSerializerTests(TestCase):
    def test_register_serializer_creates_student_profile(self):
        institution = Institution.objects.create(code='TEST-01', name='Test Institution')
        EmailVerification.objects.create(email='newstudent@example.com', code='123456', verified=True)

        data = {
            'username': 'newstudent',
            'email': 'newstudent@example.com',
            'password': 'password123',
            'password2': 'password123',
            'first_name': 'New',
            'last_name': 'Student',
            'institution_id': institution.id,
            'institutional_registration_number': 'REG-001',
            'avatar_id': 'a1',
        }

        serializer = RegisterSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        user = serializer.save()

        self.assertTrue(StudentProfile.objects.filter(user=user).exists())
        profile = user.student_profile
        self.assertEqual(profile.institution, institution)
        self.assertEqual(profile.institutional_registration_number, 'REG-001')
