from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import serializers
from .models import Certificate, UserCertificate
from apps.ranks.models import Rank


class CertificateSerializer(serializers.ModelSerializer):
    rank_name  = serializers.CharField(source='rank.name', read_only=True)
    exam_title = serializers.CharField(source='rank.exam.title', read_only=True)
    template_url = serializers.SerializerMethodField()

    class Meta:
        model  = Certificate
        fields = ['id', 'rank', 'rank_name', 'exam_title', 'name',
                  'template_file', 'template_url', 'is_active', 'preview_note', 'created_at']

    def get_template_url(self, obj):
        request = self.context.get('request')
        if obj.template_file and request:
            return request.build_absolute_uri(obj.template_file.url)
        return None


class UserCertificateSerializer(serializers.ModelSerializer):
    certificate = CertificateSerializer(read_only=True)

    class Meta:
        model  = UserCertificate
        fields = ['id', 'certificate', 'earned_at']


class CertificateViewSet(viewsets.ModelViewSet):
    serializer_class   = CertificateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = Certificate.objects.select_related('rank', 'rank__exam').all()
        rank_id = self.request.query_params.get('rank')
        if rank_id:
            qs = qs.filter(rank_id=rank_id)
        return qs

    def get_serializer_context(self):
        return {'request': self.request}

    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        cert = self.get_object()
        cert.is_active = True
        cert.save()  # enforces one-active-per-rank in save()
        return Response({'status': 'activated'})

    @action(detail=True, methods=['post'])
    def deactivate(self, request, pk=None):
        cert = self.get_object()
        cert.is_active = False
        cert.save()
        return Response({'status': 'deactivated'})


class UserCertificateViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class   = UserCertificateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserCertificate.objects.filter(user=self.request.user) \
            .select_related('certificate', 'certificate__rank', 'certificate__rank__exam')

    def get_serializer_context(self):
        return {'request': self.request}
