from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.forms import UserChangeForm, UserCreationForm
from django import forms
from .models import User, Role, UserRole


# ── Custom creation form (add user) ──────────────────────────────────────────
class CustomUserCreationForm(UserCreationForm):
    """Adds password + confirm-password when creating a user in admin."""
    class Meta(UserCreationForm.Meta):
        model  = User
        fields = ('email', 'username')


# ── Custom change form (edit user) ────────────────────────────────────────────
class CustomUserChangeForm(UserChangeForm):
    """Uses the standard Django change form which shows the hashed password
    as a read-only field with a link to the 'Set Password' page."""
    class Meta(UserChangeForm.Meta):
        model  = User
        fields = '__all__'


# ── UserAdmin ─────────────────────────────────────────────────────────────────
@admin.register(User)
class UserAdmin(BaseUserAdmin):
    form     = CustomUserChangeForm
    add_form = CustomUserCreationForm

    # Columns in the list view
    list_display   = ['email', 'username', 'xp', 'streak_days', 'is_active', 'is_staff', 'date_joined']
    list_filter    = ['is_active', 'is_staff', 'is_superuser']
    search_fields  = ['email', 'username']
    ordering       = ['-date_joined']
    filter_horizontal = ('groups', 'user_permissions')

    # ── Fieldsets for the EDIT user page ────────────────────────────────────────
    # Inheriting BaseUserAdmin gives us the password widget with
    # "Raw passwords are not stored … You can change the password using
    #  this form." + a link to the dedicated "Set Password" page.
    fieldsets = (
        (None, {
            'fields': ('email', 'username', 'password'),
        }),
        ('Personal Info', {
            'fields': ('first_name', 'last_name', 'avatar'),
        }),
        ('BenGo Stats', {
            'fields': ('xp', 'streak_days'),
        }),
        ('Permissions', {
            'fields': (
                'is_active', 'is_staff', 'is_superuser',
                'groups', 'user_permissions',
            ),
            'classes': ('collapse',),
        }),
        ('Important Dates', {
            'fields': ('last_login', 'date_joined'),
            'classes': ('collapse',),
        }),
    )

    # ── Fieldsets for the ADD user page ─────────────────────────────────────────
    # Shows email, username, password1 (Password), password2 (Confirm Password)
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'username', 'password1', 'password2'),
        }),
        ('BenGo Stats', {
            'classes': ('wide',),
            'fields': ('xp', 'streak_days', 'is_active', 'is_staff'),
        }),
    )


# ── Supporting models ─────────────────────────────────────────────────────────
@admin.register(Role)
class RoleAdmin(admin.ModelAdmin):
    list_display  = ['name', 'description', 'created_at']
    search_fields = ['name']


@admin.register(UserRole)
class UserRoleAdmin(admin.ModelAdmin):
    list_display  = ['user', 'role', 'assigned_at']
    list_filter   = ['role']
    search_fields = ['user__email', 'user__username']
    autocomplete_fields = ['user', 'role']
