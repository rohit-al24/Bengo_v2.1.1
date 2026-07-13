from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone


class Role(models.Model):
    ADMIN = 'admin'
    USER  = 'user'
    ROLE_CHOICES = [(ADMIN, 'Admin'), (USER, 'User')]

    name = models.CharField(max_length=50, unique=True, choices=ROLE_CHOICES)
    description = models.TextField(blank=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class User(AbstractUser):
    email           = models.EmailField(unique=True)
    avatar          = models.ImageField(upload_to='avatars/', null=True, blank=True)
    avatar_id       = models.CharField(max_length=10, default='a1', blank=True)
    xp              = models.IntegerField(default=0)
    streak_days     = models.IntegerField(default=0)
    last_study_date = models.DateField(null=True, blank=True)
    institution     = models.CharField(max_length=200, blank=True, null=True)
    preferred_level = models.CharField(max_length=100, blank=True, null=True)
    learning_goal   = models.CharField(max_length=120, blank=True, null=True)
    roles           = models.ManyToManyField(Role, through='UserRole', related_name='users')


    USERNAME_FIELD  = 'email'
    REQUIRED_FIELDS = ['username']

    def __str__(self):
        return self.email

    @property
    def is_admin(self):
        return self.roles.filter(name=Role.ADMIN).exists()


class UserRole(models.Model):
    user       = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_roles')
    role       = models.ForeignKey(Role, on_delete=models.CASCADE, related_name='user_roles')
    assigned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'role')

    def __str__(self):
        return f'{self.user.email} → {self.role.name}'


class EmailVerification(models.Model):
    email = models.EmailField()
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    verified = models.BooleanField(default=False)

    class Meta:
        verbose_name = 'Email Verification'
        verbose_name_plural = 'Email Verifications'
        indexes = [models.Index(fields=['email'])]

    def __str__(self):
        return f'{self.email} → {self.code}'

    @property
    def is_expired(self):
        from datetime import timedelta
        return self.created_at + timedelta(minutes=30) < timezone.now()
