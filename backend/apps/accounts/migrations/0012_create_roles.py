# Generated data migration to create default roles

from django.db import migrations


def create_roles(apps, schema_editor):
    """Create default roles if they don't exist."""
    Role = apps.get_model('accounts', 'Role')
    
    roles_data = [
        ('admin', 'Admin'),
        ('user', 'User'),
        ('institutional_admin', 'Institutional Admin'),
        ('mentor', 'Mentor'),
    ]
    
    for role_name, role_display in roles_data:
        Role.objects.get_or_create(
            name=role_name,
            defaults={'description': f'{role_display} role'}
        )


def delete_roles(apps, schema_editor):
    """Delete roles (reverse operation)."""
    Role = apps.get_model('accounts', 'Role')
    Role.objects.filter(name__in=['admin', 'user', 'institutional_admin', 'mentor']).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0011_user_is_approved'),
    ]

    operations = [
        migrations.RunPython(create_roles, delete_roles),
    ]
