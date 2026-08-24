// Smoke test: the app builds and shows the welcome hero.
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_twin/l10n.dart';
import 'package:campus_twin/main.dart';

void main() {
  testWidgets('app builds and shows the welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('digital twin'),
      findsOneWidget,
    );
    expect(find.text(AppStrings.signIn), findsOneWidget);
  });
}
