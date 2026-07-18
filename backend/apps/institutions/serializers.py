from django.db import transaction
from rest_framework import serializers

from apps.accounts.models import User
from .models import Institution, MentorAssignment


class InstitutionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Institution
        fields = ['id', 'code', 'name', 'is_active', 'created_at']


class InstitutionImportSerializer(serializers.Serializer):
    institutions = serializers.ListField(child=serializers.DictField(), required=True)

    def save(self):
        created = []
        with transaction.atomic():
            for item in self.validated_data['institutions']:
                code = str(item.get('code', '')).strip()
                name = str(item.get('name', '')).strip()
                if not code or not name:
                    continue
                obj, _ = Institution.objects.update_or_create(code=code, defaults={'name': name, 'is_active': True})
                created.append(obj)
        return created


class MentorAssignmentSerializer(serializers.ModelSerializer):
    mentor_name = serializers.CharField(source='mentor.username', read_only=True)
    student_name = serializers.CharField(source='student.username', read_only=True)

    class Meta:
        model = MentorAssignment
        fields = ['id', 'mentor', 'mentor_name', 'student', 'student_name', 'assigned_at']
