import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common.dart';
import 'net.dart';
import 'profile.dart';
import 'ui.dart';

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

/// লুডুর রং (কোণ অনুযায়ী): উপরে-বাঁয়ে নীল, উপরে-ডানে লাল, নিচে-ডানে সবুজ, নিচে-বাঁয়ে হলুদ
const _lc = [Color(0xFF2D9CFF), Color(0xFFFF3B4E), Color(0xFF16C25A), Color(0xFFFFC21A)];
const _ln = ['নীল', 'লাল', 'সবুজ', 'হলুদ'];

class LudoPage extends StatefulWidget {
  final int n;
  final bool vsPc;
  final Net? net;
  const LudoPage(this.n, this.vsPc, {super.key, this.net});
  @override
  State<LudoPage> createState() => _LudoState();
}

class _LudoState extends State<LudoPage> with NetMix<LudoPage>, TickerProviderStateMixin {
  @override
  Net? get net => widget.net;
  bool ready = false;

  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController mv = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  Map<int, List<Offset>> _from = {};

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
    pulse.repeat(reverse: true);
    mv.value = 0;
    _init();
  }

  @override
  void dispose() {
    pulse.dispose();
    mv.dispose();
    super.dispose();
  }

  void _init() {
    seats = widget.n == 2 ? [0, 2] : widget.n == 3 ? [0, 1, 2] : [0, 1, 2, 3];
    bots = List.generate(widget.n, (i) => widget.vsPc && i > 0);
    pos = List.generate(widget.n, (_) => List.filled(4, -1));
    turn = 0; dice = 0; busy = false; over = false; mov = [];
    _from = {};
    setState(() {});
    _auto();
  }

  void _auto() {
    if (!mounted) return;
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

  int _reward() => ((widget.vsPc && turn == 0) || (net != null && net!.seat == turn)) ? 50 : 0;

  String _name(int i) {
    if (bots[i]) return widget.n == 2 ? 'কম্পিউটার' : 'কম্পিউটার ${bnNum(i)}';
    if (net != null) return i == net!.seat ? '${Profile.name} (আপনি)' : 'বন্ধু';
    if (widget.vsPc) return Profile.name;
    return 'প্লেয়ার ${bnNum(i + 1)}';
  }

  void _move(int t) {
    ready = false;
    final pl = seats[turn];
    final p = pos[turn][t];
    final np = p == -1 ? 0 : p + dice;
    var extra = dice == 6 || np == 56;
    // হেঁটে যাওয়ার রুট: প্রতিটি ঘর ধরে ধরে
    final route = <Offset>[_where(pl, p, t)];
    if (p == -1) {
      route.add(_where(pl, 0, t));
    } else {
      for (var q = p + 1; q <= np; q++) { route.add(_where(pl, q, t)); }
    }
    final seg = route.length - 1;
    final from = <int, List<Offset>>{turn * 4 + t: route};
    setState(() {
      pos[turn][t] = np;
      mov = [];
      if (np <= 50 && !_safe.contains(_abs(pl, np))) {
        for (var j = 0; j < widget.n; j++) {
          if (j == turn) continue;
          for (var u = 0; u < 4; u++) {
            final q = pos[j][u];
            if (q >= 0 && q <= 50 && _abs(seats[j], q) == _abs(pl, np)) {
              final old = _where(seats[j], q, u);
              // কাটা গুটি হাঁটা শেষ হওয়া পর্যন্ত জায়গায় থাকে, তারপর ঘরে ফেরে
              from[j * 4 + u] = [for (var z = 0; z < seg; z++) old, _where(seats[j], -1, u)];
              pos[j][u] = -1;
              extra = true;
            }
          }
        }
      }
      _from = from;
    });
    final won = pos[turn].every((e) => e == 56);
    if (won) over = true;
    mv.duration = Duration(milliseconds: math.max(380, 170 * seg));
    mv.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _from = {});
      if (won) {
        final rw = _reward();
        if (rw > 0) { Profile.addCoins(rw); Profile.addXp(20); }
        showWin(context, _name(turn), _lc[pl], net == null ? _init : () => Navigator.pop(context), reward: rw);
        return;
      }
      extra ? _auto() : _next();
    });
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

  Widget _card(int q) {
    final i = seats.indexOf(q);
    if (i < 0) return const SizedBox(height: 92);
    final col = _lc[q];
    final active = i == turn && !over;
    final canRoll = active && !bots[i] && !busy && mov.isEmpty && canAct(i);
    final status = !active
        ? ''
        : bots[i]
            ? 'ভাবছে…'
            : mov.isNotEmpty
                ? 'গুটি বেছে নিন'
                : 'ডাইস ঘোরান';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 92,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(colors: [col.withOpacity(active ? .6 : .22), AC.bg1.withOpacity(.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: active ? Colors.white : Colors.white.withOpacity(.15), width: active ? 2.2 : 1),
        boxShadow: active ? [BoxShadow(color: col.withOpacity(.6), blurRadius: 18)] : const [],
      ),
      child: Row(children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black26, border: Border.all(color: col, width: 2.5)),
          child: ClipOval(child: Face(col, size: 38)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_name(i), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Row(children: [
              for (var t = 0; t < 4; t++)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: pos[i][t] == 56 ? col : Colors.white24),
                ),
            ]),
            if (status.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 3), child: Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: lighten(col, .5)))),
          ]),
        ),
        Opacity(
          opacity: active ? 1 : .3,
          child: DiceView(active ? dice : 0, size: 56, active: canRoll, color: col, rolling: busy && active, onTap: canRoll ? _uRoll : null),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ArenaBg(
          floaters: false,
          child: SafeArea(
            child: Column(children: [
              ArenaBar('লুডু', onBack: () => Navigator.pop(context), trailing: net == null ? CircleBtn(Icons.refresh_rounded, _init) : null),
              Expanded(
                child: LayoutBuilder(builder: (_, bc) {
                  final size = (math.min(bc.maxWidth - 24, bc.maxHeight - 92 * 2 - 70)).clamp(220.0, 620.0).toDouble();
                  final hint = over
                      ? ''
                      : bots[turn]
                          ? 'কম্পিউটার চাল দিচ্ছে...'
                          : mov.isNotEmpty
                              ? 'আলো জ্বলা গুটিতে ট্যাপ করুন'
                              : 'নিজের কার্ডের ডাইসে ট্যাপ করুন';
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [Expanded(child: _card(0)), const SizedBox(width: 8), Expanded(child: _card(1))]),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(size * .06),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 24, offset: const Offset(0, 10)),
                              BoxShadow(color: AC.violet.withOpacity(.45), blurRadius: 30),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(size * .06),
                            child: SizedBox(
                              width: size,
                              height: size,
                              child: GestureDetector(
                                onTapUp: (d) => _tap(d.localPosition, size),
                                child: CustomPaint(painter: _LudoPainter(pos, seats, mov, turn, pulse, mv, _from), size: Size(size, size)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(children: [Expanded(child: _card(3)), const SizedBox(width: 8), Expanded(child: _card(2))]),
                        const SizedBox(height: 10),
                        Text(hint, style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  );
                }),
              ),
            ]),
          ),
        ),
      );
}

class _P {
  final Offset o;
  final int seat;
  final bool canMove, done;
  final double lift;
  _P(this.o, this.seat, this.canMove, this.done, this.lift);
}

class _LudoPainter extends CustomPainter {
  final List<List<int>> pos;
  final List<int> seats, mov;
  final int turn;
  final Animation<double> pulse, mvA;
  final Map<int, List<Offset>> from;
  _LudoPainter(this.pos, this.seats, this.mov, this.turn, this.pulse, this.mvA, this.from)
      : super(repaint: Listenable.merge([pulse, mvA]));

  RRect _r(double x, double y, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  Path _star(Offset o, double ro, double ri) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? ro : ri;
      final x = o.dx + r * math.cos(a), y = o.dy + r * math.sin(a);
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    return p;
  }

  void _arrow(Canvas c, Offset o, Offset d, Color col) {
    final n = Offset(-d.dy, d.dx);
    final p = Path()
      ..moveTo(o.dx + d.dx * .3, o.dy + d.dy * .3)
      ..lineTo(o.dx - d.dx * .18 + n.dx * .25, o.dy - d.dy * .18 + n.dy * .25)
      ..lineTo(o.dx - d.dx * .18 - n.dx * .25, o.dy - d.dy * .18 - n.dy * .25)
      ..close();
    c.drawPath(p, Paint()..color = col);
  }

  Shader _grad(Rect r, Color col) =>
      LinearGradient(colors: [lighten(col, .22), darken(col, .1)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(r);

  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 15);
    c.drawRRect(
        _r(0, 0, 15, 15, .9),
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFE9E3FF)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              .createShader(const Rect.fromLTWH(0, 0, 15, 15)));

    // হোম জোন
    for (var i = 0; i < 4; i++) {
      final ox = [0, 9, 9, 0][i].toDouble(), oy = [0, 0, 9, 9][i].toDouble();
      final col = _lc[i];
      final present = seats.contains(i);
      final rr = _r(ox + .12, oy + .12, 5.76, 5.76, .7);
      c.drawRRect(rr, Paint()..shader = _grad(rr.outerRect, col));
      final inner = _r(ox + .8, oy + .8, 4.4, 4.4, .6);
      c.drawRRect(inner.shift(const Offset(0, .1)), Paint()..color = Colors.black.withOpacity(.2));
      c.drawRRect(inner, Paint()..color = const Color(0xFFFDFCFF));
      for (var t = 0; t < 4; t++) {
        final o = _where(i, -1, t);
        c.drawCircle(o, .64, Paint()..color = col.withOpacity(.16));
        c.drawCircle(
            o,
            .64,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .09
              ..color = col.withOpacity(.75));
      }
      if (!present) c.drawRRect(rr, Paint()..color = Colors.black.withOpacity(.32));
      if (present && seats.isNotEmpty && seats[turn] == i) {
        c.drawRRect(
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .16
              ..color = Colors.white.withOpacity(.45 + .55 * pulse.value));
      }
    }

    // পথের ঘর
    final line = Paint()
      ..color = const Color(0xFFD6CEF0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .05;
    for (var i = 0; i < 52; i++) {
      final o = _path[i];
      final r = _r(o.dx - .5 + .04, o.dy - .5 + .04, .92, .92, .16);
      final sc = _start.indexOf(i);
      c.drawRRect(r, sc >= 0 ? (Paint()..shader = _grad(r.outerRect, _lc[sc])) : (Paint()..color = Colors.white));
      c.drawRRect(r, line);
      if (_safe.contains(i)) {
        c.drawPath(_star(o, .32, .14), Paint()..color = sc >= 0 ? Colors.white : const Color(0xFFB7A6F2));
      }
    }
    for (var i = 0; i < 4; i++) {
      final idx = (_start[i] + 50) % 52;
      _arrow(c, _path[idx], Offset(_hd[i][2].toDouble(), _hd[i][3].toDouble()), _lc[i]);
    }
    for (var i = 0; i < 4; i++) {
      for (final o in _home(i)) {
        final r = _r(o.dx - .46, o.dy - .46, .92, .92, .16);
        c.drawRRect(r, Paint()..shader = _grad(r.outerRect, _lc[i]));
      }
    }

    // মাঝের ত্রিভুজ
    const ctr = Offset(7.5, 7.5);
    const tri = [
      [Offset(6, 6), Offset(6, 9)], [Offset(6, 6), Offset(9, 6)],
      [Offset(9, 6), Offset(9, 9)], [Offset(6, 9), Offset(9, 9)],
    ];
    for (var i = 0; i < 4; i++) {
      final path = Path()
        ..moveTo(tri[i][0].dx, tri[i][0].dy)
        ..lineTo(tri[i][1].dx, tri[i][1].dy)
        ..lineTo(ctr.dx, ctr.dy)
        ..close();
      c.drawPath(path, Paint()..shader = _grad(path.getBounds(), _lc[i]));
      c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .07
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.white.withOpacity(.7));
    }
    c.drawCircle(ctr, .55, Paint()..color = Colors.white);
    c.drawPath(_star(ctr, .4, .17), Paint()..color = const Color(0xFFFFB300));

    // গুটি
    final ps = <_P>[];
    for (var i = 0; i < seats.length; i++) {
      for (var t = 0; t < 4; t++) {
        final p = pos[i][t];
        var target = _where(seats[i], p, t);
        if (p >= 0 && p < 56) target += Offset((t % 2 - .5) * .22, (t ~/ 2 - .5) * .22);
        var o = target;
        var lift = 0.0;
        final a = from[i * 4 + t];
        if (a != null) {
          final segs = a.length - 1;
          final f = (mvA.value * segs).clamp(0.0, segs.toDouble()).toDouble();
          final idx = math.min(f.floor(), segs - 1);
          final local = f - idx;
          final e = segs == 1 ? Curves.easeInOut.transform(local) : local;
          o = Offset.lerp(a[idx], a[idx + 1], e)!;
          lift = a[idx] == a[idx + 1] ? 0.0 : math.sin(math.pi * local) * (segs == 1 ? .7 : .35);
        }
        final can = i == turn && mov.contains(t);
        if (can) lift = pulse.value * .22;
        ps.add(_P(o, seats[i], can, p == 56, lift));
      }
    }
    ps.sort((a, b) => a.o.dy.compareTo(b.o.dy));
    for (final p in ps) {
      _pin(c, p);
    }
  }

  void _pin(Canvas c, _P p) {
    final col = _lc[p.seat];
    final k = p.done ? .62 : 1.0;
    final gp = Offset(p.o.dx, p.o.dy + .3 * k);
    c.drawOval(Rect.fromCenter(center: gp.translate(0, .06), width: 1.0 * k, height: .36 * k), Paint()..color = Colors.black.withOpacity(.3));
    if (p.canMove) {
      c.drawOval(
          Rect.fromCenter(center: gp, width: (1.15 + .35 * pulse.value) * k, height: (.55 + .15 * pulse.value) * k),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .12
            ..color = Colors.white);
    }
    c.drawOval(
        Rect.fromCenter(center: gp, width: .86 * k, height: .3 * k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .09
          ..color = darken(col, .25));
    final o = Offset(p.o.dx, p.o.dy - p.lift * k);
    final hc = o.translate(0, -.2 * k);
    final hr = .34 * k;
    final tip = o.translate(0, .32 * k);
    final tri = Path()
      ..moveTo(hc.dx - hr * .86, hc.dy + hr * .5)
      ..lineTo(hc.dx + hr * .86, hc.dy + hr * .5)
      ..lineTo(tip.dx, tip.dy)
      ..close();
    final body = Path.combine(PathOperation.union, Path()..addOval(Rect.fromCircle(center: hc, radius: hr)), tri);
    c.drawPath(
        body,
        Paint()
          ..shader = RadialGradient(center: const Alignment(-.4, -.5), radius: 1.0, colors: [lighten(col, .55), col, darken(col, .25)], stops: const [0, .5, 1])
              .createShader(body.getBounds()));
    c.drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .07 * k
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white);
    c.drawCircle(hc, hr * .46, Paint()..color = Colors.white);
    c.drawCircle(hc, hr * .26, Paint()..color = col);
    c.drawCircle(hc.translate(-hr * .4, -hr * .5), hr * .13, Paint()..color = Colors.white.withOpacity(.65));
  }

  @override
  bool shouldRepaint(covariant _LudoPainter old) => true;
}
