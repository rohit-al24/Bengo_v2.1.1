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
    
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Your BenGo Verification Code</title>
        <style>
            body {{
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                background-color: #FAF8F5;
                margin: 0;
                padding: 0;
                -webkit-font-smoothing: antialiased;
            }}
            .wrapper {{
                width: 100%;
                background-color: #FAF8F5;
                padding: 40px 0;
            }}
            .container {{
                max-width: 480px;
                margin: 0 auto;
                background-color: #ffffff;
                border-radius: 20px;
                border: 1px solid #EAE5E1;
                box-shadow: 0 8px 24px rgba(0,0,0,0.02);
                overflow: hidden;
            }}
            .header {{
                background-color: #C41230;
                padding: 28px;
                text-align: center;
            }}
            .header h1 {{
                color: #ffffff;
                font-size: 24px;
                margin: 0;
                font-weight: 800;
                letter-spacing: -0.5px;
            }}
            .content {{
                padding: 36px 28px;
                color: #1B1B1D;
                line-height: 1.6;
            }}
            .greeting {{
                font-size: 18px;
                font-weight: 700;
                margin-top: 0;
                margin-bottom: 12px;
                color: #1B1B1D;
            }}
            .intro-text {{
                font-size: 14px;
                color: #555558;
                margin-bottom: 20px;
            }}
            .code-container {{
                background-color: #FDF3F5;
                border: 1.5px solid #EDD5D8;
                border-radius: 14px;
                padding: 20px;
                text-align: center;
                margin: 28px 0;
            }}
            .code-label {{
                font-size: 10px;
                text-transform: uppercase;
                letter-spacing: 1.5px;
                color: #C41230;
                font-weight: 700;
                margin-bottom: 8px;
            }}
            .code-value {{
                font-size: 36px;
                font-weight: 800;
                letter-spacing: 5px;
                color: #C41230;
                font-family: "Courier New", Courier, monospace;
                margin: 0;
            }}
            .info-note {{
                font-size: 12px;
                color: #8A8A8F;
                text-align: center;
                margin-top: 16px;
            }}
            .footer {{
                background-color: #FAF8F5;
                padding: 20px;
                text-align: center;
                border-top: 1px solid #EAE5E1;
                font-size: 11px;
                color: #8A8A8F;
            }}
            .footer p {{
                margin: 4px 0;
            }}
        </style>
    </head>
    <body>
        <div class="wrapper">
            <div class="container">
                <div class="header">
                    <h1>BenGo</h1>
                </div>
                <div class="content">
                    <p class="greeting">Verify your email address</p>
                    <p class="intro-text">Thank you for joining BenGo! Please use the following 6-digit verification code to complete your registration. This code is active for 15 minutes.</p>
                    <div class="code-container">
                        <div class="code-label">Verification Code</div>
                        <div class="code-value">{code}</div>
                    </div>
                    <p class="info-note">If you did not request this code, you can safely ignore this email.</p>
                </div>
                <div class="footer">
                    <p>&copy; {timezone.now().year} BenGo. All rights reserved.</p>
                    <p>Designed to help you master Japanese with ease.</p>
                </div>
            </div>
        </div>
    </body>
    </html>
    """
    
    send_mail(
        subject,
        body,
        None,
        [email],
        fail_silently=False,
        html_message=html_content,
    )


class CheckUsernameView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        username = request.query_params.get('username', '').strip()
        if not username:
            return Response({'username': ['This field is required.']}, status=status.HTTP_400_BAD_REQUEST)
        is_available = not User.objects.filter(username__iexact=username).exists()
        return Response({'available': is_available})


class CheckEmailView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        email = request.query_params.get('email', '').strip()
        if not email:
            return Response({'email': ['This field is required.']}, status=status.HTTP_400_BAD_REQUEST)
        is_available = not User.objects.filter(email__iexact=email).exists()
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


class LogoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        user.last_active = timezone.now() - timedelta(minutes=10)
        user.save(update_fields=['last_active'])
        return Response({'detail': 'Logged out successfully.'})


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


class AdminUserDetailView(APIView):
    """Admin or institutional admin: view, update, delete a user."""

    def get_object(self, user_id):
        try:
            return User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return None

    def get(self, request, user_id):
        user = self.get_object(user_id)
        if user is None:
            return Response({'detail': 'Not found.'}, status=404)
        # only admins or institutional admins of same institution
        if not (request.user.is_admin or (request.user.is_institutional_admin and request.user.institution_id == user.institution_id)):
            return Response({'detail': 'Forbidden.'}, status=403)
        return Response(UserSerializer(user).data)

    def patch(self, request, user_id):
        user = self.get_object(user_id)
        if user is None:
            return Response({'detail': 'Not found.'}, status=404)
        if not (request.user.is_admin or (request.user.is_institutional_admin and request.user.institution_id == user.institution_id)):
            return Response({'detail': 'Forbidden.'}, status=403)

        data = request.data
        allowed = ['username', 'first_name', 'last_name', 'email']
        for k in allowed:
            if k in data:
                setattr(user, k, data.get(k) or getattr(user, k))
        if 'is_approved' in data:
            user.is_approved = bool(data.get('is_approved'))
        if 'is_active' in data:
            user.is_active = bool(data.get('is_active'))
        # institution and registration number can be set by admin
        if 'institution_id' in data and request.user.is_admin:
            try:
                from apps.institutions.models import Institution
                inst = Institution.objects.get(pk=int(data.get('institution_id')))
                user.institution = inst
            except Exception:
                pass
        if 'institutional_registration_number' in data:
            user.institutional_registration_number = data.get('institutional_registration_number')
            try:
                profile, _ = StudentProfile.objects.get_or_create(user=user)
                profile.institutional_registration_number = data.get('institutional_registration_number')
                profile.save()
            except Exception:
                pass

        user.save()
        return Response(UserSerializer(user).data)

    def delete(self, request, user_id):
        user = self.get_object(user_id)
        if user is None:
            return Response({'detail': 'Not found.'}, status=404)
        # only admins can delete users; institutional admins may remove students in their institution
        if not (request.user.is_admin or (request.user.is_institutional_admin and request.user.institution_id == user.institution_id)):
            return Response({'detail': 'Forbidden.'}, status=403)
        user.delete()
        return Response(status=204)


class AdminUserResetPasswordView(APIView):
    """Admin or institutional admin: reset a user's password."""

    def post(self, request, user_id):
        try:
            user = User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)

        if not (request.user.is_admin or (request.user.is_institutional_admin and request.user.institution_id == user.institution_id)):
            return Response({'detail': 'Forbidden.'}, status=403)

        pwd = request.data.get('password')
        generated = False
        if not pwd:
            import random, string
            pwd = ''.join(random.choices(string.ascii_letters + string.digits, k=10))
            generated = True

        user.set_password(pwd)
        user.save()

        payload = {'detail': 'Password reset.'}
        if generated:
            payload['password'] = pwd
        return Response(payload)
