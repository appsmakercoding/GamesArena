import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common.dart';
import 'game_ui.dart';
import 'net.dart';
import 'ui.dart';

Offset _cell(int i) {
  i %= 40;
  if (i < 10) return Offset(.5, 10 - i + .5);
  if (i < 20) return Offset(i - 10 + .5, .5);
  if (i < 30) return Offset(10.5, i - 20 + .5);
  return Offset(10 - (i - 30) + .5, 10.5);
}

class KoriPage extends StatefulWidget {
  final int n;
  final bool vsPc;
  final Net? net;
  const KoriPage(this.n, this.vsPc, {super.key, this.net});
  @override
  State<KoriPage> createState() => _KoriState();
}

class _KoriState extends State<KoriPage> with NetMix<KoriPage>, TickerProviderStateMixin {
  @override
  Net? get net => widget.net;
  bool ready = false;

  late final AnimationController mv = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  Map<int, PawnRoute> _routes = {};

  @override
  bool remote(Map a) {
    if (!ready || a['t'] != 'r') return false;
    _throw();
    return true;
  }

  void _uThrow() {
    if (!canAct(turn) || !ready || busy) return;
    emit({'t': 'r'});
    _throw();
  }

  late List<int> pos;
  late List<bool> bots;
  List<bool> cow = [false, false, false, false];
  int turn = 0, lastSteps = 0;
  bool busy = false, over = false, shaking = false;
  String msg = 'কড়ি ছুড়তে ট্যাপ করুন';

  @override
  void initState() {
    super.initState();
    mv.value = 0;
    _init();
  }

  @override
  void dispose() {
    mv.dispose();
    super.dispose();
  }

  void _init() {
    pos = List.filled(widget.n, 0);
    bots = List.generate(widget.n, (i) => widget.vsPc && i > 0);
    turn = 0; busy = false; over = false; shaking = false; lastSteps = 0;
    cow = [false, false, false, false];
    _routes = {};
    msg = 'কড়ি ছুড়তে ট্যাপ করুন';
    setState(() {});
    _auto();
  }

  void _auto() {
    if (!mounted) return;
    ready = true;
    if (bots[turn] && !over) Future.delayed(const Duration(milliseconds: 800), () { if (mounted) _throw(); });
  }

  void _throw() {
    if (busy || over || !ready) return;
    ready = false;
    busy = true;
    shaking = true;
    var k = 0;
    Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => cow = List.generate(4, (_) => rnd.nextBool()));
      if (++k >= 8) {
        t.cancel();
        setState(() => shaking = false);
        _move();
      }
    });
  }

  Future<void> _move() async {
    final up = cow.where((e) => e).length;
    final steps = up == 0 ? 8 : up;
    var extra = up == 0 || up == 4;
    final old = pos[turn];
    final np = old + steps;
    final route = <Offset>[_cell(old)];
    for (var q = old + 1; q <= np; q++) { route.add(_cell(math.min(q, 40))); }
    final seg = route.length - 1;
    final from = <int, PawnRoute>{turn: PawnRoute(route, true)};
    setState(() {
      lastSteps = steps;
      pos[turn] = np;
      if (np < 40 && np % 8 != 0) {
        for (var j = 0; j < widget.n; j++) {
          if (j != turn && pos[j] == np) {
            // কাটা কড়ি-গুটি হাঁটা শেষ হলে শুরুতে ফেরে
            from[j] = PawnRoute([for (var z = 0; z < seg; z++) _cell(np), _cell(0)], false);
            pos[j] = 0;
            extra = true;
          }
        }
      }
      msg = '${playerName(turn, n: widget.n, bots: bots, vsPc: widget.vsPc, net: net)}: $steps ঘর ${extra ? '(আবার চাল!)' : ''}';
      _routes = from;
    });
    mv.duration = Duration(milliseconds: math.max(300, 150 * seg));
    await mv.forward(from: 0);
    if (!mounted) return;
    setState(() => _routes = {});
    busy = false;
    if (np >= 40) {
      over = true;
      final rw = giveWinReward(vsPc: widget.vsPc, turn: turn, net: net);
      showWin(context, playerName(turn, n: widget.n, bots: bots, vsPc: widget.vsPc, net: net), kCol[turn],
          net == null ? _init : () => Navigator.pop(context), reward: rw);
      return;
    }
    if (!extra) setState(() => turn = (turn + 1) % widget.n);
    _auto();
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'কড়ি খেলা',
        onRestart: net == null ? _init : null,
        child: LayoutBuilder(builder: (_, bc) {
          final rows = widget.n > 2 ? 2 : 1;
          final stripH = rows * 58.0 + (rows - 1) * 8;
          final size = math.min(bc.maxWidth - 24, bc.maxHeight - stripH - 10 - 12 - 76 - 12 - 54 - 40).clamp(220.0, 640.0).toDouble();
          final can = !bots[turn] && !busy && !over && canAct(turn);
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                PlayerStrip([
                  for (var i = 0; i < widget.n; i++)
                    PlayerChip(
                      name: playerName(i, n: widget.n, bots: bots, vsPc: widget.vsPc, net: net),
                      sub: pos[i] == 0 ? 'শুরু হয়নি' : '${bnNum(math.min(pos[i], 40))}/৪০ ঘর',
                      color: kCol[i],
                      active: i == turn && !over,
                    ),
                ]),
                const SizedBox(height: 10),
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * .055),
                    border: Border.all(color: Colors.white.withOpacity(.4), width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 24, offset: const Offset(0, 10)),
                      BoxShadow(color: AC.violet.withOpacity(.5), blurRadius: 30),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(size * .045),
                    child: Stack(fit: StackFit.expand, children: [
                      RepaintBoundary(child: CustomPaint(painter: _BoardPainter())),
                      IgnorePointer(
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(lastSteps == 0 ? '🐚' : '$lastSteps', style: TextStyle(fontSize: size * .17, fontWeight: FontWeight.w900, shadows: const [Shadow(color: Colors.black54, blurRadius: 12)])),
                            Text(lastSteps == 0 ? 'কড়ি খেলা' : 'ঘর এগোলো', style: TextStyle(fontSize: size * .04, fontWeight: FontWeight.w800, color: Colors.white70)),
                          ]),
                        ),
                      ),
                      CustomPaint(painter: _TokenPainter(pos, _routes, mv, turn, over)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        transform: shaking ? Matrix4.rotationZ(cow[i] ? .35 : -.35) : Matrix4.identity(),
                        transformAlignment: Alignment.center,
                        child: Cowrie(up: cow[i], w: 46),
                      ),
                    ),
                ]),
                const SizedBox(height: 12),
                GlossBtn('কড়ি ছুড়ুন', icon: Icons.casino_rounded, colors: [lighten(kCol[turn], .2), darken(kCol[turn], .1)], onTap: can ? _uThrow : null),
                const SizedBox(height: 8),
                Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        }),
      );
}

/// কড়ির ছবি — উপরে মুখ (ফাঁক) / উল্টো (মসৃণ)
class Cowrie extends StatelessWidget {
  final bool up;
  final double w;
  const Cowrie({super.key, required this.up, this.w = 46});
  @override
  Widget build(BuildContext context) => SizedBox(width: w, height: w * 1.4, child: CustomPaint(painter: _CowriePainter(up)));
}

class _CowriePainter extends CustomPainter {
  final bool up;
  _CowriePainter(this.up);
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final body = Rect.fromLTWH(w * .04, h * .02, w * .92, h * .96);
    c.drawOval(body.shift(Offset(0, h * .03)), Paint()..color = Colors.black.withOpacity(.3));
    c.drawOval(
        body,
        Paint()
          ..shader = RadialGradient(center: const Alignment(-.35, -.5), colors: up ? const [Color(0xFFFFF8E6), Color(0xFFF1D79A), Color(0xFFC99A4A)] : const [Color(0xFFFFF2D2), Color(0xFFE9C47A), Color(0xFFB98532)])
              .createShader(body));
    c.drawOval(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .05
          ..color = const Color(0xFF9A6A2A));
    if (up) {
      final slit = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * .17, height: h * .62), Radius.circular(w * .09));
      c.drawRRect(slit, Paint()..color = const Color(0xFF4A2B10));
      final tooth = Paint()
        ..color = const Color(0xFF8A5A24)
        ..strokeWidth = w * .035
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < 8; k++) {
        final y = h * (.26 + k * .065);
        c.drawLine(Offset(w * .34, y), Offset(w * .43, y), tooth);
        c.drawLine(Offset(w * .57, y), Offset(w * .66, y), tooth);
      }
    } else {
      c.drawOval(Rect.fromLTWH(w * .22, h * .1, w * .3, h * .2), Paint()..color = Colors.white.withOpacity(.45));
      for (final o in const [Offset(.5, .5), Offset(.38, .62), Offset(.62, .64), Offset(.5, .75)]) {
        c.drawCircle(Offset(w * o.dx, h * o.dy), w * .04, Paint()..color = const Color(0xFF9A6A2A).withOpacity(.35));
      }
    }
  }

  @override
  bool shouldRepaint(_CowriePainter o) => o.up != up;
}

class _BoardPainter extends CustomPainter {
  static const pal = [Color(0xFFFFD6E2), Color(0xFFD3F5EE), Color(0xFFFFEBC2), Color(0xFFD6E6FF)];
  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 11);
    const full = Rect.fromLTWH(0, 0, 11, 11);
    c.drawRect(full, Paint()..shader = const LinearGradient(colors: [Color(0xFF2A1670), Color(0xFF120A3A)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(full));
    // মাঝের প্যানেল
    final mid = RRect.fromRectAndRadius(const Rect.fromLTWH(1.5, 1.5, 8, 8), const Radius.circular(.9));
    c.drawRRect(mid, Paint()..shader = const RadialGradient(colors: [Color(0xFFB06CFF), Color(0xFF7C4DFF), Color(0xFFD1309E)], stops: [0, .55, 1]).createShader(mid.outerRect));
    for (final r in [3.7, 2.7, 1.7]) {
      c.drawCircle(
          const Offset(5.5, 5.5),
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .06
            ..color = Colors.white.withOpacity(.16));
    }
    // ঘর
    for (var i = 0; i < 40; i++) {
      final o = _cell(i);
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: .92, height: .92), const Radius.circular(.2));
      final safe = i % 8 == 0;
      c.drawRRect(r, Paint()..color = i == 0 ? const Color(0xFF3DDC84) : (safe ? const Color(0xFFE0D4FF) : pal[i % 4]));
      if (i == 0) {
        c.drawPath(star5(o, .3, .13), Paint()..color = Colors.white);
      } else if (safe) {
        c.drawPath(star5(o, .27, .12), Paint()..color = const Color(0xFF7C4DFF));
      } else {
        final tp = TextPainter(
          text: TextSpan(text: '$i', style: const TextStyle(fontSize: .27, color: Color(0xFF6B7A8F), fontWeight: FontWeight.w800)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _TokenPainter extends CustomPainter {
  final List<int> pos;
  final Map<int, PawnRoute> routes;
  final Animation<double> mvA;
  final int turn;
  final bool over;
  _TokenPainter(this.pos, this.routes, this.mvA, this.turn, this.over) : super(repaint: mvA);

  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 11);
    final list = <List<Object>>[];
    for (var i = 0; i < pos.length; i++) {
      final sp = Offset((i % 2 - .5) * .3, (i ~/ 2 - .5) * .26);
      var o = _cell(math.min(pos[i], 40)) + sp;
      var lift = 0.0;
      final r = routes[i];
      if (r != null) {
        final a = routeAt(r, mvA.value);
        o = a.o + sp;
        lift = a.lift;
      }
      list.add([o, lift, i]);
    }
    list.sort((a, b) => (a[0] as Offset).dy.compareTo((b[0] as Offset).dy));
    for (final e in list) {
      final i = e[2] as int;
      drawToken(c, e[0] as Offset, kCol[i], .25, glow: i == turn && !over, lift: e[1] as double);
    }
  }

  @override
  bool shouldRepaint(covariant _TokenPainter old) => true;
}
