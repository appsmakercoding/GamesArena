import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'common.dart';
import 'net.dart';

const _rc = .034, _rs = .044, _vmax = .02;
const _corners = [Offset(0, 0), Offset(1, 0), Offset(0, 1), Offset(1, 1)];

class _Coin {
  double x, y, vx = 0, vy = 0;
  final int type; // 0 white, 1 black, 2 queen, 3 striker
  bool alive = true;
  _Coin(this.x, this.y, this.type);
  double get r => type == 3 ? _rs : _rc;
  Offset get o => Offset(x, y);
}

class CarromPage extends StatefulWidget {
  final bool vsPc;
  final Net? net;
  const CarromPage(this.vsPc, {super.key, this.net});
  @override
  State<CarromPage> createState() => _CarromState();
}

class _CarromState extends State<CarromPage> with SingleTickerProviderStateMixin, NetMix<CarromPage> {
  @override
  Net? get net => widget.net;

  @override
  bool remote(Map a) {
    if (moving || over) return false;
    sx = (a['x'] as num).toDouble();
    striker.x = sx;
    _shoot(Offset((a['dx'] as num).toDouble(), (a['dy'] as num).toDouble()), (a['p'] as num).toDouble());
    return true;
  }

  void _userShot(Offset v, double p) {
    if (!canAct(turn)) { setState(() => drag = null); return; }
    emit({'x': sx, 'dx': v.dx, 'dy': v.dy, 'p': p});
    _shoot(v, p);
  }

  late Ticker tick;
  List<_Coin> coins = [];
  late _Coin striker;
  int turn = 0;
  double sx = .5;
  Offset? drag;
  bool moving = false, over = false;
  List<int> got = [];
  String msg = 'স্ট্রাইকার টেনে ছেড়ে দিন';
  bool get bot => widget.vsPc && turn == 1;

  @override
  void initState() {
    super.initState();
    tick = createTicker((_) {
      if (!moving) return;
      for (var i = 0; i < 4; i++) _step();
      setState(() {});
      final all = [...coins.where((c) => c.alive), if (striker.alive) striker];
      if (all.every((c) => c.vx.abs() + c.vy.abs() < .0012)) _settle();
    })..start();
    _init();
  }

  @override
  void dispose() { tick.dispose(); super.dispose(); }

  void _init() {
    coins = [_Coin(.5, .5, 2)];
    for (var k = 0; k < 6; k++) coins.add(_Coin(.5 + .071 * cos(k * pi / 3), .5 + .071 * sin(k * pi / 3), k % 2));
    for (var k = 0; k < 12; k++) {
      final r = k % 2 == 0 ? .142 : .134;
      coins.add(_Coin(.5 + r * cos(k * pi / 6), .5 + r * sin(k * pi / 6), (k ~/ 2) % 2 == 0 ? 0 : 1));
    }
    turn = 0; over = false; moving = false; sx = .5; msg = 'স্ট্রাইকার টেনে ছেড়ে দিন';
    _reset();
  }

  void _reset() {
    striker = _Coin(sx, turn == 0 ? .86 : .14, 3);
    setState(() {});
    if (bot && !over) Future.delayed(const Duration(milliseconds: 1000), _botShoot);
  }

  void _step() {
    final all = [...coins.where((c) => c.alive), if (striker.alive) striker];
    for (final c in all) {
      c.x += c.vx; c.y += c.vy; c.vx *= .9955; c.vy *= .9955;
      for (final k in _corners) {
        if ((c.o - k).distance < .075) { c.alive = false; got.add(c.type); c.vx = c.vy = 0; break; }
      }
      if (!c.alive) continue;
      if (c.x < c.r) { c.x = c.r; c.vx = -c.vx * .8; }
      if (c.x > 1 - c.r) { c.x = 1 - c.r; c.vx = -c.vx * .8; }
      if (c.y < c.r) { c.y = c.r; c.vy = -c.vy * .8; }
      if (c.y > 1 - c.r) { c.y = 1 - c.r; c.vy = -c.vy * .8; }
    }
    final a = all.where((c) => c.alive).toList();
    for (var i = 0; i < a.length; i++) {
      for (var j = i + 1; j < a.length; j++) {
        final p = a[i], q = a[j];
        final dx = q.x - p.x, dy = q.y - p.y, d = sqrt(dx * dx + dy * dy), md = p.r + q.r;
        if (d >= md || d == 0) continue;
        final nx = dx / d, ny = dy / d, mp = p.type == 3 ? 2.0 : 1.0, mq = q.type == 3 ? 2.0 : 1.0;
        final ov = md - d;
        p.x -= nx * ov * mq / (mp + mq); p.y -= ny * ov * mq / (mp + mq);
        q.x += nx * ov * mp / (mp + mq); q.y += ny * ov * mp / (mp + mq);
        final vn = (q.vx - p.vx) * nx + (q.vy - p.vy) * ny;
        if (vn < 0) {
          final j2 = -(1.9) * vn / (1 / mp + 1 / mq);
          p.vx -= j2 / mp * nx; p.vy -= j2 / mp * ny;
          q.vx += j2 / mq * nx; q.vy += j2 / mq * ny;
        }
      }
    }
  }

  void _settle() {
    moving = false;
    for (final c in [...coins, striker]) { c.vx = c.vy = 0; }
    final foul = !striker.alive;
    final opp = got.contains(1 - turn);
    final mine = got.any((t) => t == turn || t == 2);
    final extra = !foul && mine && !opp;
    msg = foul ? 'ফাউল! স্ট্রাইকার পকেটে' : extra ? 'দারুণ! আবার চাল' : opp ? 'প্রতিপক্ষের কয়েন পড়েছে' : '';
    final wl = coins.where((c) => c.alive && c.type == 0).length, bl = coins.where((c) => c.alive && c.type == 1).length;
    if (wl == 0 || bl == 0) {
      over = true;
      final w = wl == 0 ? 0 : 1;
      showWin(context, w == 0 ? 'সাদা' : 'কালো', w == 0 ? Colors.white : Colors.grey, net == null ? _init : () => Navigator.pop(context));
      return;
    }
    if (!extra) turn = 1 - turn;
    _reset();
  }

  void _shoot(Offset dir, double power) {
    final d = dir / dir.distance;
    striker.vx = d.dx * _vmax * power; striker.vy = d.dy * _vmax * power;
    got = []; moving = true; drag = null;
  }

  void _botShoot() {
    if (!mounted || moving || over || !bot) return;
    Offset? bestDir; var bc = 1e9; var bp = .8; var bx = .5;
    for (final c in coins.where((c) => c.alive && (c.type == 1 || c.type == 2))) {
      for (final k in _corners) {
        final dir = (k - c.o) / (k - c.o).distance;
        final ghost = c.o - dir * (_rc + _rs);
        for (final x in [.2, .3, .4, .5, .6, .7, .8]) {
          final v = ghost - Offset(x, .14);
          if (v.dy <= 0) continue;
          final dot = (v / v.distance).dx * dir.dx + (v / v.distance).dy * dir.dy;
          if (dot < .35) continue;
          final cost = v.distance + (k - c.o).distance * .5 - dot * .4;
          if (cost < bc) { bc = cost; bestDir = v; bx = x; bp = (.4 + (v.distance + (k - c.o).distance) * .45).clamp(.45, 1.0).toDouble(); }
        }
      }
    }
    sx = bx; striker.x = bx;
    var dir = bestDir ?? Offset(rnd.nextDouble() - .5, 1);
    final a = (rnd.nextDouble() - .5) * .05;
    dir = Offset(dir.dx * cos(a) - dir.dy * sin(a), dir.dx * sin(a) + dir.dy * cos(a));
    _shoot(dir, bp);
  }

  @override
  Widget build(BuildContext context) {
    final wl = coins.where((c) => c.alive && c.type == 0).length, bl = coins.where((c) => c.alive && c.type == 1).length;
    return Scaffold(
      appBar: AppBar(title: const Text('ক্যারাম বোর্ড'), backgroundColor: Colors.transparent,
          actions: [if (net == null) IconButton(onPressed: _init, icon: const Icon(Icons.refresh_rounded))]),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final p in [0, 1])
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: turn == p ? kCol[p == 0 ? 2 : 3] : Colors.white10, borderRadius: BorderRadius.circular(24)),
                  child: Text('${p == 0 ? '⚪ সাদা' : '⚫ কালো${widget.vsPc ? ' 🤖' : ''}'}: ${p == 0 ? wl : bl}', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
            ]),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF5D4037), borderRadius: BorderRadius.circular(24)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(builder: (_, bc) {
                      final w = bc.maxWidth;
                      return GestureDetector(
                        onPanUpdate: (d) { if (!moving && !bot && canAct(turn)) setState(() => drag = d.localPosition / w); },
                        onPanEnd: (_) {
                          if (drag == null || moving || bot) return;
                          final v = striker.o - drag!;
                          if (v.distance > .02) _userShot(v, (v.distance / .3).clamp(.15, 1.0).toDouble()); else setState(() => drag = null);
                        },
                        child: CustomPaint(painter: _CarromPainter(coins, striker, drag, turn), size: Size.infinite),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          Slider(
            value: sx, min: .15, max: .85,
            onChanged: moving || bot || !canAct(turn) ? null : (v) => setState(() { sx = v; striker.x = v; }),
          ),
          Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(msg, style: const TextStyle(color: Colors.white60))),
        ]),
      ),
    );
  }
}

class _CarromPainter extends CustomPainter {
  final List<_Coin> coins;
  final _Coin striker;
  final Offset? drag;
  final int turn;
  _CarromPainter(this.coins, this.striker, this.drag, this.turn);

  void _disc(Canvas c, _Coin k, Color col, Color rim) {
    c.drawCircle(k.o + const Offset(0, .006), k.r, Paint()..color = Colors.black38);
    c.drawCircle(k.o, k.r, Paint()..color = rim);
    c.drawCircle(k.o, k.r * .78, Paint()..color = col);
    c.drawCircle(k.o + Offset(-k.r * .25, -k.r * .25), k.r * .22, Paint()..color = Colors.white38);
  }

  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width);
    c.clipRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 1, 1), const Radius.circular(.03)));
    c.drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = const Color(0xFFFFE9C7));
    final ln = Paint()..color = const Color(0xFFB8860B)..style = PaintingStyle.stroke..strokeWidth = .004;
    c.drawCircle(const Offset(.5, .5), .13, ln);
    c.drawCircle(const Offset(.5, .5), .03, Paint()..color = const Color(0xFFFF4D6D).withOpacity(.4));
    for (final y in [.14, .86]) {
      c.drawLine(Offset(.15, y), Offset(.85, y), ln);
      c.drawCircle(Offset(.15, y), .018, ln);
      c.drawCircle(Offset(.85, y), .018, ln);
    }
    for (final k in _corners) {
      c.drawCircle(k, .07, Paint()..color = const Color(0xFF1B1B2F));
    }
    for (final k in coins.where((k) => k.alive)) {
      if (k.type == 0) _disc(c, k, Colors.white, const Color(0xFFD7CCC8));
      if (k.type == 1) _disc(c, k, const Color(0xFF2B2B3C), const Color(0xFF000000));
      if (k.type == 2) _disc(c, k, const Color(0xFFFF4D6D), const Color(0xFFB71C3C));
    }
    if (striker.alive) _disc(c, striker, kCol[turn == 0 ? 2 : 3], Colors.white);
    if (drag != null) {
      final v = striker.o - drag!;
      if (v.distance > .01) {
        final d = v / v.distance;
        c.drawLine(striker.o, striker.o + d * (.12 + v.distance), Paint()..color = Colors.black54..strokeWidth = .006);
        c.drawLine(striker.o, drag!, Paint()..color = kCol[1]..strokeWidth = .008..strokeCap = StrokeCap.round);
      }
    }
  }
  @override
  bool shouldRepaint(_) => true;
}
