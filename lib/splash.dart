import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'home.dart';
import 'ui.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  late final AnimationController _p =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  @override
  void initState() {
    super.initState();
    _p.forward().then((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _loop.dispose();
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final hs = math.min(250.0, h * .3);
    return Scaffold(
      body: ArenaBg(
        child: SafeArea(
          child: Column(children: [
            const Spacer(flex: 2),
            SizedBox(
              width: hs * 1.4,
              height: hs * 1.1,
              child: AnimatedBuilder(animation: _loop, builder: (_, __) => _hero(hs)),
            ),
            const SizedBox(height: 6),
            StrokeText('গেমস', size: hs * .26),
            StrokeText('এরিনা', size: hs * .3, fill: AC.gold),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(colors: [AC.violet.withOpacity(.2), AC.pink.withOpacity(.35), AC.violet.withOpacity(.2)]),
                border: Border.all(color: Colors.white.withOpacity(.2)),
              ),
              child: const Text('খেলুন, জিতুন, মজা করুন!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            const Spacer(flex: 2),
            Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: const [
              Pawn(Color(0xFFFF4D6D), size: 44),
              SizedBox(width: 10),
              Pawn(Color(0xFF3B82F6), size: 52),
              SizedBox(width: 40),
              Pawn(Color(0xFF2EE66B), size: 52),
              SizedBox(width: 10),
              Pawn(Color(0xFFFFC83D), size: 44),
            ]),
            const SizedBox(height: 18),
            const Text('Loading...', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white70)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: AnimatedBuilder(
                animation: _p,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(children: [
                    Container(height: 12, color: Colors.white.withOpacity(.12)),
                    FractionallySizedBox(
                      widthFactor: Curves.easeInOut.transform(_p.value).clamp(0.02, 1.0),
                      child: Container(
                        height: 12,
                        decoration: const BoxDecoration(gradient: LinearGradient(colors: [AC.violet, AC.pink, AC.gold])),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Crown(18),
              const SizedBox(width: 6),
              Text('Powered by Hasan', style: TextStyle(color: Colors.white.withOpacity(.7), fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 14),
          ]),
        ),
      ),
    );
  }

  Widget _hero(double hs) {
    final t = _loop.value;
    final bob = math.sin(t * 2 * math.pi) * 7;
    return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
      Container(
        width: hs * 1.1,
        height: hs * 1.1,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AC.violet.withOpacity(.55), Colors.transparent])),
      ),
      Transform.rotate(angle: -.35, child: CustomPaint(size: Size(hs * 1.25, hs * .42), painter: _RingPainter(t, false))),
      Transform.translate(
        offset: Offset(0, bob),
        child: Stack(alignment: Alignment.topCenter, clipBehavior: Clip.none, children: [
          Padding(padding: EdgeInsets.only(top: hs * .14), child: Dice3D(size: hs * .72)),
          Positioned(top: -hs * .02, child: Transform.rotate(angle: .1, child: Crown(hs * .34))),
        ]),
      ),
      Transform.rotate(angle: -.35, child: CustomPaint(size: Size(hs * 1.25, hs * .42), painter: _RingPainter(t, true))),
      Positioned(left: hs * .02, top: hs * .3 + math.sin((t + .3) * 2 * math.pi) * 8, child: const Text('🪙', style: TextStyle(fontSize: 30))),
      Positioned(right: hs * .0, top: hs * .55 + math.sin((t + .7) * 2 * math.pi) * 8, child: const Text('🪙', style: TextStyle(fontSize: 26))),
      Positioned(right: hs * .12, top: hs * .06 + math.sin((t + .5) * 2 * math.pi) * 6, child: const Text('✨', style: TextStyle(fontSize: 22))),
    ]);
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  final bool front;
  _RingPainter(this.t, this.front);
  @override
  void paint(Canvas c, Size s) {
    final rect = Rect.fromLTWH(0, 0, s.width, s.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..shader = SweepGradient(
        colors: [AC.gold.withOpacity(0), AC.gold, Colors.white, AC.gold, AC.gold.withOpacity(0)],
        transform: GradientRotation(t * 2 * math.pi),
      ).createShader(rect);
    if (front) {
      c.drawArc(rect, 0, math.pi, false, paint);
    } else {
      c.drawOval(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.t != t;
}
