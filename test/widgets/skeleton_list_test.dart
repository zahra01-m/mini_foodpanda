import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/widgets/shimmer_box.dart';
import 'package:mini_foodpanda/widgets/skeleton_list.dart';

void main() {
  testWidgets('SkeletonTileList renders the requested number of rows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SkeletonTileList(itemCount: 4, showTrailing: true)),
      ),
    );
    // Each row has 3 ShimmerBoxes (leading + 2 text lines) plus 1 more
    // when showTrailing is true — 4 rows * 4 boxes = 16.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ShimmerBox), findsNWidgets(16));
  });

  testWidgets('SkeletonTileList without a trailing chip has one fewer box per row', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SkeletonTileList(itemCount: 3)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ShimmerBox), findsNWidgets(9));
  });

  testWidgets('SkeletonRestaurantList renders one card-shaped placeholder per item', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SkeletonRestaurantList(itemCount: 3)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    // Each card has 4 ShimmerBoxes: the image block + 3 text lines.
    expect(find.byType(ShimmerBox), findsNWidgets(12));
  });

  testWidgets('ShimmerBox animates without erroring and disposes cleanly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ShimmerBox(height: 20))),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
    // Swap it out to exercise dispose() — should not throw.
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    await tester.pump();
  });
}
