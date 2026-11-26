import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'common.dart';
import 'net.dart';

List<Offset> _mk() {
  final r = <Offset>[];
  void a(int x, int y, int dx, int dy, int n) {
    for (var i = 0; i < n; i++) r.add(Offset(x + dx * i + .5, y + dy * i + .5));
  }
  a(1, 6, 1, 0, 5);
  a(6, 5, 0, -1, 6);
  a(7, 0, 1, 0, 2);
  a(8, 1, 0, 1, 5);
  a(9, 6, 1, 0, 6);
  a(14, 7, 0, 1, 2);
  a(13, 8, -1, 0, 5);
  a(8, 9, 0, 1, 6);
  a(7, 14, -1, 0, 2);
  a(6, 13, 0, -1, 5);
  a(5, 8, -1, 0, 6);
  a(0, 7, 0, -1, 2);
  return r;
}

final _path = _mk();
const _start = [0, 13, 26, 39];
const _safe = {0, 8, 13, 21, 26, 34, 39, 47};
const _dir = [Offset(-1, 0), Offset(0, -1), Offset(1, 0), Offset(0, 1)];
const _hd = [
  [1, 7, 1, 0],
  [7, 1, 0, 1],
  [13, 7, -1, 0],
  [7, 13, 0, -1],
];

List<Offset> _home(int i) {
  final d = _hd[i];
  return List.generate(5, (k) => Offset(d[0] + d[2] * k + .5, d[1] + d[3] * k + .5));
}

int _abs(int pl, int p) => (_start[pl] + p) % 52;

Offset _where(int pl, int p, int t) {
  if (p < 0) {
    return Offset(
      [0, 9, 9, 0][pl] + (t % 2 == 0 ? 1.5 : 4.5),
      [0, 0, 9, 9][pl] + (t < 2 ? 1.5 : 4.5),
    );
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
    if (a['t'] == 'r' && mov.isEmpty) {
      _roll();
      return true;
    }
    if (a['t'] == 'm' && mov.contains(a['k'])) {
      _move(a['k'] as int);
      return true;
    }
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
  bool busy = false, over = false, stepping = false;
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
    turn = 0;
    dice = 0;
    busy = false;
    over = false;
    stepping = false;
    mov = [];
    setState(() {});
    _auto();
  }

  void _auto() {
    ready = true;
    if (bots[turn] && !over) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _roll();
      });
    }
  }

  void _roll() {
    if (busy || over || mov.isNotEmpty || !ready) return;
    ready = false;
    busy = true;
    var k = 0;
    Timer.periodic(const Duration(milliseconds: 70), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
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
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _move(bots[turn] ? _ai(m) : m[0]);
      });
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
            if (q >= 0 && q <= 50 && _abs(seats[j], q) == _abs(pl, np) && !_safe.contains(_abs(pl, np))) {
              s += 100;
            }
          }
        }
      }
      if (s > bs) {
        bs = s.toInt();
        best = t;
      }
    }
    return best;
  }

  void _move(int t) {
    if (stepping) return;
    ready = false;
    stepping = true;
    final currentTurn = turn;
    final currentDice = dice;
    final pl = seats[currentTurn];
    final startPos = pos[currentTurn][t];

    setState(() {
      mov = [];
    });

    // If piece is in yard (-1) and rolled 6, move out to start square (0)
    if (startPos < 0) {
      setState(() {
        pos[currentTurn][t] = 0;
      });
      Future.delayed(const Duration(milliseconds: 160), () {
        if (!mounted) return;
        _finishMove(currentTurn, t, pl, 0, currentDice);
      });
      return;
    }

    // Otherwise step 1 square at a time up to currentDice steps
    var step = 0;
    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      step++;
      final nextP = startPos + step;
      setState(() {
        pos[currentTurn][t] = nextP;
      });
      if (step >= currentDice) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 120), () {
          if (!mounted) return;
          _finishMove(currentTurn, t, pl, nextP, currentDice);
        });
      }
    });
  }

  void _finishMove(int currentTurn, int t, int pl, int finalPos, int rolledDice) {
    var extra = rolledDice == 6 || finalPos == 56;
    setState(() {
      if (finalPos <= 50 && !_safe.contains(_abs(pl, finalPos))) {
        for (var j = 0; j < widget.n; j++) {
          if (j == currentTurn) continue;
          for (var u = 0; u < 4; u++) {
            final q = pos[j][u];
            if (q >= 0 && q <= 50 && _abs(seats[j], q) == _abs(pl, finalPos)) {
              pos[j][u] = -1;
              extra = true;
            }
          }
        }
      }
      stepping = false;
    });

    if (pos[currentTurn].every((e) => e == 56)) {
      over = true;
      showWin(context, kNames[pl], kCol[pl], net == null ? _init : () => Navigator.pop(context));
      return;
    }
    extra ? _auto() : _next();
  }

  void _next() {
    if (!mounted) return;
    setState(() {
      turn = (turn + 1) % widget.n;
      dice = 0;
    });
    _auto();
  }

  void _tap(Offset o, double w) {
    if (mov.isEmpty || bots[turn] || !ready || stepping || !canAct(turn)) return;
    final u = Offset(o.dx / w * 15, o.dy / w * 15);
    for (final t in mov) {
      if ((_where(seats[turn], pos[turn][t], t) - u).distance < .95) {
        emit({'t': 'm', 'k': t});
        _move(t);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pl = seats[turn];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D114D), Color(0xFF0C081D), Color(0xFF060410)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        '🎲 লুডু',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (net == null)
                      IconButton(onPressed: _init, icon: const Icon(Icons.refresh_rounded))
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
              TurnBar(seats, turn, bots),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C4DFF).withOpacity(.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: LayoutBuilder(
                          builder: (_, bc) => GestureDetector(
                            onTapUp: (d) => _tap(d.localPosition, bc.maxWidth),
                            child: CustomPaint(
                              painter: _LudoPainter(pos, seats, mov, turn),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kCol[pl].withOpacity(.55)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DiceView(
                      dice,
                      active: !bots[turn] && !busy && !stepping && mov.isEmpty && canAct(turn),
                      color: kCol[pl],
                      onTap: bots[turn] ? null : _uRoll,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${kNames[pl]}-এর চাল',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: kCol[pl],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stepping
                                ? 'গুটি এগোচ্ছে...'
                                : mov.isNotEmpty
                                    ? 'হাইলাইট করা গুটিতে ট্যাপ করুন'
                                    : 'ডাইস ছুড়তে ট্যাপ করুন',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _LudoPainter extends CustomPainter {
  final List<List<int>> pos;
  final List<int> seats, mov;
  final int turn;
  _LudoPainter(this.pos, this.seats, this.mov, this.turn);

  static const _quadCols = [
    Color(0xFF1DA1F2), // Blue (top-left)
    Color(0xFFE53935), // Red (top-right)
    Color(0xFF43A047), // Green (bottom-right)
    Color(0xFFFDD835), // Yellow (bottom-left)
  ];

  RRect _r(double x, double y, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  void _drawStar(Canvas c, Offset o, double rad) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? rad : rad * .45;
      final a = -pi / 2 + i * pi / 5;
      final pt = o + Offset(cos(a) * r, sin(a) * r);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    c.drawPath(
      p,
      Paint()
        ..color = const Color(0xFF546E7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .06,
    );
  }

  void _drawPin(Canvas c, Offset tip, Color baseCol, bool highlight) {
    final center = tip + const Offset(0, -.48);
    const rad = .34;

    if (highlight) {
      c.drawCircle(
        center,
        rad + .18,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = .09,
      );
    }

    // Shadow under pin tip
    c.drawOval(
      Rect.fromCenter(center: tip + const Offset(0, .04), width: .44, height: .16),
      Paint()..color = Colors.black38,
    );

    // Teardrop / map-pin silhouette matching reference
    final pin = Path()
      ..moveTo(tip.dx, tip.dy)
      ..cubicTo(
        tip.dx - .34,
        tip.dy - .26,
        center.dx - rad,
        center.dy + .06,
        center.dx - rad,
        center.dy,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: rad),
        pi,
        pi,
        false,
      )
      ..cubicTo(
        center.dx + rad,
        center.dy + .06,
        tip.dx + .34,
        tip.dy - .26,
        tip.dx,
        tip.dy,
      )
      ..close();

    c.drawPath(pin, Paint()..color = baseCol);
    c.drawPath(
      pin,
      Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .045,
    );

    // Inner glossy ring & white core
    c.drawCircle(center, rad * .62, Paint()..color = Colors.white.withOpacity(.92));
    c.drawCircle(center, rad * .34, Paint()..color = baseCol);
    c.drawCircle(center + const Offset(-.1, -.11), rad * .16, Paint()..color = Colors.white);
  }

  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 15);
    c.drawRRect(_r(0, 0, 15, 15, .55), Paint()..color = const Color(0xFFF8F9FD));

    // 4 Corner Yards
    const yardOrigins = [Offset(0, 0), Offset(9, 0), Offset(9, 9), Offset(0, 9)];
    for (var i = 0; i < 4; i++) {
      final ox = yardOrigins[i].dx, oy = yardOrigins[i].dy;
      final qc = _quadCols[i];
      c.drawRect(Rect.fromLTWH(ox, oy, 6, 6), Paint()..color = qc);
      c.drawRect(
        Rect.fromLTWH(ox + .85, oy + .85, 4.3, 4.3),
        Paint()..color = Colors.white,
      );
      c.drawRect(
        Rect.fromLTWH(ox + .85, oy + .85, 4.3, 4.3),
        Paint()
          ..color = qc.withOpacity(.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .05,
      );
      for (var t = 0; t < 4; t++) {
        final slot = _where(i, -1, t);
        c.drawCircle(slot + const Offset(0, .04), .48, Paint()..color = qc.withOpacity(.28));
        c.drawCircle(slot, .42, Paint()..color = qc.withOpacity(.82));
        c.drawCircle(slot, .22, Paint()..color = Colors.white.withOpacity(.35));
      }
    }

    // Outer track cells
    final line = Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .045;

    for (var i = 0; i < 52; i++) {
      final o = _path[i];
      final rect = Rect.fromCenter(center: o, width: 1, height: 1);
      final sc = _start.indexOf(i);
      c.drawRect(rect, Paint()..color = sc >= 0 ? _quadCols[sc] : Colors.white);
      c.drawRect(rect, line);
      if (_safe.contains(i) && sc < 0) {
        _drawStar(c, o, .33);
      }
    }

    // Colored home columns (5 cells each)
    for (var i = 0; i < 4; i++) {
      for (final o in _home(i)) {
        final rect = Rect.fromCenter(center: o, width: 1, height: 1);
        c.drawRect(rect, Paint()..color = _quadCols[i]);
        c.drawRect(rect, line);
      }
    }

    // Center 3x3 home triangles matching reference orientation
    const ctr = Offset(7.5, 7.5);
    const corners = [
      Offset(6, 6), // top-left
      Offset(9, 6), // top-right
      Offset(9, 9), // bottom-right
      Offset(6, 9), // bottom-left
    ];
    // Left -> Blue (0), Top -> Red (1), Right -> Green (2), Bottom -> Yellow (3)
    const triEdges = [
      [0, 3], // left edge -> Blue
      [0, 1], // top edge -> Red
      [1, 2], // right edge -> Green
      [3, 2], // bottom edge -> Yellow
    ];
    for (var i = 0; i < 4; i++) {
      final p1 = corners[triEdges[i][0]];
      final p2 = corners[triEdges[i][1]];
      final triPath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(ctr.dx, ctr.dy)
        ..close();
      c.drawPath(triPath, Paint()..color = _quadCols[i]);
      c.drawPath(
        triPath,
        Paint()
          ..color = const Color(0xFF546E7A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .045,
      );
    }

    // Direction arrows on entry cells
    void arrow(Offset pos, double angle) {
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(angle);
      final tp = TextPainter(
        text: const TextSpan(
          text: '→',
          style: TextStyle(fontSize: .65, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
      c.restore();
    }
    arrow(const Offset(1.5, 6.5), 0); // Blue entry right
    arrow(const Offset(8.5, 1.5), pi / 2); // Red entry down
    arrow(const Offset(13.5, 8.5), pi); // Green entry left
    arrow(const Offset(6.5, 13.5), -pi / 2); // Yellow entry up

    // Pawns / Map-pin tokens
    for (var i = 0; i < seats.length; i++) {
      final seatId = seats[i];
      final col = _quadCols[seatId];
      for (var t = 0; t < 4; t++) {
        final p = pos[i][t];
        var o = _where(seatId, p, t);
        if (p >= 0 && p < 56) {
          o += Offset((t % 2 - .5) * .24, (t ~/ 2 - .5) * .24 + .12);
        } else if (p < 0) {
          o += const Offset(0, .16);
        }
        _drawPin(c, o, col, i == turn && mov.contains(t));
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
