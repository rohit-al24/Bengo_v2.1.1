from django.utils import timezone
from django.utils.deprecation import MiddlewareMixin
from rest_framework_simplejwt.authentication import JWTAuthentication

class ActiveUserMiddleware(MiddlewareMixin):
    def process_request(self, request):
        if not request.user.is_authenticated:
            try:
                header = request.headers.get('Authorization')
                if header and header.startswith('Bearer '):
                    authenticator = JWTAuthentication()
                    res = authenticator.authenticate(request)
                    if res:
                        request.user = res[0]
            except Exception:
                pass

        if request.user.is_authenticated:
            try:
                request.user.last_active = timezone.now()
                request.user.save(update_fields=['last_active'])
            except Exception:
                pass
