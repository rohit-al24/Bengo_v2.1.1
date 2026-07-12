from django.contrib import admin
from .models import Certificate, UserCertificate


@admin.register(Certificate)
class CertificateAdmin(admin.ModelAdmin):
    list_display  = ['name', 'rank', 'is_active', 'created_at']
    list_filter   = ['is_active', 'rank__exam']
    search_fields = ['name', 'rank__name']
    readonly_fields = ['created_at', 'updated_at']
    actions = ['activate_selected', 'deactivate_selected']

    @admin.action(description='Activate selected certificate')
    def activate_selected(self, request, queryset):
        for cert in queryset:
            cert.is_active = True
            cert.save()

    @admin.action(description='Deactivate selected certificates')
    def deactivate_selected(self, request, queryset):
        queryset.update(is_active=False)


@admin.register(UserCertificate)
class UserCertificateAdmin(admin.ModelAdmin):
    list_display  = ['user', 'certificate', 'earned_at']
    search_fields = ['user__email', 'certificate__name']
    readonly_fields = ['earned_at']
