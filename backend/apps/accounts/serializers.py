from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from apps.institutions.models import MentorAssignment
from .models import User, Role, UserRole, EmailVerification, StudentProfile


class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Role
        fields = ['id', 'name', 'description']


class UserSerializer(serializers.ModelSerializer):
    roles = RoleSerializer(many=True, read_only=True)
    institution_name = serializers.SerializerMethodField(read_only=True)
    mentor_name = serializers.SerializerMethodField(read_only=True)
    institution_settings = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name', 'avatar',
            'avatar_id', 'xp', 'streak_days', 'last_study_date', 'institution',
            'institution_name', 'institution_settings', 'is_approved',
            'preferred_level', 'learning_goal', 'roles', 'date_joined'
        ]
        read_only_fields = ['id', 'date_joined']

    def get_institution_name(self, obj):
        return obj.institution.name if obj.institution else None

    def get_institution_settings(self, obj):
        if not obj.institution:
            return None
        return {
            'approval_required': obj.institution.approval_required,
            'mentor_assign_enabled': obj.institution.mentor_assign_enabled,
            'mentor_change_enabled': obj.institution.mentor_change_enabled,
        }

    def get_mentor_name(self, obj):
        assignment = MentorAssignment.objects.filter(student=obj).order_by('-assigned_at').select_related('mentor').first()
        return assignment.mentor.username if assignment and assignment.mentor else None


class RegisterSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(required=False, allow_blank=True)
    last_name = serializers.CharField(required=False, allow_blank=True)
    preferred_level = serializers.CharField(required=False, allow_blank=True)
    learning_goal = serializers.CharField(required=False, allow_blank=True)
    avatar_id = serializers.CharField(required=False, allow_blank=True, default='a1')
    institution_id = serializers.IntegerField(required=False, allow_null=True)
    institutional_registration_number = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    password = serializers.CharField(write_only=True, min_length=6)
    password2 = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'password2',
            'first_name', 'last_name', 'preferred_level', 'learning_goal', 'avatar_id',
            'institution_id', 'institutional_registration_number',
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
        avatar_id = validated_data.pop('avatar_id', 'a1')
        institution_id = validated_data.pop('institution_id', None)
        institutional_registration_number = validated_data.pop('institutional_registration_number', None)

        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=first_name,
            last_name=last_name,
        )
        user.preferred_level = preferred_level
        user.learning_goal = learning_goal
        user.avatar_id = avatar_id
        institution = None
        if institution_id:
            from apps.institutions.models import Institution
            try:
                institution = Institution.objects.get(id=institution_id)
                user.institution = institution
            except Institution.DoesNotExist:
                pass
        if institutional_registration_number:
            user.institutional_registration_number = institutional_registration_number
        if institution and institution.approval_required and institutional_registration_number:
            user.is_approved = False
        user.save()

        profile, _ = StudentProfile.objects.get_or_create(user=user)
        if institution_id:
            profile.institution_id = institution_id
        if institutional_registration_number:
            profile.institutional_registration_number = institutional_registration_number
        profile.save()

        role, _ = Role.objects.get_or_create(name=Role.USER)
        UserRole.objects.create(user=user, role=role)
        return user


class LoginSerializer(serializers.Serializer):
    email    = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        identifier = data['email'].strip()
        user = None

        if '@' in identifier:
            try:
                user = User.objects.get(email__iexact=identifier)
            except User.DoesNotExist:
                user = None
        else:
            try:
                user = User.objects.get(username__iexact=identifier)
            except User.DoesNotExist:
                user = None

        if user is not None:
            user = authenticate(username=user.email, password=data['password'])

        if not user:
            raise serializers.ValidationError('Invalid username/email or password.')
        if not user.is_active:
            raise serializers.ValidationError('Account is disabled.')
        data['user'] = user
        return data


class UpdateProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'username', 'avatar', 'avatar_id', 'institution',
            'first_name', 'last_name', 'preferred_level', 'learning_goal',
        ]


class SendEmailVerificationSerializer(serializers.Serializer):
    email = serializers.EmailField()


class VerifyEmailCodeSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=6)


class UsernameAvailabilitySerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
