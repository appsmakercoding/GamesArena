import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common.dart';
import 'game_ui.dart';
import 'net.dart';
import 'ui.dart';

const _jumps = {
  1: 38, 4: 14, 9: 31, 21: 42, 28: 84, 36: 44, 51: 67, 71: 91, 80: 100,
  16: 6, 47: 26, 49: 11, 56: 53, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 98: 78,
};

Offset _c(int n) {
  final i = n - 1, r = i ~/ 10, c = r.isEven ? i % 10 : 9 - i % 10;
  return Offset(c + .5, 9 - r + .5);
}

/// সাপের শরীরের বাঁকা পথ (মাথা a → লেজ b)
List<Offset> _curve(int a, int b) {
  final p = _c(a), q = _c(b), d = q - p, dist = d.distance;
  final n = Offset(-d.dy, d.dx) / dist;
  final k = (.5 + (a % 3) * .12) * (a.isEven ? 1 : -1);
  final c1 = p + d * .3 + n * k, c2 = p + d * .7 - n * k;
  return List.generate(41, (i) {
    final t = i / 40, u = 1 - t;
    return p * (u * u * u) + c1 * (3 * u * u * t) + c2 * (3 * u * t * t) + q * (t * t * t);
  });
}

class SnakePage extends StatefulWidget {
  final int n;
  final bool vsPc;
  final Net? net;
  const SnakePage(this.n, this.vsPc, {super.key, this.net});
  @override
  State<SnakePage> createState() => _SnakeState();
}

class _SnakeState extends State<SnakePage> with NetMix<SnakePage>, TickerProviderStateMixin {
  @override
  Net? get net => widget.net;
  bool ready = false;

  late final AnimationController mv = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  Map<int, PawnRoute> _routes = {};

  @override
  bool remote(Map a) {
    if (!ready || a['t'] != 'r') return false;
    _roll();
    return true;
  }

  void _uRoll() {
    if (!canAct(turn) || !ready || busy) return;
    emit({'t': 'r'});
    _roll();
  }

  late List<int> pos;
  late List<bool> bots;
  int turn = 0, dice = 0;
  bool busy = false, over = false, rolling = false;

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
    turn = 0; dice = 0; busy = false; over = false; rolling = false;
    _routes = {};
    setState(() {});
    _auto();
  }

  void _auto() {
    if (!mounted) return;
    ready = true;
    if (bots[turn] && !over) Future.delayed(const Duration(milliseconds: 800), () { if (mounted) _roll(); });
  }

  void _roll() {
    if (busy || over || !ready) return;
    ready = false;
    busy = true;
    rolling = true;
    var k = 0;
    Timer.periodic(const Duration(milliseconds: 70), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => dice = rnd.nextInt(6) + 1);
      if (++k >= 8) {
        t.cancel();
        setState(() => rolling = false);
        _move();
      }
    });
  }

  Future<void> _move() async {
    final old = pos[turn];
    var np = old + dice;
    if (np > 100) np = old;
    // এক ঘর করে হেঁটে যাওয়ার রুট
    final route = <Offset>[_c(old == 0 ? 1 : old)];
    for (var q = old + 1; q <= np; q++) {
      if (old == 0 && q == 1) continue;
      route.add(_c(q));
    }
    final seg = route.length - 1;
    setState(() {
      pos[turn] = np;
      _routes = {turn: PawnRoute(route, true)};
    });
    if (seg > 0) {
      mv.duration = Duration(milliseconds: 150 * seg);
      await mv.forward(from: 0);
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if (!mounted) return;
    final j = _jumps[np];
    if (j != null) {
      final r = j > np ? <Offset>[_c(np), _c(j)] : _curve(np, j);
      setState(() {
        pos[turn] = j;
        _routes = {turn: PawnRoute(r, false)};
      });
      mv.duration = Duration(milliseconds: j > np ? 700 : 1000);
      await mv.forward(from: 0);
      if (!mounted) return;
    }
    setState(() => _routes = {});
    busy = false;
    if (pos[turn] == 100) {
      over = true;
      final rw = giveWinReward(vsPc: widget.vsPc, turn: turn, net: net);
      showWin(context, playerName(turn, n: widget.n, bots: bots, vsPc: widget.vsPc, net: net), kCol[turn],
          net == null ? _init : () => Navigator.pop(context), reward: rw);
    } else if (dice == 6) {
      _auto();
    } else {
      setState(() { turn = (turn + 1) % widget.n; });
      _auto();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'সাপ-লুডু',
        onRestart: net == null ? _init : null,
        child: LayoutBuilder(builder: (_, bc) {
          final rows = widget.n > 2 ? 2 : 1;
          final stripH = rows * 58.0 + (rows - 1) * 8;
          final size = math.min(bc.maxWidth - 24, bc.maxHeight - stripH - 10 - 12 - 84 - 36).clamp(220.0, 640.0).toDouble();
          final canRoll = !bots[turn] && !busy && !over && canAct(turn);
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                PlayerStrip([
                  for (var i = 0; i < widget.n; i++)
                    PlayerChip(
                      name: playerName(i, n: widget.n, bots: bots, vsPc: widget.vsPc, net: net),
                      sub: pos[i] == 0 ? 'শুরু হয়নি' : 'ঘর ${bnNum(pos[i])}',
                      color: kCol[i],
                      active: i == turn && !over,
                    ),
                ]),
                const SizedBox(height: 10),
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * .05),
                    border: Border.all(color: Colors.white.withOpacity(.5), width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 24, offset: const Offset(0, 10)),
                      BoxShadow(color: const Color(0xFF22D3A6).withOpacity(.3), blurRadius: 30),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(size * .04),
                    child: Stack(fit: StackFit.expand, children: [
                      RepaintBoundary(child: CustomPaint(painter: _BoardPainter())),
                      CustomPaint(painter: _TokenPainter(pos, _routes, mv, turn, over)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                DiceView(dice, active: canRoll, color: kCol[turn], rolling: rolling, onTap: canRoll ? _uRoll : null),
                const SizedBox(height: 8),
                Text(over ? '' : bots[turn] ? 'কম্পিউটার চাল দিচ্ছে...' : 'ডাইসে ট্যাপ করুন', style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        }),
      );
}

class _BoardPainter extends CustomPainter {
  static const snakeCols = [Color(0xFF3DC45F), Color(0xFFA259FF), Color(0xFFFF8A3D), Color(0xFFFF4F81), Color(0xFF22B8CF), Color(0xFFE8B923)];

  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 10);
    const rect = Rect.fromLTWH(0, 0, 10, 10);
    c.drawRect(rect, Paint()..shader = const LinearGradient(colors: [Color(0xFF0E6B5C), Color(0xFF0A4A57)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(rect));
    for (var n = 1; n <= 100; n++) {
      final o = _c(n);
      final i = n - 1, chk = (i % 10 + i ~/ 10).isEven;
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: .94, height: .94), const Radius.circular(.14));
      Color col = chk ? const Color(0xFFFFF7E8) : const Color(0xFFDDF4E7);
      if (n == 1) col = const Color(0xFFB9F0CF);
      if (n == 100) col = const Color(0xFFFFE08A);
      c.drawRRect(r, Paint()..color = col);
      final tp = TextPainter(
        text: TextSpan(text: n == 1 ? 'শুরু' : n == 100 ? '১০০' : '$n', style: const TextStyle(fontSize: .27, color: Color(0xFF5E6B80), fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(o.dx - .41, o.dy - .42));
    }
    c.drawPath(star5(_c(100) + const Offset(.05, .12), .26, .11), Paint()..color = const Color(0xFFFF9F1C));

    // মই
    _jumps.forEach((a, b) {
      if (b > a) _ladder(c, _c(a), _c(b));
    });
    // সাপ
    var k = 0;
    _jumps.forEach((a, b) {
      if (b < a) {
        _snake(c, a, b, snakeCols[k % snakeCols.length]);
        k++;
      }
    });
  }

  void _ladder(Canvas c, Offset p, Offset q) {
    final d = q - p, dist = d.distance;
    final n = Offset(-d.dy, d.dx) / dist;
    const off = .15;
    const sh = Offset(.04, .06);
    final shadow = Paint()..color = Colors.black.withOpacity(.22)..strokeWidth = .13..strokeCap = StrokeCap.round;
    c.drawLine(p + n * off + sh, q + n * off + sh, shadow);
    c.drawLine(p - n * off + sh, q - n * off + sh, shadow);
    final cnt = math.max(2, (dist / .42).floor());
    final rung = Paint()..color = const Color(0xFFB87333)..strokeWidth = .075..strokeCap = StrokeCap.round;
    final rungHi = Paint()..color = const Color(0xFFE6B27A)..strokeWidth = .03..strokeCap = StrokeCap.round;
    for (var k = 1; k <= cnt; k++) {
      final a = p + d * (k / (cnt + 1));
      c.drawLine(a + n * off, a - n * off, rung);
      c.drawLine(a + n * off, a - n * off, rungHi);
    }
    final rail = Paint()..color = const Color(0xFF8A5226)..strokeWidth = .115..strokeCap = StrokeCap.round;
    final railHi = Paint()..color = const Color(0xFFD9A066)..strokeWidth = .045..strokeCap = StrokeCap.round;
    for (final sg in [1.0, -1.0]) {
      c.drawLine(p + n * (off * sg), q + n * (off * sg), rail);
      c.drawLine(p + n * (off * sg), q + n * (off * sg), railHi);
    }
  }

  void _snake(Canvas c, int a, int b, Color base) {
    final pts = _curve(a, b);
    final cnt = pts.length - 1;
    double wd(int i) => .07 + .19 * math.pow(1 - i / cnt, .75).toDouble();
    const sh = Offset(.04, .06);
    for (var i = 0; i < cnt; i++) {
      c.drawLine(pts[i] + sh, pts[i + 1] + sh, Paint()..color = Colors.black.withOpacity(.22)..strokeWidth = wd(i) + .03..strokeCap = StrokeCap.round);
    }
    for (var i = 0; i < cnt; i++) {
      final col = (i ~/ 3).isEven ? base : lighten(base, .22);
      c.drawLine(pts[i], pts[i + 1], Paint()..color = col..strokeWidth = wd(i)..strokeCap = StrokeCap.round);
    }
    for (var i = 0; i < cnt; i++) {
      c.drawLine(pts[i], pts[i + 1], Paint()..color = Colors.white.withOpacity(.25)..strokeWidth = wd(i) * .32..strokeCap = StrokeCap.round);
    }
    final dir = pts[1] - pts[0];
    final ang = math.atan2(-dir.dy, -dir.dx);
    c.save();
    c.translate(pts[0].dx, pts[0].dy);
    c.rotate(ang);
    final tongue = Paint()..color = const Color(0xFFFF3B5C)..strokeWidth = .035..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    c.drawPath(Path()..moveTo(.22, 0)..lineTo(.42, 0)..moveTo(.42, 0)..lineTo(.5, -.06)..moveTo(.42, 0)..lineTo(.5, .06), tongue);
    final head = Rect.fromCenter(center: const Offset(.05, 0), width: .46, height: .36);
    c.drawOval(head, Paint()..color = lighten(base, .08));
    c.drawOval(head, Paint()..style = PaintingStyle.stroke..strokeWidth = .04..color = darken(base, .25));
    for (final sg in [-1.0, 1.0]) {
      c.drawCircle(Offset(.1, .1 * sg), .065, Paint()..color = Colors.white);
      c.drawCircle(Offset(.12, .1 * sg), .032, Paint()..color = const Color(0xFF1A1033));
    }
    c.restore();
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
    c.scale(s.width / 10);
    final list = <List<Object>>[];
    for (var i = 0; i < pos.length; i++) {
      var o = _c(pos[i] == 0 ? 1 : pos[i]) + Offset((i % 2 - .5) * .36, (i ~/ 2 - .5) * .3 + .08);
      var lift = 0.0;
      final r = routes[i];
      if (r != null) {
        final a = routeAt(r, mvA.value);
        o = a.o + Offset((i % 2 - .5) * .12, .08);
        lift = a.lift;
      }
      list.add([o, lift, i]);
    }
    list.sort((a, b) => (a[0] as Offset).dy.compareTo((b[0] as Offset).dy));
    for (final e in list) {
      final i = e[2] as int;
      drawToken(c, e[0] as Offset, kCol[i], .24, glow: i == turn && !over, lift: e[1] as double);
    }
  }

  @override
  bool shouldRepaint(covariant _TokenPainter old) => true;
}
