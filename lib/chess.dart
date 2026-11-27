import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common.dart';
import 'net.dart';
import 'game_ui.dart';
import 'ui.dart';

class Mv {
  final int f, t;
  Mv(this.f, this.t);
}

const _kn = [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]];
const _dg = [[-1, -1], [-1, 1], [1, -1], [1, 1]];
const _or = [[-1, 0], [1, 0], [0, -1], [0, 1]];
const _val = [0, 100, 320, 330, 500, 900, 0];

class Pos {
  List<int> b;
  bool wk, wq, bk, bq, w;
  int ep;
  Pos(this.b, this.wk, this.wq, this.bk, this.bq, this.ep, this.w);
  factory Pos.start() {
    final b = List.filled(64, 0);
    const back = [4, 2, 3, 5, 6, 3, 2, 4];
    for (var c = 0; c < 8; c++) { b[c] = -back[c]; b[8 + c] = -1; b[48 + c] = 1; b[56 + c] = back[c]; }
    return Pos(b, true, true, true, true, -1, true);
  }

  Pos apply(Mv m) {
    final n = Pos([...b], wk, wq, bk, bq, -1, !w);
    final p = b[m.f];
    n.b[m.t] = p; n.b[m.f] = 0;
    if (p.abs() == 1) {
      if (m.t == ep) n.b[m.t + (w ? 8 : -8)] = 0;
      if ((m.t - m.f).abs() == 16) n.ep = (m.f + m.t) ~/ 2;
      if (m.t < 8 || m.t >= 56) n.b[m.t] = p > 0 ? 5 : -5;
    }
    if (p.abs() == 6) {
      if (w) { n.wk = false; n.wq = false; } else { n.bk = false; n.bq = false; }
      if (m.t - m.f == 2) { n.b[m.t - 1] = n.b[m.t + 1]; n.b[m.t + 1] = 0; }
      if (m.t - m.f == -2) { n.b[m.t + 1] = n.b[m.t - 2]; n.b[m.t - 2] = 0; }
    }
    if (m.f == 63 || m.t == 63) n.wk = false;
    if (m.f == 56 || m.t == 56) n.wq = false;
    if (m.f == 7 || m.t == 7) n.bk = false;
    if (m.f == 0 || m.t == 0) n.bq = false;
    return n;
  }

  bool att(int sq, bool byW) {
    final r = sq ~/ 8, c = sq % 8, s = byW ? 1 : -1;
    bool ok(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;
    final pr = r + (byW ? 1 : -1);
    for (final dc in [-1, 1]) { if (ok(pr, c + dc) && b[pr * 8 + c + dc] == s) return true; }
    for (final d in _kn) { if (ok(r + d[0], c + d[1]) && b[(r + d[0]) * 8 + c + d[1]] == 2 * s) return true; }
    for (final d in [..._dg, ..._or]) {
      if (ok(r + d[0], c + d[1]) && b[(r + d[0]) * 8 + c + d[1]] == 6 * s) return true;
      final diag = d[0] != 0 && d[1] != 0;
      var rr = r + d[0], cc = c + d[1];
      while (ok(rr, cc)) {
        final v = b[rr * 8 + cc];
        if (v != 0) { if (v == 5 * s || v == (diag ? 3 : 4) * s) return true; break; }
        rr += d[0]; cc += d[1];
      }
    }
    return false;
  }

  bool kingAtt(bool white) => att(b.indexOf(white ? 6 : -6), !white);

  List<Mv> pseudo() {
    final r = <Mv>[], s = w ? 1 : -1;
    for (var i = 0; i < 64; i++) {
      final p = b[i];
      if (p * s <= 0) continue;
      final t = p.abs(), row = i ~/ 8, col = i % 8;
      if (t == 1) {
        final d = w ? -8 : 8, st = w ? 6 : 1;
        if (b[i + d] == 0) { r.add(Mv(i, i + d)); if (row == st && b[i + 2 * d] == 0) r.add(Mv(i, i + 2 * d)); }
        for (final dc in [-1, 1]) {
          if (col + dc < 0 || col + dc > 7) continue;
          final to = i + d + dc;
          if (b[to] * s < 0 || to == ep) r.add(Mv(i, to));
        }
      } else if (t == 2 || t == 6) {
        for (final d in (t == 2 ? _kn : [..._dg, ..._or])) {
          final rr = row + d[0], cc = col + d[1];
          if (rr < 0 || rr > 7 || cc < 0 || cc > 7) continue;
          if (b[rr * 8 + cc] * s <= 0) r.add(Mv(i, rr * 8 + cc));
        }
        if (t == 6) {
          final base = w ? 60 : 4;
          if ((w ? wk : bk) && b[base + 1] == 0 && b[base + 2] == 0 && b[base + 3] == 4 * s &&
              !att(base, !w) && !att(base + 1, !w) && !att(base + 2, !w)) r.add(Mv(base, base + 2));
          if ((w ? wq : bq) && b[base - 1] == 0 && b[base - 2] == 0 && b[base - 3] == 0 && b[base - 4] == 4 * s &&
              !att(base, !w) && !att(base - 1, !w) && !att(base - 2, !w)) r.add(Mv(base, base - 2));
        }
      } else {
        for (final d in [if (t != 4) ..._dg, if (t != 3) ..._or]) {
          var rr = row + d[0], cc = col + d[1];
          while (rr >= 0 && rr < 8 && cc >= 0 && cc < 8) {
            final v = b[rr * 8 + cc];
            if (v * s <= 0) r.add(Mv(i, rr * 8 + cc));
            if (v != 0) break;
            rr += d[0]; cc += d[1];
          }
        }
      }
    }
    return r;
  }

  List<Mv> legal() => pseudo().where((m) => !apply(m).kingAtt(w)).toList();

  int eval() {
    var s = 0;
    for (var i = 0; i < 64; i++) {
      final p = b[i];
      if (p == 0) continue;
      final t = p.abs(), row = i ~/ 8, col = i % 8;
      var v = _val[t];
      final cen = 7 - ((3.5 - row).abs() + (3.5 - col).abs()).round();
      if (t == 1) v += (p > 0 ? 6 - row : row - 1) * 6 + cen;
      if (t == 2 || t == 3) v += cen * 4;
      s += p > 0 ? v : -v;
    }
    return s;
  }
}

int _search(Pos p, int d, int a, int bt) {
  if (d == 0) return (p.w ? 1 : -1) * p.eval();
  final ms = p.legal();
  if (ms.isEmpty) return p.kingAtt(p.w) ? -100000 - d : 0;
  ms.sort((x, y) => (p.b[y.t] != 0 ? 1 : 0) - (p.b[x.t] != 0 ? 1 : 0));
  for (final m in ms) {
    final v = -_search(p.apply(m), d - 1, -bt, -a);
    if (v >= bt) return bt;
    if (v > a) a = v;
  }
  return a;
}

Mv bestMove(Pos p, int depth) {
  final ms = p.legal()..shuffle(rnd);
  Mv best = ms.first;
  var bv = -999999;
  for (final m in ms) {
    final v = -_search(p.apply(m), depth - 1, -999999, 999999);
    if (v > bv) { bv = v; best = m; }
  }
  return best;
}

class ChessPage extends StatefulWidget {
  final bool vsPc;
  final Net? net;
  const ChessPage(this.vsPc, {super.key, this.net});
  @override
  State<ChessPage> createState() => _ChessState();
}

class _Snap {
  final Pos pos;
  final int l1, l2;
  _Snap(this.pos, this.l1, this.l2);
}

class _ChessState extends State<ChessPage> with NetMix<ChessPage>, SingleTickerProviderStateMixin {
  @override
  Net? get net => widget.net;
  @override
  bool remote(Map a) { _tap(a['i'] as int, true); return true; }

  late final AnimationController mv = AnimationController(vsync: this, duration: const Duration(milliseconds: 260), value: 1);
  Pos pos = Pos.start();
  int sel = -1, l1 = -1, l2 = -1, theme = 0;
  Mv? hint;
  List<int> tg = [];
  List<_Snap> hist = [];
  bool over = false, think = false;
  String msg = 'সাদার চাল';

  @override
  void dispose() {
    mv.dispose();
    super.dispose();
  }

  void _init() => setState(() {
        pos = Pos.start(); sel = -1; l1 = l2 = -1; tg = []; hist = []; hint = null;
        over = false; think = false; msg = 'সাদার চাল'; mv.value = 1;
      });

  void _tap(int i, [bool rem = false]) {
    if (over || think || (widget.vsPc && !pos.w)) return;
    if (!rem) { if (!canAct(pos.w ? 0 : 1)) return; emit({'i': i}); }
    if (sel >= 0 && tg.contains(i)) { _do(Mv(sel, i)); return; }
    if (pos.b[i] * (pos.w ? 1 : -1) > 0) {
      setState(() { sel = i; hint = null; tg = pos.legal().where((m) => m.f == i).map((m) => m.t).toList(); });
    }
  }

  void _do(Mv m) {
    hist.add(_Snap(pos, l1, l2));
    setState(() { pos = pos.apply(m); l1 = m.f; l2 = m.t; sel = -1; tg = []; hint = null; });
    mv.forward(from: 0);
    final ms = pos.legal();
    final chk = pos.kingAtt(pos.w);
    if (ms.isEmpty) {
      over = true;
      if (chk) {
        final rw = giveWinReward(vsPc: widget.vsPc, turn: pos.w ? 1 : 0, net: net);
        showWin(context, pos.w ? 'কালো' : 'সাদা', pos.w ? const Color(0xFF9E9EC8) : Colors.white, net == null ? _init : () => Navigator.pop(context), reward: rw);
      } else {
        showDialog(context: context, builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF1B1140),
          title: const Text('🤝 ড্র (স্টেলমেট)', textAlign: TextAlign.center),
          actions: [FilledButton(onPressed: () { Navigator.pop(c); if (net == null) { _init(); } else { Navigator.pop(context); } }, child: const Text('আবার খেলুন'))],
        ));
      }
      return;
    }
    setState(() => msg = '${pos.w ? 'সাদার' : 'কালোর'} চাল${chk ? ' — কিস্তি!' : ''}');
    if (widget.vsPc && !pos.w) {
      think = true;
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        final bm = bestMove(pos, 3);
        think = false;
        _do(bm);
      });
    }
  }

  void _undo() {
    if (think || over || hist.isEmpty || net != null) return;
    final k = (widget.vsPc && hist.length >= 2 && pos.w) ? 2 : 1;
    final s = hist[hist.length - k];
    hist.removeRange(hist.length - k, hist.length);
    setState(() {
      pos = s.pos; l1 = s.l1; l2 = s.l2; sel = -1; tg = []; hint = null; mv.value = 1;
      msg = '${pos.w ? 'সাদার' : 'কালোর'} চাল';
    });
  }

  void _hint() {
    if (think || over || net != null || (widget.vsPc && !pos.w)) return;
    final m = bestMove(pos, 2);
    setState(() { hint = m; sel = -1; tg = []; });
  }

  Widget _wb(IconData ic, String label, VoidCallback? on) => GestureDetector(
        onTap: on == null ? null : () { tick(); on(); },
        child: Opacity(
          opacity: on == null ? .45 : 1,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFC9772B), Color(0xFF6B3412)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                border: Border.all(color: AC.gold, width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(ic, color: AC.gold, size: 30),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          ]),
        ),
      );

  Widget _panel(bool white) {
    final active = pos.w == white && !over;
    final name = playerName(white ? 0 : 1, n: 2, bots: [false, widget.vsPc], vsPc: widget.vsPc, net: net);
    final col = white ? const Color(0xFFF4EFE3) : const Color(0xFF3A3F55);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF9A5624), Color(0xFF6B3412), Color(0xFF8A4A1E)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border.all(color: active ? AC.gold : const Color(0xFF3E1F08), width: active ? 2.5 : 1.5),
        boxShadow: active ? [BoxShadow(color: AC.gold.withOpacity(.5), blurRadius: 16)] : const [],
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black38, border: Border.all(color: AC.gold, width: 2.5)),
          child: ClipOval(child: Face(col, size: 34)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            Text(white ? 'সাদা পক্ষ' : 'কালো পক্ষ', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD9A8), fontWeight: FontWeight.w700)),
          ]),
        ),
        if (!white && think) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: AC.gold)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F5A5E), Color(0xFF08242F), Color(0xFF05141C)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: SafeArea(
            child: LayoutBuilder(builder: (_, bc) {
              final size = math.min(bc.maxWidth - 16, bc.maxHeight - 56 - 62 * 2 - 52 - 96 - 28).clamp(220.0, 640.0).toDouble();
              final pad = size * .022;
              final cs = (size - pad * 2) / 8;
              final kingSq = pos.kingAtt(pos.w) ? pos.b.indexOf(pos.w ? 6 : -6) : -1;
              return Center(
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ArenaBar('দাবা', onBack: () => Navigator.pop(context)),
                    _panel(false),
                    SizedBox(
                      height: 52,
                      child: Center(
                        child: Text(think ? 'কম্পিউটার ভাবছে...' : msg, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AC.gold, shadows: [Shadow(color: Colors.black54, blurRadius: 6)])),
                      ),
                    ),
                    Container(
                      width: size,
                      height: size,
                      padding: EdgeInsets.all(pad),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(colors: [Color(0xFF9A5624), Color(0xFF5E2F10), Color(0xFF8A4A1E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        border: Border.all(color: const Color(0xFFFFC857), width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.6), blurRadius: 24, offset: const Offset(0, 10))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: GestureDetector(
                          onTapUp: (d) => _tap(((d.localPosition.dy / cs).floor().clamp(0, 7).toInt()) * 8 + (d.localPosition.dx / cs).floor().clamp(0, 7).toInt()),
                          child: CustomPaint(painter: _CP(pos.b, sel, l1, l2, kingSq, tg, hint, theme, mv), size: Size.infinite),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _panel(true),
                    const SizedBox(height: 14),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      if (net == null) _wb(Icons.refresh_rounded, 'রিস্টার্ট', _init),
                      _wb(Icons.style_rounded, 'পিস', () => setState(() => theme = 1 - theme)),
                      if (net == null) _wb(Icons.undo_rounded, 'আনডু', hist.isEmpty || think || over ? null : _undo),
                      if (net == null) _wb(Icons.lightbulb_rounded, 'হিন্ট', think || over || (widget.vsPc && !pos.w) ? null : _hint),
                    ]),
                    const SizedBox(height: 10),
                  ]),
                ),
              );
            }),
          ),
        ),
      );
}

const _wI = [Color(0xFFFFFDF7), Color(0xFFDCD6C8), Color(0xFF9F9887)];
const _bI = [Color(0xFF666B7D), Color(0xFF2A2D3B), Color(0xFF0C0D15)];
const _wN = [Color(0xFFC7FFF6), Color(0xFF22D3EE), Color(0xFF0E7490)];
const _bN = [Color(0xFFFFC2E6), Color(0xFFFF4081), Color(0xFF9C1250)];

class _CP extends CustomPainter {
  final List<int> b, tg;
  final int sel, l1, l2, chk, theme;
  final Mv? hint;
  final Animation<double> mvA;
  _CP(this.b, this.sel, this.l1, this.l2, this.chk, this.tg, this.hint, this.theme, this.mvA) : super(repaint: mvA);

  void _label(Canvas c, String t, Offset o, Color col) {
    final tp = TextPainter(text: TextSpan(text: t, style: TextStyle(fontSize: .2, fontWeight: FontWeight.w800, color: col)), textDirection: TextDirection.ltr)..layout();
    tp.paint(c, o);
  }

  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 8);
    for (var i = 0; i < 64; i++) {
      final x = (i % 8).toDouble(), y = (i ~/ 8).toDouble();
      final light = (i % 8 + i ~/ 8) % 2 == 0;
      final r = Rect.fromLTWH(x, y, 1, 1);
      c.drawRect(
          r,
          Paint()
            ..shader = LinearGradient(
                    colors: light ? const [Color(0xFFF8EBD0), Color(0xFFE9D3AB)] : const [Color(0xFF30303A), Color(0xFF121218)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)
                .createShader(r));
      if (i == l1 || i == l2) c.drawRect(r, Paint()..color = const Color(0x66FFC107));
      if (i == chk) c.drawRect(r, Paint()..shader = const RadialGradient(colors: [Color(0xFFFF1744), Color(0x00FF1744)]).createShader(r));
      if (i == sel) {
        c.drawRect(r, Paint()..color = const Color(0xBBE53935));
        final cp = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = .05..strokeCap = StrokeCap.round;
        const k = .2, e = .06;
        for (final cx in [0.0, 1.0]) {
          for (final cy in [0.0, 1.0]) {
            final px = x + cx, py = y + cy;
            final sx = cx == 0 ? 1.0 : -1.0, sy = cy == 0 ? 1.0 : -1.0;
            c.drawPath(Path()..moveTo(px + sx * e, py + sy * (e + k))..lineTo(px + sx * e, py + sy * e)..lineTo(px + sx * (e + k), py + sy * e), cp);
          }
        }
      }
      final lc = light ? const Color(0xFF6B5638) : const Color(0xFFCDBFA5);
      if (i % 8 == 0) _label(c, '${8 - i ~/ 8}', Offset(x + .05, y + .03), lc);
      if (i ~/ 8 == 7) _label(c, String.fromCharCode(97 + i % 8), Offset(x + .8, y + .76), lc);
    }

    // হিন্ট
    if (hint != null) {
      final a = Offset(hint!.f % 8 + .5, hint!.f ~/ 8 + .5), z = Offset(hint!.t % 8 + .5, hint!.t ~/ 8 + .5);
      final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = .07..color = const Color(0xFFFFD54F);
      c.drawRect(Rect.fromCenter(center: a, width: .92, height: .92), ring);
      c.drawRect(Rect.fromCenter(center: z, width: .92, height: .92), ring);
      c.drawLine(a, z, Paint()..color = const Color(0xAAFFD54F)..strokeWidth = .12..strokeCap = StrokeCap.round);
    }

    // গুটি (নিচের সারি উপরে আঁকা হবে)
    final u = mvA.value;
    final list = <List<Object>>[];
    for (var i = 0; i < 64; i++) {
      if (b[i] == 0) continue;
      var o = Offset(i % 8 + .5, i ~/ 8 + .5);
      var lift = 0.0;
      if (i == l2 && l1 >= 0 && u < 1) {
        final f = Offset(l1 % 8 + .5, l1 ~/ 8 + .5);
        o = Offset.lerp(f, o, Curves.easeInOut.transform(u))!;
        lift = math.sin(math.pi * u) * .18;
      }
      list.add([i, o, lift]);
    }
    list.sort((p, q) => (p[1] as Offset).dy.compareTo((q[1] as Offset).dy));
    for (final e in list) {
      _piece(c, b[e[0] as int], e[1] as Offset, e[2] as double);
    }

    for (final i in tg) {
      final o = Offset(i % 8 + .5, i ~/ 8 + .5);
      if (b[i] != 0) {
        c.drawCircle(o, .46, Paint()..color = const Color(0xFF2EE66B)..style = PaintingStyle.stroke..strokeWidth = .08);
      } else {
        c.drawCircle(o, .15, Paint()..color = const Color(0xFF2EE66B).withOpacity(.9));
      }
    }
  }

  void _piece(Canvas c, int p, Offset center, double lift) {
    final t = p.abs(), white = p > 0;
    final cols = theme == 0 ? (white ? _wI : _bI) : (white ? _wN : _bN);
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(.94);
    c.translate(-.5, -.5);
    c.drawOval(Rect.fromLTWH(.17, .86, .66, .1), Paint()..color = Colors.black.withOpacity(.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, .03));
    c.translate(0, -lift);
    final fill = Paint()
      ..shader = LinearGradient(colors: cols, begin: Alignment.centerLeft, end: Alignment.centerRight).createShader(const Rect.fromLTWH(.15, 0, .7, 1));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .022
      ..strokeJoin = StrokeJoin.round
      ..color = white ? const Color(0xFF5E5646) : Colors.black.withOpacity(.7);
    void shape(Path pa) {
      c.drawPath(pa, fill);
      c.drawPath(pa, line);
    }

    void base() {
      shape(Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(.2, .78, .6, .08), const Radius.circular(.04))));
      shape(Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(.15, .85, .7, .08), const Radius.circular(.04))));
    }

    final eye = Paint()..color = white ? const Color(0xFF2A2218) : Colors.white70;
    switch (t) {
      case 1:
        shape(Path()..moveTo(.40, .46)..quadraticBezierTo(.43, .64, .26, .79)..lineTo(.74, .79)..quadraticBezierTo(.57, .64, .60, .46)..close());
        shape(Path()..addOval(Rect.fromCenter(center: const Offset(.5, .47), width: .28, height: .07)));
        shape(Path()..addOval(Rect.fromCircle(center: const Offset(.5, .30), radius: .14)));
        break;
      case 2:
        shape(Path()
          ..moveTo(.27, .80)
          ..cubicTo(.27, .64, .36, .58, .38, .50)
          ..cubicTo(.32, .52, .26, .54, .20, .50)
          ..cubicTo(.14, .47, .16, .40, .22, .36)
          ..cubicTo(.26, .33, .30, .30, .32, .24)
          ..lineTo(.36, .13)
          ..lineTo(.43, .21)
          ..cubicTo(.56, .19, .70, .30, .73, .50)
          ..cubicTo(.76, .62, .74, .72, .74, .80)
          ..close());
        c.drawCircle(const Offset(.31, .35), .022, eye);
        c.drawCircle(const Offset(.19, .44), .014, eye);
        break;
      case 3:
        shape(Path()..moveTo(.42, .56)..lineTo(.58, .56)..quadraticBezierTo(.60, .70, .72, .79)..lineTo(.28, .79)..quadraticBezierTo(.40, .70, .42, .56)..close());
        shape(Path()..moveTo(.5, .17)..cubicTo(.72, .30, .68, .50, .60, .57)..lineTo(.40, .57)..cubicTo(.32, .50, .28, .30, .5, .17)..close());
        shape(Path()..addOval(Rect.fromCircle(center: const Offset(.5, .14), radius: .05)));
        c.drawLine(const Offset(.52, .28), const Offset(.60, .42), Paint()..color = white ? const Color(0xFF5E5646) : Colors.white54..strokeWidth = .03..strokeCap = StrokeCap.round);
        break;
      case 4:
        shape(Path()..moveTo(.32, .36)..lineTo(.68, .36)..lineTo(.73, .79)..lineTo(.27, .79)..close());
        shape(Path()
          ..moveTo(.26, .38)
          ..lineTo(.26, .18)
          ..lineTo(.34, .18)
          ..lineTo(.34, .25)
          ..lineTo(.43, .25)
          ..lineTo(.43, .18)
          ..lineTo(.57, .18)
          ..lineTo(.57, .25)
          ..lineTo(.66, .25)
          ..lineTo(.66, .18)
          ..lineTo(.74, .18)
          ..lineTo(.74, .38)
          ..close());
        break;
      case 5:
        shape(Path()..moveTo(.31, .38)..lineTo(.69, .38)..quadraticBezierTo(.62, .62, .74, .79)..lineTo(.26, .79)..quadraticBezierTo(.38, .62, .31, .38)..close());
        shape(Path()..moveTo(.28, .40)..lineTo(.22, .20)..lineTo(.36, .31)..lineTo(.42, .14)..lineTo(.5, .30)..lineTo(.58, .14)..lineTo(.64, .31)..lineTo(.78, .20)..lineTo(.72, .40)..close());
        shape(Path()..addOval(Rect.fromCenter(center: const Offset(.5, .42), width: .46, height: .07)));
        for (final o in const [Offset(.22, .18), Offset(.42, .12), Offset(.58, .12), Offset(.78, .18)]) {
          shape(Path()..addOval(Rect.fromCircle(center: o, radius: .035)));
        }
        break;
      default:
        shape(Path()..moveTo(.32, .42)..lineTo(.68, .42)..quadraticBezierTo(.62, .62, .74, .79)..lineTo(.26, .79)..quadraticBezierTo(.38, .62, .32, .42)..close());
        shape(Path()..moveTo(.28, .44)..quadraticBezierTo(.28, .26, .5, .27)..quadraticBezierTo(.72, .26, .72, .44)..close());
        shape(Path()..addOval(Rect.fromCenter(center: const Offset(.5, .45), width: .46, height: .07)));
        shape(Path()..addRect(const Rect.fromLTWH(.46, .05, .08, .24)));
        shape(Path()..addRect(const Rect.fromLTWH(.39, .11, .22, .07)));
    }
    base();
    if (t != 2) {
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(.36, .34, .04, .36), const Radius.circular(.02)), Paint()..color = Colors.white.withOpacity(white ? .5 : .28));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _CP old) => true;
}
