import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'splash.dart';
import 'net.dart';
import 'profile.dart';
import 'ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadDbUrl();
  await Profile.load();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AC.bg0,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const GamesArenaApp());
}

class GamesArenaApp extends StatelessWidget {
  const GamesArenaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Games Arena',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: AC.bg0,
          colorScheme: ColorScheme.fromSeed(seedColor: AC.violet, brightness: Brightness.dark),
        ),
        home: const SplashPage(),
      );
}
