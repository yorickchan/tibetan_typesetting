import 'package:flutter/material.dart';

import 'pages/projects_page.dart';
import 'services/database_service.dart';
import 'utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database
  await DatabaseService().database;

  runApp(const TibetanTypesettingApp());
}

class TibetanTypesettingApp extends StatelessWidget {
  const TibetanTypesettingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tibetan Typesetting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.slate950,
        colorScheme: ColorScheme.dark(
          primary: AppColors.sky500,
          secondary: AppColors.sky400,
          surface: AppColors.slate900,
          error: AppColors.rose600,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.slate100,
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.slate950,
          foregroundColor: AppColors.slate100,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.slate900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.slate900,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.slate700),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.sky500,
          selectionColor: Color(0x400ea5e9),
          selectionHandleColor: AppColors.sky500,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const ProjectsPage(),
    );
  }
}
