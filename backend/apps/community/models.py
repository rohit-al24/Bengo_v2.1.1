from django.db import models
from django.conf import settings

User = settings.AUTH_USER_MODEL


class FriendRequest(models.Model):
    STATUS_CHOICES = [
        ('pending',  'Pending'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
    ]
    from_user  = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_requests')
    to_user    = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_requests')
    status     = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('from_user', 'to_user')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.from_user} → {self.to_user} ({self.status})"


class Friendship(models.Model):
    """A confirmed friendship (bi-directional)."""
    user1      = models.ForeignKey(User, on_delete=models.CASCADE, related_name='friendships_as_user1')
    user2      = models.ForeignKey(User, on_delete=models.CASCADE, related_name='friendships_as_user2')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user1', 'user2')
        ordering = ['-created_at']

    @classmethod
    def get_friends(cls, user):
        from django.db.models import Q
        return cls.objects.filter(Q(user1=user) | Q(user2=user))

    def get_other_user(self, user):
        return self.user2 if self.user1 == user else self.user1

    def __str__(self):
        return f"{self.user1} ↔ {self.user2}"


class VocabHint(models.Model):
    """Community mnemonic hints for vocabulary items."""
    user          = models.ForeignKey(User, on_delete=models.CASCADE, related_name='vocab_hints')
    study_item_id = models.IntegerField(help_text='FK to courses.StudyItem')
    hint_text     = models.TextField()
    likes         = models.PositiveIntegerField(default=0)
    created_at    = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-likes', '-created_at']

    def __str__(self):
        return f"Hint by {self.user} for item {self.study_item_id}"
