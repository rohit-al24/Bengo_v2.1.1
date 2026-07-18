from django.conf import settings
from django.db import models


class Institution(models.Model):
    code = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=255)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f'{self.code} - {self.name}'


class MentorAssignment(models.Model):
    institution = models.ForeignKey(Institution, on_delete=models.CASCADE, related_name='mentor_assignments')
    mentor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='assigned_students')
    student = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='mentor_assignments')
    assigned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('mentor', 'student')
        ordering = ['-assigned_at']

    def __str__(self):
        return f'{self.mentor} -> {self.student}'
