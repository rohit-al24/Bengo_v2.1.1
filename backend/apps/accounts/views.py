import random
import string
from datetime import timedelta

from django.core.mail import send_mail
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User, Role, UserRole, EmailVerification
from .serializers import (
    RegisterSerializer, LoginSerializer,
    UserSerializer, UpdateProfileSerializer,
    SendEmailVerificationSerializer, VerifyEmailCodeSerializer,
)


def get_tokens(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access':  str(refresh.access_token),
    }


def _send_email_verification_code(email: str, code: str) -> None:
    subject = 'Your BenGo verification code'
    body = f'Your BenGo verification code is {code}.\n\nUse this code to complete your registration.'
    send_mail(
        subject,
        body,
        None,
        [email],
        fail_silently=False,
    )


class CheckUsernameView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        username = request.query_params.get('username', '').strip()
        if not username:
            return Response({'username': ['This field is required.']}, status=status.HTTP_400_BAD_REQUEST)
        is_available = not User.objects.filter(username__iexact=username).exists()
        return Response({'available': is_available})


class SendVerificationCodeView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = SendEmailVerificationSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            if User.objects.filter(email__iexact=email).exists():
                return Response(
                    {'email': ['Email is already registered.']},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            code = ''.join(random.choices(string.digits, k=6))
            verification = EmailVerification.objects.filter(email__iexact=email).first()
            if verification:
                verification.code = code
                verification.created_at = timezone.now()
                verification.verified = False
                verification.save()
            else:
                verification = EmailVerification.objects.create(
                    email=email,
                    code=code,
                    verified=False,
                )

            _send_email_verification_code(email, code)
            return Response({'detail': 'Verification code sent.'})

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class VerifyEmailView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = VerifyEmailCodeSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            code = serializer.validated_data['code']
            try:
                verification = EmailVerification.objects.get(
                    email__iexact=email,
                    code=code,
                )
            except EmailVerification.DoesNotExist:
                return Response(
                    {'code': ['Invalid verification code.']},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            if verification.is_expired:
                return Response(
                    {'code': ['Verification code has expired.']},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            verification.verified = True
            verification.save()
            return Response({'detail': 'Email verified.'})

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user   = serializer.save()
            tokens = get_tokens(user)
            return Response({
                'user':   UserSerializer(user).data,
                'tokens': tokens,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user   = serializer.validated_data['user']
            tokens = get_tokens(user)
            return Response({
                'user':   UserSerializer(user).data,
                'tokens': tokens,
            })
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class MeView(APIView):
    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UpdateProfileSerializer(
            request.user, data=request.data, partial=True
        )
        if serializer.is_valid():
            serializer.save()
            return Response(UserSerializer(request.user).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class AdminUserListView(APIView):
    """Admin only: list all users."""

    def get(self, request):
        if not request.user.is_admin:
            return Response({'detail': 'Forbidden.'}, status=403)
        users = User.objects.prefetch_related('roles').all()
        return Response(UserSerializer(users, many=True).data)


class AdminAssignRoleView(APIView):
    """Admin only: assign or remove a role from a user."""

    def post(self, request, user_id):
        if not request.user.is_admin:
            return Response({'detail': 'Forbidden.'}, status=403)
        try:
            user = User.objects.get(pk=user_id)
            role = Role.objects.get(name=request.data.get('role'))
            UserRole.objects.get_or_create(user=user, role=role)
            return Response({'detail': f'Role {role.name} assigned.'})
        except (User.DoesNotExist, Role.DoesNotExist) as e:
            return Response({'detail': str(e)}, status=400)
