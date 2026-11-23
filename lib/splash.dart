import 'package:flutter/material.dart';
import 'home.dart';
import 'logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _c, curve: const Interval(0, .5)),
          child: ScaleTransition(
            scale: curve,
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
              ArenaLogo(size: 130),
              SizedBox(height: 24),
              Text('GAMES ARENA',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 3)),
              SizedBox(height: 6),
              Text('Powered by Hasan', style: TextStyle(color: Colors.white54)),
            ]),
          ),
        ),
      ),
    );
  }
}
