from django.db import migrations, models
import django.db.models.deletion


def migrate_institution_values(apps, schema_editor):
    User = apps.get_model('accounts', 'User')
    Institution = apps.get_model('institutions', 'Institution')
    for user in User.objects.exclude(institution__isnull=True).exclude(institution=''):
        raw = user.institution
        if not raw:
            continue
        try:
            institution = Institution.objects.get(code=str(raw))
        except Institution.DoesNotExist:
            try:
                institution = Institution.objects.get(name__iexact=str(raw))
            except Institution.DoesNotExist:
                institution = None
        if institution:
            user.institution_id = institution.pk
            user.save(update_fields=['institution'])


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0006_user_last_active'),
        ('institutions', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='institutional_registration_number',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
        migrations.RunPython(migrate_institution_values, migrations.RunPython.noop),
        migrations.AlterField(
            model_name='user',
            name='institution',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='users', to='institutions.institution'),
        ),
    ]
