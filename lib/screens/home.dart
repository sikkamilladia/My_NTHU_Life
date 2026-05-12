
import 'package:flutter/material.dart';
import 'package:my_nthu_life/data/studentData.dart';
import 'package:my_nthu_life/screens/auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/theme/theme.dart';
// import 'package:my_nthu_life/screens/login.dart';
// import 'screens/login.dart';

var kColorScheme = MaterialTheme.lightScheme();
var kDarkColorScheme = MaterialTheme.darkHighContrastScheme();

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //Need this for Shared Preferences
  await loadUsers(); //Fill the amp with saved users before the app opens
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //Disables the debug banner
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: kDarkColorScheme,
        // cardTheme is from material app
        // card = container with a shadow
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
              // title
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
              // subtitle
              titleSmall: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white60.withOpacity(0.55),
              ),
              // input field text
              bodyMedium: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
              // label input field
              labelMedium: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white38,
              ),
              // button
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
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
            .copyWith(
              // title
              titleLarge: GoogleFonts.outfit(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              // subtitle
              titleSmall: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white60,
              ),
              // input field text
              bodyMedium: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
              // label input field
              labelMedium: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white38,
              ),
              // button
              labelLarge: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: Colors.white,
              ),
            ),
      ),
      themeMode: ThemeMode.dark, // default
      home: Auth(), //This sets the Login screen as the home screen
    );
  }
}

/* class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context){
  }
}
*/
