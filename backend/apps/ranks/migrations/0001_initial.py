from django.db import migrations, models
import django.db.models.deletion
import django.db.models.functions.text
from django.conf import settings


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('courses', '0001_initial'),
    ]

    operations = [
        # Rank
        migrations.CreateModel(
            name='Rank',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('name', models.CharField(help_text='E.g. Bronze, Silver, Gold', max_length=100)),
                ('rank_type', models.CharField(
                    choices=[('category', 'Category-Wise'), ('full', 'Full Exam')],
                    default='full', max_length=10)),
                ('order', models.PositiveIntegerField(default=1, help_text='1 = lowest (beginner)')),
                ('pass_percentage', models.PositiveIntegerField(default=70)),
                ('color', models.CharField(default='#CD7F32', max_length=7)),
                ('icon', models.CharField(blank=True, default='🥉', max_length=10)),
                ('question_timer_seconds', models.PositiveIntegerField(default=30)),
                ('has_overall_timer', models.BooleanField(default=False)),
                ('overall_timer_seconds', models.PositiveIntegerField(default=300)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('exam', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    related_name='ranks', to='courses.exam')),
                ('category', models.ForeignKey(blank=True, null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='ranks', to='courses.category')),
            ],
            options={'ordering': ['exam', 'order']},
        ),
        migrations.AlterUniqueTogether(
            name='rank',
            unique_together={('exam', 'order'), ('exam', 'name')},
        ),
        # UserRankProgress
        migrations.CreateModel(
            name='UserRankProgress',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('is_completed', models.BooleanField(default=False)),
                ('is_current', models.BooleanField(default=False)),
                ('completed_at', models.DateTimeField(blank=True, null=True)),
                ('unlocked_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    related_name='rank_progress', to=settings.AUTH_USER_MODEL)),
                ('rank', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    related_name='user_progress', to='ranks.rank')),
            ],
            options={'ordering': ['rank__order']},
        ),
        migrations.AlterUniqueTogether(
            name='userrankprogress',
            unique_together={('user', 'rank')},
        ),
        # TestLog
        migrations.CreateModel(
            name='TestLog',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('total', models.PositiveIntegerField(default=0)),
                ('correct', models.PositiveIntegerField(default=0)),
                ('wrong', models.PositiveIntegerField(default=0)),
                ('timed_out', models.PositiveIntegerField(default=0)),
                ('score_pct', models.FloatField(default=0.0)),
                ('time_taken_seconds', models.PositiveIntegerField(default=0)),
                ('ended_by_timer', models.BooleanField(default=False)),
                ('passed', models.BooleanField(default=False)),
                ('question_detail', models.JSONField(default=list)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    related_name='test_logs', to=settings.AUTH_USER_MODEL)),
                ('lesson', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    related_name='test_logs', to='courses.lesson')),
                ('rank', models.ForeignKey(blank=True, null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='test_logs', to='ranks.rank')),
            ],
            options={'ordering': ['-created_at']},
        ),
        # XPConfig
        migrations.CreateModel(
            name='XPConfig',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('study_xp', models.PositiveIntegerField(default=10)),
                ('test_xp', models.PositiveIntegerField(default=50)),
                ('rank', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    related_name='xp_configs', to='ranks.rank')),
                ('lesson', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    related_name='xp_configs', to='courses.lesson')),
            ],
            options={'ordering': ['lesson__order']},
        ),
        migrations.AlterUniqueTogether(
            name='xpconfig',
            unique_together={('rank', 'lesson')},
        ),
    ]
