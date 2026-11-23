import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'common.dart';
import 'net.dart';

const _jumps = {
  1: 38, 4: 14, 9: 31, 21: 42, 28: 84, 36: 44, 51: 67, 71: 91, 80: 100,
  16: 6, 47: 26, 49: 11, 56: 53, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 98: 78,
};

Offset _c(int n) {
  final i = n - 1, r = i ~/ 10, c = r.isEven ? i % 10 : 9 - i % 10;
  return Offset(c + .5, 9 - r + .5);
}

class SnakePage extends StatefulWidget {
  final int n;
  final bool vsPc;
  final Net? net;
  const SnakePage(this.n, this.vsPc, {super.key, this.net});
  @override
  State<SnakePage> createState() => _SnakeState();
}

class _SnakeState extends State<SnakePage> with NetMix<SnakePage> {
  @override
  Net? get net => widget.net;
  bool ready = false;

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
  bool busy = false, over = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    pos = List.filled(widget.n, 0);
    bots = List.generate(widget.n, (i) => widget.vsPc && i > 0);
    turn = 0; dice = 0; busy = false; over = false;
    setState(() {});
    _auto();
  }

  void _auto() {
    ready = true;
    if (bots[turn] && !over) Future.delayed(const Duration(milliseconds: 800), () { if (mounted) _roll(); });
  }

  void _roll() {
    if (busy || over || !ready) return;
    ready = false;
    busy = true;
    var k = 0;
    Timer.periodic(const Duration(milliseconds: 70), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => dice = rnd.nextInt(6) + 1);
      if (++k >= 8) { t.cancel(); _move(); }
    });
  }

  void _move() {
    var np = pos[turn] + dice;
    if (np > 100) np = pos[turn];
    setState(() => pos[turn] = np);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => pos[turn] = _jumps[np] ?? np);
      busy = false;
      if (pos[turn] == 100) {
        over = true;
        showWin(context, kNames[turn], kCol[turn], net == null ? _init : () => Navigator.pop(context));
      } else if (dice == 6) {
        _auto();
      } else {
        setState(() { turn = (turn + 1) % widget.n; });
        _auto();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('সাপ-লুডু'), backgroundColor: Colors.transparent,
            actions: [if (net == null) IconButton(onPressed: _init, icon: const Icon(Icons.refresh_rounded))]),
        body: SafeArea(
          child: Column(children: [
            TurnBar(List.generate(widget.n, (i) => i), turn, bots),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AspectRatio(aspectRatio: 1, child: CustomPaint(painter: _SnakePainter(pos), size: Size.infinite)),
                ),
              ),
            ),
            DiceView(dice, active: !bots[turn] && !busy && canAct(turn), color: kCol[turn], onTap: bots[turn] ? null : _uRoll),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('ডাইসে ট্যাপ করুন', style: TextStyle(color: Colors.white54)),
            ),
          ]),
        ),
      );
}

class _SnakePainter extends CustomPainter {
  final List<int> pos;
  _SnakePainter(this.pos);
  static const pal = [Color(0xFFFFE5EC), Color(0xFFE0F7F4), Color(0xFFFFF3D6), Color(0xFFE3EEFF)];

  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 10);
    c.clipRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 10, 10), const Radius.circular(.5)));
    for (var n = 1; n <= 100; n++) {
      final o = _c(n);
      c.drawRect(Rect.fromCenter(center: o, width: 1, height: 1), Paint()..color = pal[(n + (n - 1) ~/ 10) % 4]);
      final tp = TextPainter(
          text: TextSpan(text: '$n', style: const TextStyle(fontSize: .3, color: Colors.black38, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr)..layout();
      tp.paint(c, o - const Offset(.42, .42));
    }
    _jumps.forEach((a, b) {
      final p = _c(a), q = _c(b);
      if (b > a) {
        final d = (q - p), nrm = Offset(-d.dy, d.dx) / d.distance * .13;
        final lp = Paint()..color = const Color(0xFF8D5B2E)..strokeWidth = .09..strokeCap = StrokeCap.round;
        c.drawLine(p + nrm, q + nrm, lp);
        c.drawLine(p - nrm, q - nrm, lp);
        for (var t = .08; t < 1; t += .9 / (d.distance / .45)) {
          c.drawLine(p + d * t + nrm, p + d * t - nrm, lp..strokeWidth = .06);
        }
      } else {
        final m = (p + q) / 2, d = q - p;
        final ctl = m + Offset(-d.dy, d.dx) / d.distance * .9;
        final col = HSVColor.fromAHSV(1, (a * 37 % 360).toDouble(), .7, .85).toColor();
        final path = Path()..moveTo(p.dx, p.dy)..quadraticBezierTo(ctl.dx, ctl.dy, q.dx, q.dy);
        c.drawPath(path, Paint()..color = col.withOpacity(.9)..style = PaintingStyle.stroke..strokeWidth = .22..strokeCap = StrokeCap.round);
        c.drawCircle(p, .22, Paint()..color = col);
        c.drawCircle(p + const Offset(-.07, -.05), .04, Paint()..color = Colors.white);
        c.drawCircle(p + const Offset(.07, -.05), .04, Paint()..color = Colors.white);
      }
    });
    for (var i = 0; i < pos.length; i++) {
      final o = _c(pos[i] == 0 ? 1 : pos[i]) + Offset((i % 2 - .5) * .4, (i ~/ 2 - .5) * .4 + .1);
      c.drawCircle(o + const Offset(0, .05), .22, Paint()..color = Colors.black26);
      c.drawCircle(o, .22, Paint()..color = Colors.white);
      c.drawCircle(o, .17, Paint()..color = kCol[i]);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
