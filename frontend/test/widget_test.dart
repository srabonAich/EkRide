import 'package:flutter_test/flutter_test.dart';
import 'package:ekride_frontend/main.dart';

void main() {
  testWidgets('EkRide app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EkRideApp());
    expect(find.text('EkRide'), findsOneWidget);
  });
}
