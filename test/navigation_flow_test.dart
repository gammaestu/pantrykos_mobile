import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrykos_mobile/main.dart';

/// Smoke test that walks through every major flow at phone size and fails on
/// any layout overflow or framework exception.
void main() {
  testWidgets('Full navigation flow has no layout/runtime exceptions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Route/animation tickers start on the first frame after a push, so pump
    // twice (infinite animations rule out pumpAndSettle).
    Future<void> settle([int ms = 700]) async {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(Duration(milliseconds: ms));
    }

    await tester.pumpWidget(const PantryKosApp());
    await settle();
    expect(find.text('Kulkas Kos'), findsOneWidget);

    // Manage ingredients sheet
    await tester.tap(find.text('+ Kelola Bahan'));
    await settle(900);
    expect(find.text('Kelola Kulkas Virtual'), findsOneWidget);
    await tester.tap(find.textContaining('Simpan Kulkas'));
    await settle(900);

    // Recipe detail + cooking mode
    await tester.tap(find.text('Nasi Telur Ceplok Bawang Putih Kecap'));
    await settle(900);
    expect(find.text('Mulai Mode Masak'), findsOneWidget);
    await tester.tap(find.text('Mulai Mode Masak'));
    await settle(900);
    expect(find.textContaining('Langkah 1 /'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await settle(900);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await settle(900);

    // Bookmark tab -> remove -> empty state -> back to home
    await tester.tap(find.text('Tersimpan'));
    await settle();
    expect(find.text('Resep Tersimpan'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_rounded).last);
    await settle(600);
    expect(find.text('Belum Ada Resep Tersimpan'), findsOneWidget);
    await tester.tap(find.text('Kembali ke Kulkas Virtual'));
    await settle();
    expect(find.text('+ Kelola Bahan'), findsOneWidget);

    // Scanner
    await tester.tap(find.text('Scan AI'));
    await settle(900);
    expect(find.text('Pindai Bahan di Kulkas'), findsOneWidget);
    await tester.tap(find.text('Masukkan ke Kulkas (+)'));
    await settle(900);
    expect(find.text('Kulkas Kos'), findsOneWidget);
  });
}
