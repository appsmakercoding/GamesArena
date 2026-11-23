import 'dart:async';
import 'package:flutter/material.dart';
import 'common.dart';
import 'net.dart';

List<Offset> _mk() {
  final r = <Offset>[];
  void a(int x, int y, int dx, int dy, int n) {
    for (var i = 0; i < n; i++) r.add(Offset(x + dx * i + .5, y + dy * i + .5));
  }
  a(1, 6, 1, 0, 5); a(6, 5, 0, -1, 6); a(7, 0, 1, 0, 2); a(8, 1, 0, 1, 5);
  a(9, 6, 1, 0, 6); a(14, 7, 0, 1, 2); a(13, 8, -1, 0, 5); a(8, 9, 0, 1, 6);
  a(7, 14, -1, 0, 2); a(6, 13, 0, -1, 5); a(5, 8, -1, 0, 6); a(0, 7, 0, -1, 2);
  return r;
}

final _path = _mk();
const _start = [0, 13, 26, 39];
const _safe = {0, 8, 13, 21, 26, 34, 39, 47};
const _dir = [Offset(-1, 0), Offset(0, -1), Offset(1, 0), Offset(0, 1)];
const _hd = [[1, 7, 1, 0], [7, 1, 0, 1], [13, 7, -1, 0], [7, 13, 0, -1]];
List<Offset> _home(int i) {
  final d = _hd[i];
  return List.generate(5, (k) => Offset(d[0] + d[2] * k + .5, d[1] + d[3] * k + .5));
}

int _abs(int pl, int p) => (_start[pl] + p) % 52;

Offset _where(int pl, int p, int t) {
  if (p < 0) {
    return Offset([0, 9, 9, 0][pl] + (t % 2 == 0 ? 1.5 : 4.5), [0, 0, 9, 9][pl] + (t < 2 ? 1.5 : 4.5));
  }
  if (p <= 50) return _path[_abs(pl, p)];
  if (p < 56) return _home(pl)[p - 51];
  return const Offset(7.5, 7.5) + _dir[pl] * .9 + Offset((t - 1.5) * .14, 0);
}

class LudoPage extends StatefulWidget {
  final int n;
  final bool vsPc;
  final Net? net;
  const LudoPage(this.n, this.vsPc, {super.key, this.net});
  @override
  State<LudoPage> createState() => _LudoState();
}

class _LudoState extends State<LudoPage> with NetMix<LudoPage> {
  @override
  Net? get net => widget.net;
  bool ready = false;

  @override
  bool remote(Map a) {
    if (!ready) return false;
    if (a['t'] == 'r' && mov.isEmpty) { _roll(); return true; }
    if (a['t'] == 'm' && mov.contains(a['k'])) { _move(a['k'] as int); return true; }
    return false;
  }

  void _uRoll() {
    if (!canAct(turn) || !ready || busy || mov.isNotEmpty) return;
    emit({'t': 'r'});
    _roll();
  }

  late List<int> seats;
  late List<bool> bots;
  late List<List<int>> pos;
  int turn = 0, dice = 0;
  bool busy = false, over = false;
  List<int> mov = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    seats = widget.n == 2 ? [0, 2] : widget.n == 3 ? [0, 1, 2] : [0, 1, 2, 3];
    bots = List.generate(widget.n, (i) => widget.vsPc && i > 0);
    pos = List.generate(widget.n, (_) => List.filled(4, -1));
    turn = 0; dice = 0; busy = false; over = false; mov = [];
    setState(() {});
    _auto();
  }

  void _auto() {
    ready = true;
    if (bots[turn] && !over) Future.delayed(const Duration(milliseconds: 800), () { if (mounted) _roll(); });
  }

  void _roll() {
    if (busy || over || mov.isNotEmpty || !ready) return;
    ready = false;
    busy = true;
    var k = 0;
    Timer.periodic(const Duration(milliseconds: 70), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => dice = rnd.nextInt(6) + 1);
      if (++k >= 8) {
        t.cancel();
        busy = false;
        _afterRoll();
      }
    });
  }

  void _afterRoll() {
    final m = <int>[];
    for (var t = 0; t < 4; t++) {
      final p = pos[turn][t];
      if (p == -1 ? dice == 6 : p + dice <= 56) m.add(t);
    }
    if (m.isEmpty) {
      Future.delayed(const Duration(milliseconds: 700), _next);
      return;
    }
    if (bots[turn] || m.length == 1) {
      Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _move(bots[turn] ? _ai(m) : m[0]); });
    } else {
      setState(() => mov = m);
      ready = true;
    }
  }

  int _ai(List<int> m) {
    int best = m[0], bs = -999;
    final pl = seats[turn];
    for (final t in m) {
      final p = pos[turn][t], np = p == -1 ? 0 : p + dice;
      var s = np.toDouble();
      if (p == -1) s += 40;
      if (np >= 51) s += 30;
      if (np <= 50 && _safe.contains(_abs(pl, np))) s += 15;
      if (np <= 50) {
        for (var j = 0; j < widget.n; j++) {
          if (j == turn) continue;
          for (final q in pos[j]) {
            if (q >= 0 && q <= 50 && _abs(seats[j], q) == _abs(pl, np) && !_safe.contains(_abs(pl, np))) s += 100;
          }
        }
      }
      if (s > bs) { bs = s.toInt(); best = t; }
    }
    return best;
  }

  void _move(int t) {
    ready = false;
    final pl = seats[turn];
    final p = pos[turn][t];
    final np = p == -1 ? 0 : p + dice;
    var extra = dice == 6 || np == 56;
    setState(() {
      pos[turn][t] = np;
      mov = [];
      if (np <= 50 && !_safe.contains(_abs(pl, np))) {
        for (var j = 0; j < widget.n; j++) {
          if (j == turn) continue;
          for (var u = 0; u < 4; u++) {
            final q = pos[j][u];
            if (q >= 0 && q <= 50 && _abs(seats[j], q) == _abs(pl, np)) { pos[j][u] = -1; extra = true; }
          }
        }
      }
    });
    if (pos[turn].every((e) => e == 56)) {
      over = true;
      showWin(context, kNames[pl], kCol[pl], net == null ? _init : () => Navigator.pop(context));
      return;
    }
    extra ? _auto() : _next();
  }

  void _next() {
    if (!mounted) return;
    setState(() { turn = (turn + 1) % widget.n; dice = 0; });
    _auto();
  }

  void _tap(Offset o, double w) {
    if (mov.isEmpty || bots[turn] || !ready || !canAct(turn)) return;
    final u = Offset(o.dx / w * 15, o.dy / w * 15);
    for (final t in mov) {
      if ((_where(seats[turn], pos[turn][t], t) - u).distance < .9) { emit({'t': 'm', 'k': t}); _move(t); return; }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pl = seats[turn];
    return Scaffold(
      appBar: AppBar(title: const Text('লুডু'), backgroundColor: Colors.transparent,
          actions: [if (net == null) IconButton(onPressed: _init, icon: const Icon(Icons.refresh_rounded))]),
      body: SafeArea(
        child: Column(children: [
          TurnBar(seats, turn, bots),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (_, bc) => GestureDetector(
                      onTapUp: (d) => _tap(d.localPosition, bc.maxWidth),
                      child: CustomPaint(painter: _LudoPainter(pos, seats, mov, turn), size: Size.infinite),
                    ),
                  ),
                ),
              ),
            ),
          ),
          DiceView(dice, active: !bots[turn] && !busy && mov.isEmpty && canAct(turn), color: kCol[pl], onTap: bots[turn] ? null : _uRoll),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(mov.isNotEmpty ? 'গুটি বেছে নিন' : 'ডাইসে ট্যাপ করুন',
                style: const TextStyle(color: Colors.white54)),
          ),
        ]),
      ),
    );
  }
}

class _LudoPainter extends CustomPainter {
  final List<List<int>> pos;
  final List<int> seats, mov;
  final int turn;
  _LudoPainter(this.pos, this.seats, this.mov, this.turn);

  RRect _r(double x, double y, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 15);
    c.drawRRect(_r(0, 0, 15, 15, .7), Paint()..color = const Color(0xFFF7F5FF));
    for (var i = 0; i < 4; i++) {
      final ox = [0, 9, 9, 0][i].toDouble(), oy = [0, 0, 9, 9][i].toDouble();
      c.drawRRect(_r(ox + .15, oy + .15, 5.7, 5.7, .6), Paint()..color = kCol[i]);
      c.drawRRect(_r(ox + .8, oy + .8, 4.4, 4.4, .5), Paint()..color = Colors.white);
      for (var t = 0; t < 4; t++) {
        c.drawCircle(_where(i, -1, t), .55, Paint()..color = kCol[i].withOpacity(.25));
      }
    }
    final cell = Paint()..color = Colors.white;
    final line = Paint()..color = const Color(0xFFE2DDF5)..style = PaintingStyle.stroke..strokeWidth = .05;
    for (var i = 0; i < 52; i++) {
      final o = _path[i];
      final r = _r(o.dx - .5 + .04, o.dy - .5 + .04, .92, .92, .18);
      final sc = _start.indexOf(i);
      c.drawRRect(r, Paint()..color = sc >= 0 ? kCol[sc] : Colors.white);
      c.drawRRect(r, line);
      if (_safe.contains(i) && sc < 0) c.drawCircle(o, .17, Paint()..color = const Color(0xFFB8B0DA));
    }
    for (var i = 0; i < 4; i++) {
      for (final o in _home(i)) {
        c.drawRRect(_r(o.dx - .46, o.dy - .46, .92, .92, .18), Paint()..color = kCol[i].withOpacity(.85));
      }
    }
    const ctr = Offset(7.5, 7.5);
    final tri = [
      [const Offset(6, 6), const Offset(6, 9)], [const Offset(6, 6), const Offset(9, 6)],
      [const Offset(9, 6), const Offset(9, 9)], [const Offset(6, 9), const Offset(9, 9)],
    ];
    for (var i = 0; i < 4; i++) {
      c.drawPath(Path()..moveTo(tri[i][0].dx, tri[i][0].dy)..lineTo(tri[i][1].dx, tri[i][1].dy)..lineTo(ctr.dx, ctr.dy)..close(),
          Paint()..color = kCol[i]);
    }
    for (var i = 0; i < seats.length; i++) {
      for (var t = 0; t < 4; t++) {
        final p = pos[i][t];
        var o = _where(seats[i], p, t);
        if (p >= 0 && p < 56) o += Offset((t % 2 - .5) * .22, (t ~/ 2 - .5) * .22);
        if (i == turn && mov.contains(t)) {
          c.drawCircle(o, .72, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = .12);
        }
        c.drawCircle(o + const Offset(0, .08), .46, Paint()..color = Colors.black26);
        c.drawCircle(o, .46, Paint()..color = Colors.white);
        c.drawCircle(o, .36, Paint()..color = kCol[seats[i]]);
        c.drawCircle(o + const Offset(-.1, -.1), .1, Paint()..color = Colors.white54);
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
