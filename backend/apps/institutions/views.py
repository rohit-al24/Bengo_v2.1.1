from django.db.models import Q
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import Role, User, UserRole
from .models import Institution, MentorAssignment
from .serializers import InstitutionImportSerializer, InstitutionSerializer, MentorAssignmentSerializer


class InstitutionListView(APIView):
    def get_permissions(self):
        if self.request.method == 'GET':
            return [AllowAny()]
        return [IsAuthenticated()]

    def get(self, request):
        qs = Institution.objects.filter(is_active=True)
        q = request.query_params.get('search', '').strip()
        if q:
            qs = qs.filter(Q(code__icontains=q) | Q(name__icontains=q))
        return Response(InstitutionSerializer(qs.order_by('name'), many=True).data)

    def post(self, request):
        if not request.user.is_admin:
            return Response({'detail': 'Forbidden.'}, status=403)
        if isinstance(request.data, list):
            payload = {'institutions': request.data}
        else:
            payload = request.data
        serializer = InstitutionImportSerializer(data=payload)
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)
        created = serializer.save()
        return Response({'created': len(created)}, status=201)


class InstitutionDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            institution = Institution.objects.get(pk=pk)
        except Institution.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)
        return Response(InstitutionSerializer(institution).data)

    def patch(self, request, pk):
        try:
            institution = Institution.objects.get(pk=pk)
        except Institution.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)

        if not (request.user.is_admin or (request.user.is_institutional_admin and request.user.institution_id == institution.id)):
            return Response({'detail': 'Forbidden.'}, status=403)

        data = request.data
        if 'name' in data:
            institution.name = data.get('name') or institution.name
        if 'is_active' in data:
            institution.is_active = bool(data.get('is_active'))
        if 'approval_required' in data:
            institution.approval_required = bool(data.get('approval_required'))
        if 'mentor_assign_enabled' in data:
            institution.mentor_assign_enabled = bool(data.get('mentor_assign_enabled'))
        if 'mentor_change_enabled' in data:
            institution.mentor_change_enabled = bool(data.get('mentor_change_enabled'))
        institution.save()
        return Response(InstitutionSerializer(institution).data)


class InstitutionStudentsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, institution_id):
        try:
            institution = Institution.objects.get(pk=institution_id)
        except Institution.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)

        if not (request.user.is_admin or (request.user.is_institutional_admin and request.user.institution_id == institution.id)):
            return Response({'detail': 'Forbidden.'}, status=403)

        users = User.objects.filter(institution=institution).select_related('institution').prefetch_related('roles').order_by('username')
        payload = []
        for user in users:
            payload.append({
                'id': user.id,
                'username': user.username,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'email': user.email,
                'institutional_registration_number': user.institutional_registration_number,
                'is_approved': user.is_approved,
                'is_active': user.is_active,
                'roles': [role.name for role in user.roles.all()],
            })
        return Response(payload)


class InstitutionMentorsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, institution_id):
        try:
            institution = Institution.objects.get(pk=institution_id)
        except Institution.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)

        if not (request.user.is_admin or (request.user.is_institutional_admin and request.user.institution_id == institution.id)):
            return Response({'detail': 'Forbidden.'}, status=403)

        role = Role.objects.filter(name=Role.MENTOR).first()
        if role is None:
            return Response([])
        users = User.objects.filter(institution=institution, roles=role).order_by('username')
        return Response([{'id': user.id, 'username': user.username, 'email': user.email} for user in users])


class MentorAssignmentView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, institution_id):
        try:
            institution = Institution.objects.get(pk=institution_id)
        except Institution.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)

        if not (request.user.is_admin or (request.user.is_institutional_admin and request.user.institution_id == institution.id)):
            return Response({'detail': 'Forbidden.'}, status=403)

        assignments = MentorAssignment.objects.filter(institution=institution).select_related('mentor', 'student').order_by('assigned_at')
        return Response(MentorAssignmentSerializer(assignments, many=True).data)

    def post(self, request, institution_id):
        student_id = request.data.get('student_id')
        mentor_id = request.data.get('mentor_id')
        if not student_id or not mentor_id:
            return Response({'detail': 'student_id and mentor_id are required.'}, status=400)

        try:
            student = User.objects.get(pk=student_id)
            mentor = User.objects.get(pk=mentor_id)
        except User.DoesNotExist:
            return Response({'detail': 'Student or mentor not found.'}, status=404)

        if student.institution_id != institution_id or mentor.institution_id != institution_id:
            return Response({'detail': 'Mentor and student must belong to the same institution.'}, status=400)

        try:
            institution = Institution.objects.get(pk=institution_id)
        except Institution.DoesNotExist:
            return Response({'detail': 'Institution not found.'}, status=404)

        allowed = request.user.is_admin or (request.user.is_institutional_admin and request.user.institution_id == institution_id)
        if not allowed:
            if request.user.id != student.id:
                return Response({'detail': 'Forbidden.'}, status=403)
            if student.institution_id != institution_id:
                return Response({'detail': 'Forbidden.'}, status=403)
            current_assignment = MentorAssignment.objects.filter(student=student).order_by('-assigned_at').first()
            if current_assignment is None and not institution.mentor_assign_enabled:
                return Response({'detail': 'Mentor self-assignment is disabled.'}, status=403)
            if current_assignment is not None and not institution.mentor_change_enabled:
                return Response({'detail': 'Mentor changes are disabled.'}, status=403)

        role = Role.objects.get_or_create(name=Role.MENTOR)[0]
        UserRole.objects.get_or_create(user=mentor, role=role)

        assignment, created = MentorAssignment.objects.get_or_create(
            institution_id=institution_id,
            mentor=mentor,
            student=student,
        )
        return Response(MentorAssignmentSerializer(assignment).data, status=201 if created else 200)


class MentorAssignmentDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        try:
            assignment = MentorAssignment.objects.get(pk=pk)
        except MentorAssignment.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)

        if not (request.user.is_admin or (request.user.is_institutional_admin and request.user.institution_id == assignment.institution_id)):
            return Response({'detail': 'Forbidden.'}, status=403)

        assignment.delete()
        return Response(status=204)
