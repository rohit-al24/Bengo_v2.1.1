from django.conf import settings
from django.db import models
import random
import string


def _room_code():
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))


class RolePlayStory(models.Model):
    DIFFICULTY = [('easy', 'Easy'), ('medium', 'Medium'), ('hard', 'Hard')]
    JLPT       = [('N5', 'N5'), ('N4', 'N4'), ('N3', 'N3'), ('N2', 'N2'), ('N1', 'N1')]

    title       = models.CharField(max_length=200)
    category    = models.CharField(max_length=100, blank=True, default='')
    exam        = models.ForeignKey('courses.Exam', on_delete=models.SET_NULL, null=True, blank=True, related_name='roleplay_stories')
    difficulty  = models.CharField(max_length=10, choices=DIFFICULTY, default='easy')
    cover_emoji = models.CharField(max_length=8, default='📖')
    is_published= models.BooleanField(default=True)
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title


class RolePlayCharacter(models.Model):
    story         = models.ForeignKey(RolePlayStory, on_delete=models.CASCADE, related_name='characters')
    name          = models.CharField(max_length=100)
    emoji         = models.CharField(max_length=8, default='👤')
    display_order = models.PositiveSmallIntegerField(default=1)

    class Meta:
        ordering = ['display_order']

    def __str__(self):
        return f"{self.story.title} — {self.name}"


class RolePlayDialogue(models.Model):
    EMOTIONS = [
        ('happy', 'Happy'), ('sad', 'Sad'), ('angry', 'Angry'),
        ('polite', 'Polite'), ('neutral', 'Neutral'), ('serious', 'Serious'),
        ('excited', 'Excited'),
    ]

    story         = models.ForeignKey(RolePlayStory, on_delete=models.CASCADE, related_name='dialogues')
    character     = models.ForeignKey(RolePlayCharacter, on_delete=models.CASCADE, related_name='dialogues')
    display_order = models.PositiveSmallIntegerField(default=1)
    japanese      = models.TextField()
    romaji        = models.TextField(blank=True, default='')
    english       = models.TextField(blank=True, default='')
    emotion       = models.CharField(max_length=20, choices=EMOTIONS, default='neutral')
    pause_ms      = models.PositiveIntegerField(default=1000)

    class Meta:
        ordering = ['display_order']

    def __str__(self):
        return f"{self.story.title}:{self.display_order} — {self.japanese[:30]}"


class RolePlayRoom(models.Model):
    VISIBILITY = [('public', 'Public'), ('friends', 'Friends'), ('private', 'Private')]
    STATUS     = [('waiting', 'Waiting'), ('active', 'Active'), ('finished', 'Finished')]

    creator     = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='created_rp_rooms')
    story       = models.ForeignKey(RolePlayStory, on_delete=models.SET_NULL, null=True, blank=True, related_name='rooms')
    room_code   = models.CharField(max_length=6, unique=True, default=_room_code)
    visibility  = models.CharField(max_length=10, choices=VISIBILITY, default='public')
    max_players = models.PositiveSmallIntegerField(default=4)
    status      = models.CharField(max_length=10, choices=STATUS, default='waiting')
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"RolePlayRoom({self.room_code}) status={self.status}"


class RolePlayMember(models.Model):
    room      = models.ForeignKey(RolePlayRoom, on_delete=models.CASCADE, related_name='members')
    user      = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='rp_memberships')
    character = models.ForeignKey(RolePlayCharacter, on_delete=models.SET_NULL, null=True, blank=True, related_name='members')
    is_creator= models.BooleanField(default=False)
    score     = models.FloatField(default=0.0)
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('room', 'user')

    def __str__(self):
        return f"Member {self.user_id} @ Room {self.room.room_code}"


class RolePlayLineResult(models.Model):
    room      = models.ForeignKey(RolePlayRoom, on_delete=models.CASCADE, related_name='line_results')
    member    = models.ForeignKey(RolePlayMember, on_delete=models.CASCADE, related_name='line_results')
    dialogue  = models.ForeignKey(RolePlayDialogue, on_delete=models.CASCADE, related_name='results')
    correct   = models.BooleanField(default=False)
    score     = models.FloatField(default=0.0)
    created_at= models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']
