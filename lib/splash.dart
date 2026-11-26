import 'package:flutter/material.dart';
import 'home.dart';
import 'logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final AnimationController _loadCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();

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
    _logoCtrl.dispose();
    _loadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.18),
            radius: 1.3,
            colors: [Color(0xFF33177A), Color(0xFF120B2E), Color(0xFF060410)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              children: [
                const Spacer(flex: 2),
                ScaleTransition(
                  scale: scale,
                  child: FadeTransition(
                    opacity: _logoCtrl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(.04),
                            border: Border.all(color: Colors.white.withOpacity(.14)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C4DFF).withOpacity(.55),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const ArenaLogo(size: 116),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)],
                            ),
                            border: Border.all(color: Colors.white.withOpacity(.25)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4081).withOpacity(.38),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Text(
                            'গেমস এরিনা',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'খেলুন, জিতুন, মজা করুন!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _loadCtrl,
                  builder: (_, __) => Column(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Color(0xFF38EF7D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Loading...',
                        style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.7),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 9,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            border: Border.all(color: Colors.white10),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _loadCtrl.value.clamp(0.0, 1.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF00C6FF), Color(0xFF7C4DFF), Color(0xFFFF4081)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '👑 Powered by Hasan',
                  style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
