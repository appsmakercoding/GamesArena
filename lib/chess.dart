import 'package:flutter/material.dart';
import 'common.dart';
import 'net.dart';
import 'gutti.dart';

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

class _ChessState extends State<ChessPage> with NetMix<ChessPage> {
  @override
  Net? get net => widget.net;
  @override
  bool remote(Map a) { _tap(a['i'] as int, true); return true; }

  Pos pos = Pos.start();
  int sel = -1, l1 = -1, l2 = -1;
  List<int> tg = [];
  bool over = false, think = false;
  String msg = 'সাদার চাল';

  void _init() => setState(() { pos = Pos.start(); sel = -1; l1 = l2 = -1; tg = []; over = false; think = false; msg = 'সাদার চাল'; });

  void _tap(int i, [bool rem = false]) {
    if (over || think || (widget.vsPc && !pos.w)) return;
    if (!rem) { if (!canAct(pos.w ? 0 : 1)) return; emit({'i': i}); }
    if (sel >= 0 && tg.contains(i)) { _do(Mv(sel, i)); return; }
    if (pos.b[i] * (pos.w ? 1 : -1) > 0) {
      setState(() { sel = i; tg = pos.legal().where((m) => m.f == i).map((m) => m.t).toList(); });
    }
  }

  void _do(Mv m) {
    setState(() { pos = pos.apply(m); l1 = m.f; l2 = m.t; sel = -1; tg = []; });
    final ms = pos.legal();
    final chk = pos.kingAtt(pos.w);
    if (ms.isEmpty) {
      over = true;
      if (chk) {
        showWin(context, pos.w ? 'কালো' : 'সাদা', pos.w ? const Color(0xFF9E9EC8) : Colors.white, net == null ? _init : () => Navigator.pop(context));
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('দাবা'), backgroundColor: Colors.transparent,
            actions: [if (net == null) IconButton(onPressed: _init, icon: const Icon(Icons.refresh_rounded))]),
        body: SafeArea(
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(12), child: Text(think ? '🤖 কম্পিউটার ভাবছে...' : msg, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            Expanded(child: BoardView(8, 8, _CP(pos.b, sel, l1, l2, pos.kingAtt(pos.w) ? pos.b.indexOf(pos.w ? 6 : -6) : -1, tg), _tap)),
            const Padding(padding: EdgeInsets.all(16), child: Text('ক্যাসলিং, এন-প্যাসান ও প্রমোশন (মন্ত্রী) সহ পূর্ণ নিয়ম', style: TextStyle(color: Colors.white38, fontSize: 12))),
          ]),
        ),
      );
}

class _CP extends CustomPainter {
  final List<int> b, tg;
  final int sel, l1, l2, chk;
  _CP(this.b, this.sel, this.l1, this.l2, this.chk, this.tg);
  static const g = ['', '♟', '♞', '♝', '♜', '♛', '♚'];
  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 8);
    c.clipRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 8, 8), const Radius.circular(.3)));
    for (var i = 0; i < 64; i++) {
      final x = (i % 8).toDouble(), y = (i ~/ 8).toDouble();
      var col = (i % 8 + i ~/ 8) % 2 == 0 ? const Color(0xFFEDE7F6) : const Color(0xFF9575CD);
      if (i == l1 || i == l2) col = Color.alphaBlend(const Color(0x88FFD54F), col);
      if (i == sel) col = const Color(0xFF2EC4B6);
      if (i == chk) col = const Color(0xFFFF4D6D);
      c.drawRect(Rect.fromLTWH(x, y, 1, 1), Paint()..color = col);
      final p = b[i];
      if (p != 0) {
        final w = p > 0;
        void draw(Paint? fg, Color? col) {
          final tp = TextPainter(
              text: TextSpan(text: '${g[p.abs()]}\uFE0E', style: TextStyle(fontSize: .82, height: 1, color: fg == null ? col : null, foreground: fg)),
              textDirection: TextDirection.ltr)..layout();
          tp.paint(c, Offset(x + .5 - tp.width / 2, y + .5 - tp.height / 2));
        }
        draw(Paint()..style = PaintingStyle.stroke..strokeWidth = .07..color = w ? const Color(0xFF1B1B2F) : const Color(0x99FFFFFF), null);
        draw(null, w ? Colors.white : const Color(0xFF1B1B2F));
      }
      if (tg.contains(i)) {
        c.drawCircle(Offset(x + .5, y + .5), p != 0 ? .45 : .15,
            Paint()..color = const Color(0xFF2EC4B6).withOpacity(.9)..style = p != 0 ? PaintingStyle.stroke : PaintingStyle.fill..strokeWidth = .08);
      }
    }
  }
  @override
  bool shouldRepaint(_) => true;
}
