import 'package:flutter/material.dart';
import 'package:my_nthu_life/data/studentData.dart';
import 'package:my_nthu_life/screens/auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/theme/theme.dart';

var kColorScheme = MaterialTheme.lightScheme();
var kDarkColorScheme = MaterialTheme.darkHighContrastScheme();

// Global notifier — any widget in the tree can toggle the theme
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadUsers();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: kDarkColorScheme,
            cardTheme: const CardThemeData().copyWith(
              color: kDarkColorScheme.secondaryContainer,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: kDarkColorScheme.primaryContainer,
                foregroundColor: kDarkColorScheme.onPrimaryContainer,
              ),
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
                .copyWith(
                  titleLarge: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  titleMedium: GoogleFonts.outfit(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  titleSmall: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white60.withOpacity(0.55),
                  ),
                  displayLarge: GoogleFonts.outfit(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  bodyMedium: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  labelMedium: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white38,
                  ),
                  labelLarge: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
          ),
          theme: ThemeData().copyWith(
            colorScheme: kColorScheme,
            appBarTheme: const AppBarTheme().copyWith(
              backgroundColor: kColorScheme.onPrimaryContainer,
              foregroundColor: kColorScheme.primaryContainer,
            ),
            cardTheme: const CardThemeData().copyWith(
              color: kColorScheme.secondaryContainer,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: kColorScheme.primaryContainer,
              ),
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData().textTheme)
                .copyWith(
                  titleLarge: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  titleMedium: GoogleFonts.outfit(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  titleSmall: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white60.withOpacity(0.55),
                  ),
                  displayLarge: GoogleFonts.outfit(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  bodyMedium: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  labelMedium: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white38,
                  ),
                  labelLarge: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
          ),
          themeMode: mode, // driven by the notifier
          home: Auth(),
        );
      },
    );
  }
}
