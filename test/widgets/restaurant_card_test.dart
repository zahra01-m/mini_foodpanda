import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/restaurant_model.dart';
import 'package:mini_foodpanda/widgets/restaurant_card.dart';

void main() {
  const restaurant = Restaurant(
    id: 'rest-1',
    name: 'Karahi House',
    category: 'Pakistani',
    imageAsset: '',
    rating: 4.6,
    etaMinutes: 30,
  );

  testWidgets('tapping the card fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestaurantCard(restaurant: restaurant, onTap: () => tapped = true),
        ),
      ),
    );
    await tester.tap(find.text('Karahi House'));
    expect(tapped, true);
  });

  testWidgets('no heart icon renders when onToggleFavorite is not provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RestaurantCard(restaurant: restaurant, onTap: () {}))),
    );
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
  });

  testWidgets('shows an outlined heart when not a favorite, and tapping it does not also fire onTap', (tester) async {
    var cardTapped = false;
    var heartTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestaurantCard(
            restaurant: restaurant,
            onTap: () => cardTapped = true,
            onToggleFavorite: () => heartTapped = true,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    expect(heartTapped, true);
    expect(cardTapped, false);
  });

  testWidgets('shows a filled red heart when isFavorite is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestaurantCard(
            restaurant: restaurant,
            onTap: () {},
            isFavorite: true,
            onToggleFavorite: () {},
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
  });
}
