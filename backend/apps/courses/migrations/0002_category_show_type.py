from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('courses', '0001_initial'),
    ]

    operations = [
        # Add show_type to Category
        migrations.AddField(
            model_name='category',
            name='show_type',
            field=models.CharField(
                choices=[('full_row', 'Full Row Show'), ('topic_wise', 'Topic Wise Show')],
                default='full_row',
                help_text='How study content is displayed for lessons in this category',
                max_length=20,
            ),
        ),
        # Remove show_type from Lesson
        migrations.RemoveField(
            model_name='lesson',
            name='show_type',
        ),
        # Remove pass_percentage from Lesson
        migrations.RemoveField(
            model_name='lesson',
            name='pass_percentage',
        ),
        # Add exp1-exp5 to StudyItem
        migrations.AddField(model_name='studyitem', name='exp1',
            field=models.CharField(blank=True, max_length=1000)),
        migrations.AddField(model_name='studyitem', name='exp2',
            field=models.CharField(blank=True, max_length=1000)),
        migrations.AddField(model_name='studyitem', name='exp3',
            field=models.CharField(blank=True, max_length=1000)),
        migrations.AddField(model_name='studyitem', name='exp4',
            field=models.CharField(blank=True, max_length=1000)),
        migrations.AddField(model_name='studyitem', name='exp5',
            field=models.CharField(blank=True, max_length=1000)),
        # Make correct_answer optional
        migrations.AlterField(
            model_name='studyitem',
            name='correct_answer',
            field=models.CharField(blank=True, max_length=500),
        ),
    ]
