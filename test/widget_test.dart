import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrykos_mobile/main.dart';
import 'package:pantrykos_mobile/presentation/providers/repository_providers.dart';
import 'package:pantrykos_mobile/presentation/screens/bookmark_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OfflineDioAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('offline', 503);
  }
}

void main() {
  testWidgets('MainNavigation shows dock, home recipes and bookmark tab', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final offlineDio = Dio()..httpClientAdapter = _OfflineDioAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(offlineDio),
        ],
        child: const PantryKosApp(),
      ),
    );
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

    // Home content loaded from pantrykos_db.json via PantryNotifier
    expect(find.text('Pantry'), findsOneWidget);
    expect(find.text('+ Kelola Bahan'), findsOneWidget);
    expect(find.text('Nasi Telur Ceplok Bawang Kecap'), findsOneWidget);

    // Switch to bookmark tab
    await tester.tap(find.text('Tersimpan'));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Resep Tersimpan'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('100% Siap Masak'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BookmarkScreen),
        matching: find.text('Nasi Goreng Mawut Rice Cooker'),
      ),
      findsOneWidget,
    );

    expect(Icons.bookmark_rounded, isNotNull);
  });
}
