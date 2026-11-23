import 'package:flutter/material.dart';
import 'common.dart';
import 'net.dart';
import 'games.dart';

List<List<int>> _dirs(int x, int y) => [
      [1, 0], [-1, 0], [0, 1], [0, -1],
      if ((x + y) % 2 == 0) ...[[1, 1], [1, -1], [-1, 1], [-1, -1]],
    ];

/// Legal moves of piece i: [to, capturedIndex(-1 if none)]
List<List<int>> movesOf(int w, int h, List<int> bd, int i, {bool steps = true, bool jumps = true}) {
  final x = i % w, y = i ~/ w, me = bd[i], r = <List<int>>[];
  for (final d in _dirs(x, y)) {
    final nx = x + d[0], ny = y + d[1];
    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
    final j = ny * w + nx;
    if (bd[j] == 0) {
      if (steps) r.add([j, -1]);
    } else if (bd[j] != me && jumps) {
      final mx = nx + d[0], my = ny + d[1];
      if (mx < 0 || my < 0 || mx >= w || my >= h) continue;
      if (bd[my * w + mx] == 0) r.add([my * w + mx, j]);
    }
  }
  return r;
}

class GridPainter extends CustomPainter {
  final int w, h, sel;
  final List<int> b;
  final List<List<int>> tg;
  final Map<int, Color> col;
  final Map<int, String>? icon;
  GridPainter(this.w, this.h, this.b, this.sel, this.tg, this.col, [this.icon]);

  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / w);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), const Radius.circular(.5)),
        Paint()..color = const Color(0xFFF7F5FF));
    final ln = Paint()..color = const Color(0xFF7C4DFF).withOpacity(.55)..strokeWidth = .06..strokeCap = StrokeCap.round;
    Offset P(int x, int y) => Offset(x + .5, y + .5);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (x + 1 < w) c.drawLine(P(x, y), P(x + 1, y), ln);
        if (y + 1 < h) c.drawLine(P(x, y), P(x, y + 1), ln);
        if ((x + y) % 2 == 0 && y + 1 < h) {
          if (x + 1 < w) c.drawLine(P(x, y), P(x + 1, y + 1), ln);
          if (x > 0) c.drawLine(P(x, y), P(x - 1, y + 1), ln);
        }
      }
    }
    for (var i = 0; i < w * h; i++) {
      final o = P(i % w, i ~/ w);
      c.drawCircle(o, .09, Paint()..color = const Color(0xFF7C4DFF));
      final v = b[i];
      if (v > 0) {
        c.drawCircle(o + const Offset(0, .06), .38, Paint()..color = Colors.black26);
        c.drawCircle(o, .38, Paint()..color = Colors.white);
        if (icon != null) {
          final tp = TextPainter(text: TextSpan(text: icon![v], style: const TextStyle(fontSize: .5)), textDirection: TextDirection.ltr)..layout();
          tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
        } else {
          c.drawCircle(o, .31, Paint()..color = col[v]!);
          c.drawCircle(o + const Offset(-.09, -.09), .09, Paint()..color = Colors.white54);
        }
      }
      if (i == sel) c.drawCircle(o, .46, Paint()..color = const Color(0xFF7C4DFF)..style = PaintingStyle.stroke..strokeWidth = .09);
    }
    for (final t in tg) {
      c.drawCircle(P(t[0] % w, t[0] ~/ w), .2, Paint()..color = const Color(0xFF2EC4B6).withOpacity(.85));
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

class BoardView extends StatelessWidget {
  final int w, h;
  final CustomPainter p;
  final void Function(int) onCell;
  const BoardView(this.w, this.h, this.p, this.onCell, {super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: AspectRatio(
            aspectRatio: w / h,
            child: LayoutBuilder(builder: (_, bc) {
              final cs = bc.maxWidth / w;
              return GestureDetector(
                onTapUp: (d) => onCell(((d.localPosition.dy / cs).floor().clamp(0, h - 1).toInt()) * w +
                    (d.localPosition.dx / cs).floor().clamp(0, w - 1).toInt()),
                child: CustomPaint(painter: p, size: Size.infinite),
              );
            }),
          ),
        ),
      );
}

const _cfg = {'gutti16': [7, 5, 16], 'gutti12': [5, 5, 12], 'gutti8': [5, 4, 8]};

class GuttiPage extends StatefulWidget {
  final GameInfo g;
  final bool vsPc;
  final Net? net;
  const GuttiPage(this.g, this.vsPc, {super.key, this.net});
  @override
  State<GuttiPage> createState() => _GuttiState();
}

class _GuttiState extends State<GuttiPage> with NetMix<GuttiPage> {
  @override
  Net? get net => widget.net;
  @override
  bool remote(Map a) { _tap(a['i'] as int, true); return true; }

  late int w, h, n;
  late List<int> b;
  int turn = 0, sel = -1, forced = -1;
  bool over = false;
  List<List<int>> tg = [];
  static const ids = [0, 3];

  bool get bot => widget.vsPc && turn == 1;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    final c = _cfg[widget.g.id]!;
    w = c[0]; h = c[1]; n = c[2];
    b = List.filled(w * h, 0);
    for (var i = 0; i < n; i++) { b[i] = 1; b[w * h - 1 - i] = 2; }
    turn = 0; sel = -1; forced = -1; over = false; tg = [];
    setState(() {});
  }

  List<List<int>> _all() {
    final r = <List<int>>[];
    for (var i = 0; i < b.length; i++) {
      if (b[i] != turn + 1 || (forced >= 0 && i != forced)) continue;
      for (final m in movesOf(w, h, b, i, steps: forced < 0)) r.add([i, ...m]);
    }
    return r;
  }

  void _tap(int i, [bool rem = false]) {
    if (over || bot) return;
    if (!rem) { if (!canAct(turn)) return; emit({'i': i}); }
    if (sel >= 0) {
      final m = tg.where((e) => e[0] == i);
      if (m.isNotEmpty) { _move(sel, i, m.first[1]); return; }
    }
    if (b[i] == turn + 1 && (forced < 0 || forced == i)) {
      setState(() { sel = i; tg = movesOf(w, h, b, i, steps: forced < 0); });
    }
  }

  void _move(int f, int t, int cap) {
    setState(() { b[t] = b[f]; b[f] = 0; if (cap >= 0) b[cap] = 0; sel = -1; tg = []; });
    if (cap >= 0 && movesOf(w, h, b, t, steps: false).isNotEmpty) {
      forced = t;
      if (!bot) setState(() { sel = t; tg = movesOf(w, h, b, t, steps: false); });
      _bot();
      return;
    }
    forced = -1;
    setState(() => turn = 1 - turn);
    if (_all().isEmpty) {
      over = true;
      showWin(context, kNames[ids[1 - turn]], kCol[ids[1 - turn]], net == null ? _init : () => Navigator.pop(context));
      return;
    }
    _bot();
  }

  void _bot() {
    if (!bot || over) return;
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || over || !bot) return;
      final a = _all();
      if (a.isEmpty) return;
      final caps = a.where((e) => e[3] >= 0).toList();
      final l = caps.isNotEmpty ? caps : a;
      final m = l[rnd.nextInt(l.length)];
      _move(m[0], m[1], m[2]);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.g.bn), backgroundColor: Colors.transparent,
            actions: [if (net == null) IconButton(onPressed: _init, icon: const Icon(Icons.refresh_rounded))]),
        body: SafeArea(
          child: Column(children: [
            TurnBar(ids, turn, [false, widget.vsPc]),
            Expanded(child: BoardView(w, h, GridPainter(w, h, b, sel, tg, {1: kCol[0], 2: kCol[3]}), _tap)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(forced >= 0 ? 'আবার লাফ দিন!' : 'গুটি বেছে নিন, তারপর সবুজ ঘরে ট্যাপ করুন',
                  style: const TextStyle(color: Colors.white54)),
            ),
          ]),
        ),
      );
}
