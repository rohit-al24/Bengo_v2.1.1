from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0008_alter_role_name'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='daily_revision_completed_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
