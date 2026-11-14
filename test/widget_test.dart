import 'package:flutter_test/flutter_test.dart';
import 'package:pantrykos_mobile/main.dart';

void main() {
  testWidgets(
      'PantryKos renders clean brand AppBar, Compact Pantry Dock & above-the-fold recipes',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PantryKosApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Verify clean brand lockup, Compact Pantry Dock & Manage Ingredients button
    expect(find.text('Pantry'), findsOneWidget);
    expect(find.text('Kos'), findsOneWidget);
    expect(find.textContaining('Isi Kulkasmu ('), findsOneWidget);
    expect(find.text('+ Kelola Bahan'), findsOneWidget);
    expect(find.text('Scan Isi Kulkas'), findsOneWidget);

    // Verify Ultra-Thin Tool Filter Strip chips
    expect(find.text('Semua Alat'), findsOneWidget);
    expect(find.text('Rice Cooker'), findsWidgets);

    // Verify initial 100% Siap Masak recipe is immediately visible above-the-fold
    expect(find.text('Nasi Goreng Mawut Rice Cooker'), findsOneWidget);
  });
}
