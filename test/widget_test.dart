// Basic smoke test: the app should build without throwing.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobilyamevime_app/app.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MobilyamevimeApp()));

    expect(find.byType(MobilyamevimeApp), findsOneWidget);
  });
}
