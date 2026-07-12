from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from .models import User, Role, UserRole, EmailVerification


class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Role
        fields = ['id', 'name', 'description']


class UserSerializer(serializers.ModelSerializer):
    roles = RoleSerializer(many=True, read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name', 'avatar',
            'xp', 'streak_days', 'last_study_date', 'institution',
            'preferred_level', 'learning_goal', 'roles', 'date_joined'
        ]
        read_only_fields = ['id', 'date_joined']


class RegisterSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(required=False, allow_blank=True)
    last_name = serializers.CharField(required=False, allow_blank=True)
    preferred_level = serializers.CharField(required=False, allow_blank=True)
    learning_goal = serializers.CharField(required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=6)
    password2 = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'password2',
            'first_name', 'last_name', 'preferred_level', 'learning_goal',
        ]

    def validate(self, data):
        if data['password'] != data['password2']:
            raise serializers.ValidationError({'password': 'Passwords do not match.'})

        if User.objects.filter(email__iexact=data['email']).exists():
            raise serializers.ValidationError({'email': 'This email is already registered.'})

        if User.objects.filter(username__iexact=data['username']).exists():
            raise serializers.ValidationError({'username': 'That username is already taken.'})

        verified = EmailVerification.objects.filter(
            email__iexact=data['email'], verified=True
        ).order_by('-created_at').first()
        if not verified or verified.is_expired:
            raise serializers.ValidationError({
                'email': 'Please verify your email before completing registration.'
            })
        return data

    def create(self, validated_data):
        validated_data.pop('password2')
        first_name = validated_data.pop('first_name', '')
        last_name = validated_data.pop('last_name', '')
        preferred_level = validated_data.pop('preferred_level', '')
        learning_goal = validated_data.pop('learning_goal', '')

        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=first_name,
            last_name=last_name,
        )
        user.preferred_level = preferred_level
        user.learning_goal = learning_goal
        user.save()

        role, _ = Role.objects.get_or_create(name=Role.USER)
        UserRole.objects.create(user=user, role=role)
        return user


class LoginSerializer(serializers.Serializer):
    email    = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        user = authenticate(username=data['email'], password=data['password'])
        if not user:
            raise serializers.ValidationError('Invalid email or password.')
        if not user.is_active:
            raise serializers.ValidationError('Account is disabled.')
        data['user'] = user
        return data


class UpdateProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'username', 'avatar', 'institution',
            'first_name', 'last_name', 'preferred_level', 'learning_goal',
        ]


class SendEmailVerificationSerializer(serializers.Serializer):
    email = serializers.EmailField()


class VerifyEmailCodeSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=6)


class UsernameAvailabilitySerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
