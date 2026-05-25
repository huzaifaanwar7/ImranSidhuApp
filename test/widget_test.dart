import 'package:flutter_test/flutter_test.dart';

import 'package:ismvcc/app.dart';

void main() {
  testWidgets('shows the splash screen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const IsmvccApp());

    expect(find.text('ESTABLISHED IN HIS MEMORY'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pumpAndSettle();

    expect(find.text('SKIP'), findsOneWidget);
  });
}
