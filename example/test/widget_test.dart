import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid_example/main.dart';

void main() {
  testWidgets('Showcase app loads and can switch between feature tabs', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppGridShowcaseApp());
    await tester.pumpAndSettle();

    // Verify initial header and quickstart view
    expect(find.text('AppGrid'), findsOneWidget);
    expect(find.text('Overview & Quickstart'), findsWidgets);
    expect(find.text('Copy Code'), findsOneWidget);

    // Switch to Row Mutation Helpers tab
    await tester.tap(find.text('Row Mutation Helpers'));
    await tester.pumpAndSettle();

    expect(find.text('Developer Row & Batch Mutation Helpers'), findsOneWidget);
    expect(find.text('updateRow(0)'), findsOneWidget);

    // Click updateRow(0) button
    await tester.tap(find.text('updateRow(0)'));
    await tester.pumpAndSettle();

    expect(find.text('Emma (Updated)'), findsOneWidget);

    // Switch to Column Freezing tab
    await tester.tap(find.text('Column Freezing'));
    await tester.pumpAndSettle();

    expect(find.text('Frozen ID'), findsOneWidget);
    expect(find.text('Frozen Action'), findsOneWidget);

    // Switch to Discrete Pagination tab
    await tester.tap(find.text('Discrete Pagination'));
    await tester.pumpAndSettle();

    expect(find.text('Data Ingestion: Discrete Pagination (REQ-DATA-01)'), findsOneWidget);
    expect(find.text('Page 1 of 12'), findsOneWidget);
    expect(find.text('Showing 1–10 of 120 orders'), findsOneWidget);
    expect(find.text('ORD-1001'), findsOneWidget);
    expect(find.text('ORD-1011'), findsNothing);

    // Tap Next Page button
    await tester.ensureVisible(find.byTooltip('Next Page'));
    await tester.tap(find.byTooltip('Next Page'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    // Verify Page 2 data is now rendered in the table
    expect(find.text('Page 2 of 12'), findsOneWidget);
    expect(find.text('Showing 11–20 of 120 orders'), findsOneWidget);
    expect(find.text('ORD-1001'), findsNothing);
    expect(find.text('ORD-1011'), findsOneWidget);

    // Switch to Modular Column Builders & DX tab
    await tester.ensureVisible(find.text('Modular Column Builders & DX'));
    await tester.tap(find.text('Modular Column Builders & DX'));
    await tester.pumpAndSettle();

    expect(find.text('Honeycrisp Apple'), findsOneWidget);
    expect(find.text('Simulate Empty State'), findsOneWidget);

    // Switch to Infinite Scroll tab
    await tester.ensureVisible(find.text('Infinite Scroll'));
    await tester.tap(find.text('Infinite Scroll'));
    await tester.pumpAndSettle();

    expect(find.text('Data Ingestion: Infinite Scroll (REQ-DATA-01)'), findsOneWidget);
    expect(find.text('Loaded: 30 / 200 items'), findsOneWidget);

    // Switch to 100,000 Rows x 50 Cols tab
    await tester.ensureVisible(find.text('100,000 Rows x 50 Cols'));
    await tester.tap(find.text('100,000 Rows x 50 Cols'));
    await tester.pumpAndSettle();

    expect(find.text('Field 0'), findsOneWidget);
  });
}
