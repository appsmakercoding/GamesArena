import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'splash.dart';
import 'net.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadDbUrl();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
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
          scaffoldBackgroundColor: const Color(0xFF0E0B1F),
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7C4DFF), brightness: Brightness.dark),
        ),
        home: const SplashPage(),
      );
}
