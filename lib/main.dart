import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/providers/app_init_provider.dart';
import 'data/providers/theme_provider.dart';
import 'data/services/firebase_options.dart';
import 'routes/router_config.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

//dart run build_runner watch -d
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //
  runApp(const ProviderScope(child: MyApp()));
}

// ===================== MY APP =====================
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // trigger app initialization (non-blocking)
    ref.listen(appInitProvider, (_, __) {});

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Blood Finder',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: routerConfig,
    );
  }
}

// ===================== THEMES =====================
final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.red,
    brightness: Brightness.light,
  ),
  fontFamily: GoogleFonts.ubuntu().fontFamily,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    titleTextStyle: GoogleFonts.ubuntu(
      fontWeight: FontWeight.w600,
      fontSize: 18,
      color: Colors.black,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      minimumSize: const Size(double.infinity, 48),
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.ubuntu(fontWeight: FontWeight.w500, height: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    height: 64,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: Colors.red);
      }
      return const IconThemeData(color: Colors.grey);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(color: Colors.red, fontSize: 12);
      }
      return const TextStyle(color: Colors.grey, fontSize: 12);
    }),
  ),
  inputDecorationTheme: InputDecorationTheme(
    contentPadding: const EdgeInsets.only(left: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  ),
  dialogTheme: const DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.red,
    brightness: Brightness.dark,
  ),
  fontFamily: GoogleFonts.ubuntu().fontFamily,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[900],
    surfaceTintColor: Colors.grey[900],
    titleTextStyle: GoogleFonts.ubuntu(
      fontWeight: FontWeight.w600,
      fontSize: 18,
      color: Colors.white,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.grey[850],
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red[700],
      minimumSize: const Size(double.infinity, 48),
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.ubuntu(fontWeight: FontWeight.w500, height: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.grey[900],
    height: 64,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: Colors.red);
      }
      return const IconThemeData(color: Colors.grey);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(color: Colors.red, fontSize: 12);
      }
      return const TextStyle(color: Colors.grey, fontSize: 12);
    }),
  ),
  inputDecorationTheme: InputDecorationTheme(
    contentPadding: const EdgeInsets.only(left: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  ),
  dialogTheme: const DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
);

// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//
//
//     // Watch the themeModeProvider to get the current theme mode.
//     final themeMode = ref.watch(themeModeProvider);
//
//     return MaterialApp.router(
//       title: 'Blood Finder',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.red,
//           // surface: Colors.white,
//           brightness: Brightness.light,
//         ),
//         fontFamily: GoogleFonts.ubuntu().fontFamily,
//
//         // AppBar Theme for Light Mode
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.white,
//           surfaceTintColor: Colors.white,
//           titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
//             fontFamily: GoogleFonts.ubuntu().fontFamily,
//             fontWeight: FontWeight.w600,
//             fontSize: 18,
//             color: Colors.black,
//           ),
//         ),
//
//         // Card Theme for Light Mode
//         cardTheme: CardThemeData(
//           color: Colors.white,
//           elevation: 0,
//           margin: EdgeInsets.zero,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
//         ),
//
//         // Elevated Button Theme for Light Mode
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.red,
//             minimumSize: const Size(double.infinity, 48),
//             foregroundColor: Colors.white,
//             textStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
//               fontWeight: FontWeight.w500,
//               height: 1,
//               fontFamily: GoogleFonts.ubuntu().fontFamily,
//             ),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//
//         // Navigation Bar Theme for Light Mode
//         navigationBarTheme: NavigationBarThemeData(
//           backgroundColor: Colors.white,
//           // indicatorColor: Colors.transparent,
//           height: 64,
//           shadowColor: Colors.black,
//           iconTheme: WidgetStateProperty.resolveWith((states) {
//             if (states.contains(WidgetState.selected)) {
//               return const IconThemeData(color: Colors.red);
//             }
//             return const IconThemeData(color: Colors.grey);
//           }),
//           labelTextStyle: WidgetStateProperty.resolveWith((states) {
//             if (states.contains(WidgetState.selected)) {
//               return const TextStyle(color: Colors.red, fontSize: 12);
//             }
//             return const TextStyle(color: Colors.grey, fontSize: 12);
//           }),
//         ),
//
//         //
//         inputDecorationTheme: InputDecorationTheme(
//           contentPadding: EdgeInsets.only(left: 12),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//
//         //
//         dialogTheme: DialogThemeData(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.all(Radius.circular(12)), //
//           ),
//         ),
//       ),
//
//       // Dark Theme configuration
//       darkTheme: ThemeData(
//         useMaterial3: true,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.red,
//           brightness: Brightness.dark,
//         ),
//         fontFamily: GoogleFonts.ubuntu().fontFamily,
//
//         // AppBar Theme for Dark Mode
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.grey[900],
//           surfaceTintColor: Colors.grey[900],
//           titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
//             fontFamily: GoogleFonts.ubuntu().fontFamily,
//             fontWeight: FontWeight.w600,
//             fontSize: 18,
//             color: Colors.white,
//           ),
//         ),
//         // Card Theme for Dark Mode
//         cardTheme: CardThemeData(
//           color: Colors.grey[850],
//           elevation: 0,
//           margin: EdgeInsets.zero,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
//         ),
//
//         // Elevated Button Theme for Dark Mode
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.red[700],
//             minimumSize: const Size(double.infinity, 48),
//             foregroundColor: Colors.white,
//             textStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
//               fontWeight: FontWeight.w500,
//               height: 1,
//               fontFamily: GoogleFonts.ubuntu().fontFamily,
//             ),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//
//         // Navigation Bar Theme for Dark Mode
//         navigationBarTheme: NavigationBarThemeData(
//           backgroundColor: Colors.grey[900],
//           // indicatorColor: Colors.transparent,
//           height: 64,
//           shadowColor: Colors.black,
//           iconTheme: WidgetStateProperty.resolveWith((states) {
//             if (states.contains(WidgetState.selected)) {
//               return const IconThemeData(color: Colors.red);
//             }
//             return const IconThemeData(color: Colors.grey);
//           }),
//           labelTextStyle: WidgetStateProperty.resolveWith((states) {
//             if (states.contains(WidgetState.selected)) {
//               return const TextStyle(color: Colors.red, fontSize: 12);
//             }
//             return const TextStyle(color: Colors.grey, fontSize: 12);
//           }),
//         ),
//
//         //
//         inputDecorationTheme: InputDecorationTheme(
//           contentPadding: EdgeInsets.only(left: 12),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//
//         //
//         dialogTheme: DialogThemeData(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.all(Radius.circular(12)), //
//           ),
//         ),
//       ),
//
//       //
//       themeMode: themeMode,
//       routerConfig: routerConfig,
//     );
//   }
// }
