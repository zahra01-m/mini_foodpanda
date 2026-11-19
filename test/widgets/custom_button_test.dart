import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/widgets/custom_button.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget button, {ThemeMode mode = ThemeMode.light}) {
    return tester.pumpWidget(
      MaterialApp(
        themeMode: mode,
        theme: ThemeData(brightness: Brightness.light),
        darkTheme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(body: Center(child: button)),
      ),
    );
  }

  testWidgets('fires onPressed when enabled', (tester) async {
    var taps = 0;
    await pump(tester, CustomButton(label: 'Pay', onPressed: () => taps++));
    await tester.tap(find.text('Pay'));
    expect(taps, 1);
  });

  testWidgets('disabled button still shows its label and ignores taps', (tester) async {
    await pump(tester, const CustomButton(label: 'Pay', onPressed: null));
    expect(find.text('Pay'), findsOneWidget);
    await tester.tap(find.text('Pay'), warnIfMissed: false);
    // Nothing to assert on a callback: the point is that it renders and does not throw.
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading hides the label and blocks taps', (tester) async {
    var taps = 0;
    await pump(tester, CustomButton(label: 'Pay', loading: true, onPressed: () => taps++));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Pay'), findsNothing);
    await tester.tap(find.byType(CustomButton), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('outlined variant uses an OutlinedButton', (tester) async {
    await pump(tester, CustomButton(label: 'Create account', outlined: true, onPressed: () {}));
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('renders in dark mode without errors', (tester) async {
    await pump(tester, CustomButton(label: 'Pay', onPressed: () {}), mode: ThemeMode.dark);
    expect(find.text('Pay'), findsOneWidget);
  });
}
