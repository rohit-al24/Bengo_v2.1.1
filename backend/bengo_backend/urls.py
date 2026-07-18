from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/',         include('apps.accounts.urls')),
    path('api/institutions/', include('apps.institutions.urls')),
    path('api/courses/',      include('apps.courses.urls')),
    path('api/progress/',     include('apps.progress.urls')),
    path('api/community/',    include('apps.community.urls')),
    path('api/ranks/',        include('apps.ranks.urls')),
    path('api/certificates/', include('apps.certificates.urls')),
    path('api/teams/', include('apps.teams.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
