import 'package:flutter_test/flutter_test.dart';
import 'package:kamer_sync/main.dart';

void main() {
  testWidgets('App shows ready text', (WidgetTester tester) async {
    await tester.pumpWidget(const KamerSyncApp());
    expect(find.text('App Ready'), findsOneWidget);
  });
}
