
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:bloodfinder/routes/router_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_web_plugins/url_strategy.dart' show usePathUrlStrategy;
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'data/providers/theme_provider.dart';
import 'firebase_options.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  GoRouter.optionURLReflectsImperativeAPIs = true;

  runApp(const ProviderScope(child: MyApp()));
}

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
    if (!kIsWeb) {
      initDeepLinks();
    }
  }

  void initDeepLinks() {
    _linkSubscription = AppLinks().uriLinkStream.listen((uri) {
      if (mounted) {
        handleDeepLink(uri);
      }
    });

    AppLinks().getInitialLink().then((uri) {
      if (uri != null && mounted) {
        handleDeepLink(uri);
      }
    });
  }

  void handleDeepLink(Uri uri) {
    if (uri.pathSegments.isEmpty) return;

    final communityIndex = uri.pathSegments.indexOf('community');
    if (communityIndex != -1 && uri.pathSegments.length > communityIndex + 1) {
      final communityId = uri.pathSegments[communityIndex + 1];
      routerConfig.push('/community/$communityId');
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
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
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}
