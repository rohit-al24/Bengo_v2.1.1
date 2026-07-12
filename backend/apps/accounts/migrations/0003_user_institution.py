from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0002_user_last_study_date'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='institution',
            field=models.CharField(blank=True, max_length=200, null=True),
        ),
    ]
