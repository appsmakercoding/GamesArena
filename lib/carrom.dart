import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'common.dart';
import 'net.dart';
import 'game_ui.dart';
import 'ui.dart';

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

  late Ticker _ticker;
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
    _ticker = createTicker((_) {
      if (!moving) return;
      for (var i = 0; i < 4; i++) _step();
      setState(() {});
      final all = [...coins.where((c) => c.alive), if (striker.alive) striker];
      if (all.every((c) => c.vx.abs() + c.vy.abs() < .0012)) _settle();
    })..start();
    _init();
  }

  @override
  void dispose() { _ticker.dispose(); super.dispose(); }

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
      final rw = giveWinReward(vsPc: widget.vsPc, turn: w, net: net);
      showWin(context, playerName(w, n: 2, bots: [false, widget.vsPc], vsPc: widget.vsPc, net: net), w == 0 ? kCol[2] : kCol[3],
          net == null ? _init : () => Navigator.pop(context), reward: rw);
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
    final scores = [9 - wl, 9 - bl];
    final names = [for (var p = 0; p < 2; p++) playerName(p, n: 2, bots: [false, widget.vsPc], vsPc: widget.vsPc, net: net)];
    final canAim = !moving && !bot && canAct(turn) && !over;
    return GameScaffold(
      title: 'ক্যারাম বোর্ড',
      onRestart: net == null ? _init : null,
      child: LayoutBuilder(builder: (_, bc) {
        final size = min(bc.maxWidth - 24, bc.maxHeight - 58 - 56 - 40 - 24).clamp(220.0, 640.0).toDouble();
        final fr = size * .07, sw = size - 2 * fr;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: size,
                height: size,
                child: GestureDetector(
                  onPanUpdate: (d) {
                    if (canAim) setState(() => drag = Offset((d.localPosition.dx - fr) / sw, (d.localPosition.dy - fr) / sw));
                  },
                  onPanEnd: (_) {
                    if (drag == null || moving || bot) return;
                    final v = striker.o - drag!;
                    if (v.distance > .02) {
                      _userShot(v, (v.distance / .3).clamp(.15, 1.0).toDouble());
                    } else {
                      setState(() => drag = null);
                    }
                  },
                  child: CustomPaint(painter: _CarromPainter(coins, striker, drag, turn, fr, sw, canAim), size: Size(size, size)),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(activeTrackColor: AC.gold, thumbColor: AC.gold, inactiveTrackColor: Colors.white24, overlayColor: AC.gold.withOpacity(.2)),
                child: Slider(
                  value: sx, min: .15, max: .85,
                  onChanged: !canAim ? null : (v) => setState(() { sx = v; striker.x = v; }),
                ),
              ),
              SizedBox(
                height: 26,
                child: Text(moving ? '' : msg, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
              ),
              PlayerStrip([
                for (var p = 0; p < 2; p++)
                  PlayerChip(
                    name: names[p],
                    sub: 'স্কোর ${bnNum(scores[p])} · ${p == 0 ? 'সাদা' : 'কালো'}',
                    color: kCol[p == 0 ? 2 : 3],
                    active: turn == p && !over,
                  ),
              ]),
              const SizedBox(height: 8),
            ]),
          ),
        );
      }),
    );
  }
}

class _CarromPainter extends CustomPainter {
  final List<_Coin> coins;
  final _Coin striker;
  final Offset? drag;
  final int turn;
  final double fr, sw;
  final bool canAim;
  _CarromPainter(this.coins, this.striker, this.drag, this.turn, this.fr, this.sw, this.canAim);

  void _disc(Canvas c, _Coin k, List<Color> g, Color rim, Color ring) {
    c.drawCircle(k.o + const Offset(.003, .008), k.r * 1.02, Paint()..color = Colors.black.withOpacity(.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, .004));
    c.drawCircle(k.o, k.r, Paint()..color = rim);
    c.drawCircle(k.o, k.r * .9, Paint()..shader = RadialGradient(center: const Alignment(-.4, -.5), colors: g).createShader(Rect.fromCircle(center: k.o, radius: k.r)));
    final rp = Paint()..style = PaintingStyle.stroke..strokeWidth = k.r * .09..color = ring;
    c.drawCircle(k.o, k.r * .66, rp);
    c.drawCircle(k.o, k.r * .36, rp);
    c.drawCircle(k.o + Offset(-k.r * .35, -k.r * .4), k.r * .14, Paint()..color = Colors.white.withOpacity(.5));
  }

  Offset _ray(Offset o, Offset d) {
    var p = o;
    for (var i = 0; i < 170; i++) {
      p += d * .006;
      if (p.dx < _rs || p.dx > 1 - _rs || p.dy < _rs || p.dy > 1 - _rs) return p;
      for (final k in coins) {
        if (k.alive && (k.o - p).distance < _rs + _rc) return p;
      }
    }
    return p;
  }

  @override
  void paint(Canvas c, Size s) {
    final S = s.width;
    // কাঠের ফ্রেম
    final outer = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, S, S), Radius.circular(S * .05));
    c.drawRRect(outer, Paint()..shader = const LinearGradient(colors: [Color(0xFFB57338), Color(0xFF7A4520), Color(0xFF9A5C2B)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(Rect.fromLTWH(0, 0, S, S)));
    c.drawRRect(outer, Paint()..style = PaintingStyle.stroke..strokeWidth = S * .008..color = const Color(0xFF4A2810));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(fr * .35, fr * .35, S - fr * .7, S - fr * .7), Radius.circular(S * .035)),
        Paint()..style = PaintingStyle.stroke..strokeWidth = S * .004..color = const Color(0xFFD9A066).withOpacity(.7));

    c.translate(fr, fr);
    c.scale(sw);
    const full = Rect.fromLTWH(0, 0, 1, 1);
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(full, const Radius.circular(.012)));
    c.drawRect(full, Paint()..shader = const RadialGradient(colors: [Color(0xFFF9E8C0), Color(0xFFEBCB8D)], radius: .85).createShader(full));
    final ln = Paint()..color = const Color(0xFF8B5A2B)..style = PaintingStyle.stroke..strokeWidth = .004;
    c.drawRect(const Rect.fromLTWH(.15, .14, .7, .72), ln);
    c.drawCircle(const Offset(.5, .5), .13, ln);
    c.drawCircle(const Offset(.5, .5), .155, Paint()..color = const Color(0xFF8B5A2B).withOpacity(.55)..style = PaintingStyle.stroke..strokeWidth = .003);
    c.drawCircle(const Offset(.5, .5), .03, Paint()..color = const Color(0xFFD9534F).withOpacity(.5));
    for (final x in [.15, .85]) {
      for (final y in [.14, .86]) {
        final dx = x < .5 ? -1.0 : 1.0, dy = y < .5 ? -1.0 : 1.0;
        c.drawLine(Offset(x, y), Offset(x + dx * .09, y + dy * .09), ln);
        c.drawCircle(Offset(x, y), .026, Paint()..color = const Color(0xFFD9534F));
        c.drawCircle(Offset(x, y), .026, Paint()..style = PaintingStyle.stroke..strokeWidth = .004..color = const Color(0xFF8E2B2B));
      }
    }
    c.restore();

    // পকেট
    for (final k in _corners) {
      c.drawCircle(k, .078, Paint()..shader = const RadialGradient(colors: [Color(0xFF000000), Color(0xFF1B1B26)], stops: [.6, 1]).createShader(Rect.fromCircle(center: k, radius: .078)));
      c.drawCircle(k, .078, Paint()..style = PaintingStyle.stroke..strokeWidth = .006..color = const Color(0xFF3A2312));
    }

    // গুটি
    for (final k in coins.where((k) => k.alive)) {
      if (k.type == 0) _disc(c, k, const [Colors.white, Color(0xFFE8DDC8)], const Color(0xFFCFC3AB), const Color(0xFFB9AA8B));
      if (k.type == 1) _disc(c, k, const [Color(0xFF55566A), Color(0xFF15151E)], Colors.black, const Color(0xFF7A7B90));
      if (k.type == 2) _disc(c, k, const [Color(0xFFFF7088), Color(0xFFD01C3E)], const Color(0xFF8E1330), const Color(0xFFFFB3C0));
    }
    if (striker.alive) _disc(c, striker, const [Color(0xFFFFE27A), Color(0xFFE59A12)], const Color(0xFFB36B00), const Color(0xFFFFF3B0));

    // এইম গাইড
    if (drag != null) {
      final v = striker.o - drag!;
      if (v.distance > .01) {
        final d = v / v.distance;
        final end = _ray(striker.o, d);
        final len = (end - striker.o).distance;
        for (var t = .04; t < len; t += .026) {
          c.drawCircle(striker.o + d * t, .0045, Paint()..color = Colors.white.withOpacity(.95));
        }
        c.drawPath(star5(end, .018, .008), Paint()..color = Colors.white);
        c.drawLine(striker.o, drag!, Paint()..color = kCol[1].withOpacity(.85)..strokeWidth = .008..strokeCap = StrokeCap.round);
        c.drawCircle(drag!, .014, Paint()..color = kCol[1]);
      }
    }

    // পাওয়ার বার (ডান ফ্রেমে)
    final pw = drag == null ? 0.0 : ((striker.o - drag!).distance / .3).clamp(.0, 1.0).toDouble();
    final track = RRect.fromRectAndRadius(const Rect.fromLTWH(1.02, .25, .028, .5), const Radius.circular(.014));
    c.drawRRect(track, Paint()..color = Colors.black.withOpacity(.4));
    if (pw > 0) {
      final h = .5 * pw;
      final f = RRect.fromRectAndRadius(Rect.fromLTWH(1.02, .75 - h, .028, h), const Radius.circular(.014));
      c.drawRRect(f, Paint()..shader = const LinearGradient(colors: [Color(0xFF2EE66B), Color(0xFFFFC83D), Color(0xFFFF4D6D)], begin: Alignment.bottomCenter, end: Alignment.topCenter).createShader(const Rect.fromLTWH(1.02, .25, .028, .5)));
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
