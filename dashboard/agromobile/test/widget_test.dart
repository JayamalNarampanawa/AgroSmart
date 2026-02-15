import 'package:flutter_test/flutter_test.dart';
import 'package:agri_bot/main.dart';

void main() {
  testWidgets('Shows login screen on app start', (WidgetTester tester) async {
    await tester.pumpWidget(const AgriBot());

    expect(find.text('Agri-Bot'), findsOneWidget);
    expect(find.text('Agricultural Assistant Robot'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
