from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('institutions', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='institution',
            name='approval_required',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='institution',
            name='mentor_assign_enabled',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='institution',
            name='mentor_change_enabled',
            field=models.BooleanField(default=False),
        ),
    ]
