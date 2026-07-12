from django.contrib.auth import get_user_model
from django.test import SimpleTestCase, TestCase
from rest_framework.test import APIRequestFactory, force_authenticate

from .models import Category, Exam, Lesson, QuestionBank, BankQuestion
from .serializers import LessonSerializer
from .views import _build_header_map, _extract_row_values, LessonTestView
from apps.progress.models import UserExamUnlock
from apps.ranks.models import Rank


class StudyImportColumnMappingTests(SimpleTestCase):
    def test_extracts_values_from_header_names_for_exam_lessons(self):
        header_row = ['Target (Japanese)', 'Correct Answer', 'Wrong 1', 'Wrong 2', 'Wrong 3', 'Wrong 4']
        row = ('こんにちは', 'Hello', 'Goodbye', 'Thanks', 'Sorry', 'Please')

        header_map = _build_header_map(header_row)
        values = _extract_row_values(row, Lesson.EXAM, False, header_map)

        self.assertEqual(values['target'], 'こんにちは')
        self.assertEqual(values['correct_answer'], 'Hello')
        self.assertEqual(values['wrong_1'], 'Goodbye')
        self.assertEqual(values['wrong_2'], 'Thanks')
        self.assertEqual(values['wrong_3'], 'Sorry')
        self.assertEqual(values['wrong_4'], 'Please')


class LessonVisibilityTests(TestCase):
    def test_falls_back_to_the_lowest_rank_for_initial_visibility(self):
        exam = Exam.objects.create(title='Exam', level='N5')
        category = Category.objects.create(exam=exam, title='Vocabulary')
        rank = Rank.objects.create(exam=exam, name='Beginner', order=1, pass_percentage=70)
        lesson = Lesson.objects.create(category=category, name='Lesson 1', rank=rank)
        user = get_user_model().objects.create_user(username='learner', email='learner@example.com', password='secret')

        request = APIRequestFactory().get('/')
        request.user = user

        data = LessonSerializer(lesson, context={'request': request}).data

        self.assertTrue(data['is_visible_for_user'])
        self.assertEqual(data['rank_id'], rank.id)


class LessonTestViewTests(TestCase):
    def test_lesson_serializer_prefers_category_timer_settings(self):
        exam = Exam.objects.create(title='Exam', level='N5')
        category = Category.objects.create(
            exam=exam,
            title='Vocabulary',
            question_timer_seconds=15,
            has_overall_timer=True,
            overall_timer_seconds=180,
        )
        rank = Rank.objects.create(
            exam=exam,
            name='Beginner',
            order=1,
            pass_percentage=70,
            question_timer_seconds=30,
            has_overall_timer=False,
            overall_timer_seconds=300,
        )
        lesson = Lesson.objects.create(category=category, name='Lesson 1', rank=rank)

        request = APIRequestFactory().get('/')
        request.user = get_user_model().objects.create_user(username='learner3', email='learner3@example.com', password='secret')

        data = LessonSerializer(lesson, context={'request': request}).data

        self.assertEqual(data['question_timer_seconds'], 15)
        self.assertTrue(data['has_overall_timer'])
        self.assertEqual(data['overall_timer_seconds'], 180)

    def test_custom_bank_questions_use_lesson_question_count_across_active_banks(self):
        exam = Exam.objects.create(title='Exam', level='N5')
        category = Category.objects.create(exam=exam, title='Vocabulary')
        lesson = Lesson.objects.create(
            category=category,
            name='Lesson 1',
            lesson_type=Lesson.STUDY,
            test_source=Lesson.CUSTOM_BANK,
            test_questions_count=2,
        )
        user = get_user_model().objects.create_user(username='learner2', email='learner2@example.com', password='secret')
        UserExamUnlock.objects.create(user=user, exam=exam)

        bank_a = QuestionBank.objects.create(lesson=lesson, title='Bank A', questions_count=5, is_active=True)
        bank_b = QuestionBank.objects.create(lesson=lesson, title='Bank B', questions_count=5, is_active=True)
        for idx in range(3):
            BankQuestion.objects.create(bank=bank_a, target=f'A-{idx}', correct_answer='A')
            BankQuestion.objects.create(bank=bank_b, target=f'B-{idx}', correct_answer='B')

        request = APIRequestFactory().get('/')
        force_authenticate(request, user=user)
        response = LessonTestView.as_view()(request, pk=lesson.pk)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data['questions']), 2)
