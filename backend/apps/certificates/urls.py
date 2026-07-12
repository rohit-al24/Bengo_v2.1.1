from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CertificateViewSet, UserCertificateViewSet

router = DefaultRouter()
router.register('templates', CertificateViewSet,     basename='certificate')
router.register('mine',      UserCertificateViewSet, basename='my-certificate')

urlpatterns = [path('', include(router.urls))]
