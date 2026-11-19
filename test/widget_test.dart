// App-level smoke test.
//
// The original Flutter counter-app boilerplate here referenced `MyApp`
// and a counter, neither of which exist in this project — it never
// compiled. This replaces it with a real smoke test of the first screen
// a user sees, which needs no Firebase setup since RoleSelectorScreen
// reads no providers. Feature-level behavior is covered by the tests
// under test/models, test/providers, test/services and test/widgets.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/screens/auth/login_screen.dart';
import 'package:mini_foodpanda/screens/auth/role_selector_screen.dart';
import 'package:mini_foodpanda/models/user_model.dart';

void main() {
  testWidgets('RoleSelectorScreen shows the three roles and navigates to login', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoleSelectorScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Mini FoodPanda'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Rider'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);

    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    final loginScreen = tester.widget<LoginScreen>(find.byType(LoginScreen));
    expect(loginScreen.role, UserRole.customer);
  });
}
