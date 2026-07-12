#!/usr/bin/env python
"""
BenGo Backend Setup Script
Run this once to create admin user and seed initial data.
Usage: python setup.py
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'bengo_backend.settings')
django.setup()

from apps.accounts.models import User, Role, UserRole
from apps.courses.models import Exam, Category, Lesson

print("🔧 Setting up BenGo backend...")

# ── Create roles ─────────────────────────────────────────────────────────────
admin_role, _ = Role.objects.get_or_create(name='admin', defaults={'description': 'Full admin access'})
user_role,  _ = Role.objects.get_or_create(name='user',  defaults={'description': 'Regular user'})
print("✅ Roles created: admin, user")

# ── Create superuser ─────────────────────────────────────────────────────────
if not User.objects.filter(email='admin@bengo.com').exists():
    admin = User.objects.create_superuser(
        username='admin',
        email='admin@bengo.com',
        password='admin123',
    )
    UserRole.objects.create(user=admin, role=admin_role)
    print("✅ Admin user created: admin@bengo.com / admin123")
else:
    print("ℹ️  Admin user already exists.")

# ── Seed sample N5 exam ──────────────────────────────────────────────────────
if not Exam.objects.filter(level='N5').exists():
    exam = Exam.objects.create(
        title='JLPT N5 Proficiency',
        description='Foundation level Japanese for daily communication basics.',
        level='N5',
        is_active=True,
        order=1,
    )
    vocab_cat = Category.objects.create(exam=exam, title='Vocabulary', order=1, is_active=True)
    grammar_cat = Category.objects.create(exam=exam, title='Grammar', order=2, is_active=True)
    kanji_cat = Category.objects.create(exam=exam, title='Kanji', order=3, is_active=True)

    # 10 lessons in Vocabulary
    for i in range(10):
        Lesson.objects.create(
            category=vocab_cat,
            name=f'Lesson {i+1}',
            order=i,
            lesson_type='study',
            show_type='full_row',
            test_source='from_study',
            pass_percentage=90,
            is_active=True,
        )

    print("✅ Sample N5 exam seeded with 3 categories and 10 vocabulary lessons.")
else:
    print("ℹ️  N5 exam already exists.")

print("\n🚀 Setup complete! Start the server with:")
print("   python manage.py runserver")
print("\nAdmin panel: http://localhost:8000/admin/")
print("API base:    http://localhost:8000/api/")
