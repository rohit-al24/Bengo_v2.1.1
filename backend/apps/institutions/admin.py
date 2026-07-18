from django.contrib import admin, messages
from django.http import HttpResponse
from django.shortcuts import redirect
from django.urls import path, reverse

from .excel_utils import build_template_bytes, import_institutions_from_excel, import_mentor_assignments_from_excel
from .models import Institution, MentorAssignment


class InstitutionAdmin(admin.ModelAdmin):
    change_list_template = 'admin/institutions/change_list_with_import.html'
    list_display = ('code', 'name', 'is_active', 'created_at')
    search_fields = ('code', 'name')

    def get_urls(self):
        urls = super().get_urls()
        info = (self.model._meta.app_label, self.model._meta.model_name)
        custom_urls = [
            path('import-excel/', self.admin_site.admin_view(self.import_excel_view), name='%s_%s_import_excel' % info),
            path('download-template/', self.admin_site.admin_view(self.download_template_view), name='%s_%s_download_template' % info),
        ]
        return custom_urls + urls

    def changelist_view(self, request, extra_context=None):
        extra_context = extra_context or {}
        extra_context.update({
            'import_url': reverse('admin:institutions_institution_import_excel'),
            'download_url': reverse('admin:institutions_institution_download_template'),
        })
        return super().changelist_view(request, extra_context=extra_context)

    def import_excel_view(self, request):
        if request.method != 'POST':
            return HttpResponse('Method not allowed', status=405)

        if 'excel_file' not in request.FILES:
            messages.error(request, 'Please select an Excel file to import.')
            return redirect(reverse('admin:institutions_institution_changelist'))

        try:
            count = import_institutions_from_excel(request.FILES['excel_file'])
        except Exception as exc:  # pragma: no cover - defensive admin handling
            messages.error(request, f'Import failed: {exc}')
            return redirect(reverse('admin:institutions_institution_changelist'))

        messages.success(request, f'Imported {count} institutions from Excel.')
        return redirect(reverse('admin:institutions_institution_changelist'))

    def download_template_view(self, request):
        template_bytes = build_template_bytes('institutions', ['code', 'name'])
        response = HttpResponse(template_bytes, content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        response['Content-Disposition'] = 'attachment; filename="institution_template.xlsx"'
        return response


class MentorAssignmentAdmin(admin.ModelAdmin):
    change_list_template = 'admin/institutions/change_list_with_import.html'
    list_display = ('institution', 'mentor', 'student', 'assigned_at')
    search_fields = ('institution__code', 'institution__name', 'mentor__username', 'student__username')

    def get_urls(self):
        urls = super().get_urls()
        info = (self.model._meta.app_label, self.model._meta.model_name)
        custom_urls = [
            path('import-excel/', self.admin_site.admin_view(self.import_excel_view), name='%s_%s_import_excel' % info),
            path('download-template/', self.admin_site.admin_view(self.download_template_view), name='%s_%s_download_template' % info),
        ]
        return custom_urls + urls

    def changelist_view(self, request, extra_context=None):
        extra_context = extra_context or {}
        extra_context.update({
            'import_url': reverse('admin:institutions_mentorassignment_import_excel'),
            'download_url': reverse('admin:institutions_mentorassignment_download_template'),
        })
        return super().changelist_view(request, extra_context=extra_context)

    def import_excel_view(self, request):
        if request.method != 'POST':
            return HttpResponse('Method not allowed', status=405)

        if 'excel_file' not in request.FILES:
            messages.error(request, 'Please select an Excel file to import.')
            return redirect(reverse('admin:institutions_mentorassignment_changelist'))

        try:
            count = import_mentor_assignments_from_excel(request.FILES['excel_file'])
        except Exception as exc:  # pragma: no cover - defensive admin handling
            messages.error(request, f'Import failed: {exc}')
            return redirect(reverse('admin:institutions_mentorassignment_changelist'))

        messages.success(request, f'Imported {count} mentor assignments from Excel.')
        return redirect(reverse('admin:institutions_mentorassignment_changelist'))

    def download_template_view(self, request):
        template_bytes = build_template_bytes('mentor_assignments', ['institution_code', 'mentor_username', 'student_username'])
        response = HttpResponse(template_bytes, content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        response['Content-Disposition'] = 'attachment; filename="mentor_assignment_template.xlsx"'
        return response


admin.site.register(Institution, InstitutionAdmin)
admin.site.register(MentorAssignment, MentorAssignmentAdmin)
