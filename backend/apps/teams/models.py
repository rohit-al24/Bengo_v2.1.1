from django.conf import settings
from django.db import models


class TeamRoom(models.Model):
    name = models.CharField(max_length=128)
    creator = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='created_teams')
    max_members = models.PositiveSmallIntegerField(default=4)
    settings = models.JSONField(default=dict, blank=True)
    started = models.BooleanField(default=False)
    finished = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"TeamRoom({self.id}) {self.name}"


class TeamMember(models.Model):
    team = models.ForeignKey(TeamRoom, on_delete=models.CASCADE, related_name='members')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='team_memberships')
    is_creator = models.BooleanField(default=False)
    joined_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)
    score = models.IntegerField(default=0)
    streak = models.IntegerField(default=0)
    knives = models.IntegerField(default=0)
    eliminates = models.IntegerField(default=0)

    class Meta:
        unique_together = ('team', 'user')

    def __str__(self):
        return f"Member {self.user_id} @ Team {self.team_id}"


class TeamInvite(models.Model):
    team = models.ForeignKey(TeamRoom, on_delete=models.CASCADE, related_name='invites')
    from_user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sent_team_invites')
    to_user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='received_team_invites')
    STATUS_CHOICES = [('pending', 'Pending'), ('accepted', 'Accepted'), ('rejected', 'Rejected'), ('cancelled', 'Cancelled')]
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('team', 'to_user')

    def __str__(self):
        return f"Invite {self.id} {self.team_id} -> {self.to_user_id} ({self.status})"


class TeamGameLog(models.Model):
    team = models.ForeignKey(TeamRoom, on_delete=models.CASCADE, related_name='logs')
    event_type = models.CharField(max_length=64)
    payload = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Log {self.id} {self.event_type} @ Team {self.team_id}"


class KnifeEvent(models.Model):
    team = models.ForeignKey(TeamRoom, on_delete=models.CASCADE, related_name='knife_events')
    attacker = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='knife_attacks')
    target = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='knife_targets')
    executed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)


class EliminateEvent(models.Model):
    team = models.ForeignKey(TeamRoom, on_delete=models.CASCADE, related_name='eliminate_events')
    attacker = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='eliminate_attacks')
    target = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='eliminate_targets')
    executed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)


class AttackDefense(models.Model):
    event = models.ForeignKey(TeamGameLog, on_delete=models.CASCADE, related_name='defenses')
    defender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='defense_actions')
    used_shield = models.BooleanField(default=False)
    shield_cost = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
