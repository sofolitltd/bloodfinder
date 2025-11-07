import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart'
    show PathUrlStrategy, setUrlStrategy;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/providers/theme_provider.dart';
import 'firebase_options.dart';
import 'routes/router_config.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

//dart run build_runner watch -d
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // remove #
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }

  //
  GoRouter.optionURLReflectsImperativeAPIs = true;

  //
  runApp(const ProviderScope(child: MyApp()));
}

// ===================== MY APP =====================
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  void initDeepLinks() {
    _linkSubscription = AppLinks().uriLinkStream.listen((uri) {
      if (uri != null && uri.pathSegments.isNotEmpty) {
        // ⬇️ CHANGE INDEX FROM 1 TO 0
        final communityId = uri.pathSegments[0];
        routerConfig.push('/community/$communityId');
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: MaterialApp.router(
        title: 'Blood Finder',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        routerConfig: routerConfig,
        builder: (context, child) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: child,
            ),
          );
        },
      ),
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
  fontFamily: GoogleFonts.anekBangla().fontFamily,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    titleTextStyle: GoogleFonts.anekBangla(
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
      minimumSize: const Size(double.infinity, 40),
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, height: 1),
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
    isDense: true,
    contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
  fontFamily: GoogleFonts.anekBangla().fontFamily,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey.shade900,
    surfaceTintColor: Colors.grey.shade900,
    titleTextStyle: GoogleFonts.anekBangla(
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
      minimumSize: const Size(double.infinity, 40),
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.anekBangla(fontWeight: FontWeight.w500, height: 1),
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
    isDense: true,
    contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
  ),
  dialogTheme: const DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
);
