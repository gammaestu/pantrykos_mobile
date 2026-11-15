import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.scaffoldMintWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const PantryKosApp());
}

class PantryKosApp extends StatelessWidget {
  const PantryKosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PantryKos — Smart Pantry Anak Kos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const MainNavigation(),
    );
  }
}
