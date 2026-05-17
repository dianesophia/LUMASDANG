import 'package:flutter_test/flutter_test.dart';
import 'package:lumasdang/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lumasdang/providers/theme_provider.dart'; // adjust if your path is different

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Initialize Firebase for widgets that access Firebase during init
    await Firebase.initializeApp();

    // Create a ThemeProvider instance
    final themeProvider = ThemeProvider();

    // Build the app with the required parameter
    await tester.pumpWidget(MyApp(themeProvider: themeProvider));
    // Let initial animations/timers run so no timers remain pending
    await tester.pump();

    // Verify the app shows the loading screen content
    expect(find.text('Getting things ready...'), findsOneWidget);
    expect(find.text('Lµmasdαng'), findsOneWidget);

    // Advance enough time to allow LoadingScreen timers to complete
    await tester.pump(const Duration(seconds: 3));
  });
}