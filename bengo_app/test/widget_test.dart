import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bengo_app/screens/vocabulary/vocabulary_test_screen.dart';

void main() {
  testWidgets('Vocabulary test screen renders quiz content without layout errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: VocabularyTestScreen(lessonId: null, questionTimerSeconds: 0),
    ));

    await tester.pumpAndSettle();

    expect(find.text('こんにちは'), findsOneWidget);
    expect(find.text('EXIT QUIZ'), findsOneWidget);
  });
}
