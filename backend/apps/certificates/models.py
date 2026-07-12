from django.db import models
from apps.ranks.models import Rank
from apps.courses.models import Exam


class Certificate(models.Model):
    """Certificate template for a rank."""
    rank          = models.ForeignKey(Rank, on_delete=models.CASCADE, related_name='certificates')
    name          = models.CharField(max_length=200)
    template_file = models.FileField(upload_to='certificates/',
                                     help_text='PDF or Image file')
    is_active     = models.BooleanField(default=False,
                                        help_text='Only one active certificate per rank')
    preview_note  = models.TextField(blank=True, help_text='Admin notes')
    created_at    = models.DateTimeField(auto_now_add=True)
    updated_at    = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-is_active', '-created_at']

    def save(self, *args, **kwargs):
        # Enforce: only one active certificate per rank
        if self.is_active:
            Certificate.objects.filter(rank=self.rank, is_active=True).exclude(pk=self.pk).update(is_active=False)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.name} ({'Active' if self.is_active else 'Draft'})"


class UserCertificate(models.Model):
    """Certificate earned by a user."""
    from django.conf import settings
    user        = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                                    related_name='certificates')
    certificate = models.ForeignKey(Certificate, on_delete=models.CASCADE,
                                    related_name='user_certificates')
    earned_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'certificate')
        ordering = ['-earned_at']

    def __str__(self):
        return f"{self.user} — {self.certificate.name}"
