from django.db import migrations, models
import django.db.models.deletion
from django.conf import settings


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('ranks', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Certificate',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=200)),
                ('template_file', models.FileField(help_text='PDF or Image file', upload_to='certificates/')),
                ('is_active', models.BooleanField(default=False, help_text='Only one active certificate per rank')),
                ('preview_note', models.TextField(blank=True, help_text='Admin notes')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('rank', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='certificates', to='ranks.rank')),
            ],
            options={
                'ordering': ['-is_active', '-created_at'],
            },
        ),
        migrations.CreateModel(
            name='UserCertificate',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('earned_at', models.DateTimeField(auto_now_add=True)),
                ('certificate', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='user_certificates', to='certificates.certificate')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='certificates', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-earned_at'],
                'unique_together': {('user', 'certificate')},
            },
        ),
    ]
