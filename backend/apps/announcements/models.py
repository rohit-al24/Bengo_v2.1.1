from django.db import models


class Announcement(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    image = models.ImageField(upload_to='announcements/', blank=True, null=True)
    is_active = models.BooleanField(default=True)
    link_enabled = models.BooleanField(default=False)
    link_url = models.URLField(blank=True, null=True)
    button_text = models.CharField(max_length=80, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-is_active', '-created_at']

    def __str__(self):
        return self.title
