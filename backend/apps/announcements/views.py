from rest_framework import status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import Role
from .models import Announcement
from .serializers import AnnouncementSerializer


class AnnouncementListCreateView(APIView):
    permission_classes = [AllowAny]
    parser_classes = [MultiPartParser, FormParser]

    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAuthenticated()]
        return [AllowAny()]

    def get(self, request, *args, **kwargs):
        if request.user.is_authenticated and getattr(request.user, 'is_admin', False):
            queryset = Announcement.objects.all()
        else:
            queryset = Announcement.objects.filter(is_active=True)

        serializer = AnnouncementSerializer(queryset, many=True, context={'request': request})
        return Response(serializer.data)

    def post(self, request, *args, **kwargs):
        if not request.user.is_authenticated or not getattr(request.user, 'is_admin', False):
            return Response({'detail': 'Only admins can create announcements.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = AnnouncementSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class AnnouncementDetailView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def patch(self, request, pk, *args, **kwargs):
        if not getattr(request.user, 'is_admin', False):
            return Response({'detail': 'Only admins can update announcements.'}, status=status.HTTP_403_FORBIDDEN)

        try:
            announcement = Announcement.objects.get(pk=pk)
        except Announcement.DoesNotExist:
            return Response({'detail': 'Announcement not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = AnnouncementSerializer(announcement, data=request.data, partial=True, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
