import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrykos_mobile/main.dart';

void main() {
  testWidgets('MainNavigation shows dock, home recipes and bookmark tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PantryKosApp());
    await tester.pump(const Duration(milliseconds: 900));

    // Choreographed Splash Screen phase 1
    expect(find.text('PantryKos'), findsOneWidget);
    expect(find.text('Memindai bahan anak kos...'), findsOneWidget);

    // Phase 2 micro-copy after 1.35s
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Menyiapkan Kulkas Virtual...'), findsOneWidget);

    // Advance past 2.8s splash hold + 650ms CircularReveal transition into MainNavigation
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 200));

    // Floating dock destinations
    expect(find.text('Kulkas Kos'), findsOneWidget);
    expect(find.text('Scan AI'), findsOneWidget);
    expect(find.text('Tersimpan'), findsOneWidget);

    // Home content
    expect(find.text('Pantry'), findsOneWidget);
    expect(find.text('+ Kelola Bahan'), findsOneWidget);
    // Cheapest 100% match is sorted to the top of the recipe list
    expect(find.text('Nasi Telur Ceplok Bawang Putih Kecap'), findsOneWidget);

    // Switch to bookmark tab
    await tester.tap(find.text('Tersimpan'));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Resep Tersimpan'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('100% Siap Masak'), findsOneWidget);
    expect(find.text('Nasi Goreng Mawut Rice Cooker'), findsOneWidget);

    // Silence unused import warnings for Icons in some analyzer configs
    expect(Icons.bookmark_rounded, isNotNull);
  });
}
