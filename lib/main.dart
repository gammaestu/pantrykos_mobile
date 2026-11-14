import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_navigation.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.midnightNavyScaffold,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PantryKosApp());
}

/// Root application widget for PantryKos (Smart Pantry & Recipe Finder for Boarding Students).
class PantryKosApp extends StatelessWidget {
  const PantryKosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PantryKos — Smart Pantry Anak Kos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.midnightNavyTheme,
      darkTheme: AppTheme.midnightNavyTheme,
      themeMode: ThemeMode.dark,
      home: const MainNavigation(),
    );
  }
}
